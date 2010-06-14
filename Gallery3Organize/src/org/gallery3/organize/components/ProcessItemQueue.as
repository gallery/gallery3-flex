/**
 * Gallery - a web based photo album viewer and editor
 * Copyright (C) 2000-2010 Bharat Mediratta
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or (at
 * your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street - Fifth Floor, Boston, MA  02110-1301, USA.
 */
package org.gallery3.organize.components {
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.ProgressEvent;
	
	import mx.collections.ArrayCollection;
	import mx.core.FlexGlobals;
	import mx.managers.PopUpManager;
	import mx.rpc.Fault;
	import mx.utils.StringUtil;
	
	import org.gallery3.api.GalleryRestResponder;
	import org.gallery3.api.GalleryRestToken;
	import org.gallery3.organize.OrganizeText;
	import org.gallery3.organize.components.ErrorDialog;
	import org.gallery3.organize.components.ProgressDialog;
	
	public class ProcessItemQueue extends ArrayCollection {
		public static const MOVE_OPERATION: String = "move";
		public static const DELETE_OPERATION: String = "delete";
		public static const UPLOAD_OPERATION: String = "upload";
		public static const SAVE_OPERATION: String = "save";
		
		private var _completionCallback: Function = null;
		private var _progressCount: int;
		private var _progressTotal: int;
		private var _progressWindow: ProgressDialog;
		private var _operation: String;
		
		public function ProcessItemQueue(operation: String) {
			super(null);
			_operation = operation;
		}
		
		public function processQueue(onComplete: Function=null): void {
			var textStrings: OrganizeText = OrganizeText.instance;
			_progressCount = 0;
			_progressTotal = length;
			
			// @todo start a batch or do we want to start the batch when the dialog is displayed
			var mainWindow: DisplayObject = FlexGlobals.topLevelApplication.organizeDialog as DisplayObject;
			_progressWindow = PopUpManager.createPopUp(mainWindow, ProgressDialog, true) as ProgressDialog;
			_progressWindow.title = textStrings[_operation + "Title"];
			if (_operation == UPLOAD_OPERATION) {
				_progressWindow.currentState = "hasSubtask";
				_progressWindow.subTaskProgressBar.indeterminate = true;
			} else {
				_progressWindow.currentState = "basic";
			}
			
			_progressWindow.overallProgressBar.label = textStrings.progressLabel;
			_progressWindow.overallProgressBar.setProgress(0, _progressTotal);
			PopUpManager.centerPopUp(_progressWindow);

			_completionCallback = onComplete;
			_processItem();
		}

		private function _processItem(): void {
			if (length > 0) {
				var queueItem: Object = this.removeItemAt(0);
				var token: GalleryRestToken;
				switch (queueItem.action) {
					case "save":
						token = queueItem.item.save();
						token.addResponder(new GalleryRestResponder(_onItemProcessingComplete, _onFault));
						break;
					case "delete":
						token = queueItem.item.deleteResource();
						token.addResponder(new GalleryRestResponder(_onItemProcessingComplete, _onFault));
						break;
					case "loadFile":
						queueItem.item.loadFile()
							.addResponder(new GalleryRestResponder(function (resource: Object) : void {						
								queueItem.item.save().addResponder(new GalleryRestResponder(_onItemProcessingComplete, _onFault));
							}, _onFault));
						break;
					default:
						// Just log any invalid items and then process the next one.
						trace("Action: '" + queueItem.action + "' is not implemented");
						_onItemProcessingComplete(null);
				}
			} else {
				if (_completionCallback != null) {
					_completionCallback();
				}
				PopUpManager.removePopUp(_progressWindow);
				this.removeAll();
				// @todo stop the batch
			}
		}
		
		private function _onItemProcessingComplete(resource: Object): void {
			_progressWindow.overallProgressBar.setProgress(++_progressCount, _progressTotal);
			_processItem();
		}
		
		private function _onFault(fault: Object): void {
			PopUpManager.removePopUp(_progressWindow);
			this.removeAll();
			ErrorDialog.display(fault as Fault);
		}
	}
}