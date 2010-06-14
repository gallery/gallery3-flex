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
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import mx.controls.Tree;
	import mx.controls.listClasses.BaseListData;
	import mx.controls.listClasses.IListItemRenderer;
	import mx.events.DragEvent;
	import mx.events.ListEvent;
	import mx.managers.DragManager;
	import mx.rpc.Fault;
	
	import org.gallery3.api.GalleryAlbum;
	import org.gallery3.api.GalleryItem;
	import org.gallery3.api.GalleryRestResponder;
	import org.gallery3.organize.OrganizeDataDescriptor;

	public class AlbumTree extends Tree {
		private var _lastHighlightItemRendererAtIndices: IListItemRenderer;
		private var _lastHighlightItemIndices: Point;
		
		private var _saveQueue: Vector.<Object> = new Vector.<Object>();

		public function AlbumTree() {
			super();
			dataDescriptor = new OrganizeDataDescriptor();
			dropEnabled = true;
			focusEnabled = false;
			dragMoveEnabled = true;
		}

		override protected function dragDropHandler(event:DragEvent):void {
			var targetAlbum: GalleryAlbum = _lastHighlightItemRendererAtIndices.data as GalleryAlbum;
			var data: Vector.<Object> = event.dragSource.dataForFormat("items") as Vector.<Object>;
			var queue: ProcessItemQueue = new ProcessItemQueue(ProcessItemQueue.MOVE_OPERATION);
			while (data.length > 0) {
				var item: GalleryItem = data.shift();
				item.parent = targetAlbum.url;
				_saveQueue.push(item);
				queue.addItem({"action": "save", "item": item});
			}
			queue.processQueue(
				function(): void {
					GalleryAlbum(selectedItem).refreshResource().addResponder(new GalleryRestResponder(
						function(resource: Object): void {},
						function (fault: Fault): void {
							ErrorDialog.display(fault as Fault);
						}));
					var targetAlbum: GalleryAlbum = _lastHighlightItemRendererAtIndices.data as GalleryAlbum;
					targetAlbum.refreshResource().addResponder(new GalleryRestResponder(
						function(resource: Object): void {},
						function (fault: Fault): void {
							ErrorDialog.display(fault as Fault);
						}));
				});
		}

		override protected function dragEnterHandler(event:DragEvent):void {
        	if (event.isDefaultPrevented()) {
            	return;
         	}
			_acceptItems(event);
		}
		
		override protected function mouseOutHandler(event:MouseEvent) : void {
			if (!DragManager.isDragging) {
				super.mouseOutHandler(event);
			} else {
				var item:IListItemRenderer = mouseEventToItemRenderer(event);
				if (item != _lastHighlightItemRendererAtIndices && _lastHighlightItemRendererAtIndices) {
					_updateHightlight(_lastHighlightItemRendererAtIndices, _lastHighlightItemIndices, false);
				}
			}
		}

		override protected function mouseOverHandler(event:MouseEvent) : void {
			if (DragManager.isDragging) {
				var item:IListItemRenderer = mouseEventToItemRenderer(event);	
				if (item) {
					// we're rolling onto different subpieces of ourself or our highlight indicator
					if (event.relatedObject) {
						var lastUID:String;
						if (_lastHighlightItemRendererAtIndices && highlightUID) {
							var rowData:BaseListData = rowMap[item.name];
							lastUID = rowData.uid;
						}
						if (itemRendererContains(item, event.relatedObject) ||
							uid == lastUID ||
							event.relatedObject == highlightIndicator) {
							return;
						}
					}       
					
					if (getStyle("useRollOver") && (item.data != null)) {
						drawItem(UIDToItemRenderer(uid), isItemSelected(item.data), true, uid == caretUID);
						var pt:Point = itemRendererToIndices(item);
						if (pt) {		// during tweens, we may get null
							_updateHightlight(item, pt, true);
						}
					}
				}
			} else {
				super.mouseOverHandler(event);
			}
		}
		
		override protected function dragOverHandler(event:DragEvent): void {
        	if (event.isDefaultPrevented()) {
            	return;
         	}
			_acceptItems(event);
		}

		override protected function dragExitHandler(event:DragEvent): void {
			if (_lastHighlightItemRendererAtIndices) {
				_updateHightlight(_lastHighlightItemRendererAtIndices, _lastHighlightItemIndices, false);
			}
		}

		private function _updateHightlight(item:IListItemRenderer, pt:Point, showHighlight:Boolean): void {
			var uid:String = itemToUID(item.data);
			drawItem(UIDToItemRenderer(uid), isItemSelected(item.data), showHighlight, uid == caretUID);
			var evt:ListEvent = new ListEvent(showHighlight? ListEvent.ITEM_ROLL_OVER : ListEvent.ITEM_ROLL_OUT);
			evt.columnIndex = pt.x;
			evt.rowIndex = pt.y;
			evt.itemRenderer = item;
			dispatchEvent(evt);
			if (showHighlight) {
				_lastHighlightItemIndices = pt;
				_lastHighlightItemRendererAtIndices = item;
			} else {
				_lastHighlightItemIndices = null;
				_lastHighlightItemRendererAtIndices = null;
			}
		}
		
		private function _acceptItems(event:DragEvent): void {
			if (event.dragSource.hasFormat("items")) {
				DragManager.acceptDragDrop(this);
				DragManager.showFeedback(DragManager.MOVE);
			}
		}		
	}
}