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
package org.gallery3.organize {
	// @todo implement mirrored layout when flex supports it (probably 4.1)
	import com.adobe.serialization.json.JSON;
	import com.adobe.utils.StringUtil;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.external.ExternalInterface;
	import flash.net.FileFilter;
	import flash.net.FileReferenceList;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	import flash.system.Security;
	
	import mx.binding.utils.BindingUtils;
	import mx.collections.ArrayCollection;
	import mx.containers.HDividedBox;
	import mx.events.FlexEvent;
	import mx.managers.PopUpManager;
	import mx.rpc.Fault;
	
	import org.gallery3.api.GalleryAlbum;
	import org.gallery3.api.GalleryItem;
	import org.gallery3.api.GalleryResource;
	import org.gallery3.api.GalleryRestRequest;
	import org.gallery3.api.GalleryRestResponder;
	import org.gallery3.api.GalleryRestToken;
	import org.gallery3.organize.components.AddAlbumDialog;
	import org.gallery3.organize.components.AlbumTree;
	import org.gallery3.organize.components.ErrorDialog;
	import org.gallery3.organize.components.ProcessItemQueue;
	import org.gallery3.organize.components.ThumbGrid;
	
	import spark.components.Button;
	import spark.components.ComboBox;
	import spark.components.Label;
	import spark.events.IndexChangeEvent;
	
	public class OrganizeDialog extends HDividedBox {
		private var _fileFilters: Array;
		private var _typeMap: Object;
		
		// References to Controls must be declared public
		public var albumTree: AlbumTree;
		public var imageGrid: ThumbGrid;
		public var sortColumn: ComboBox;
		public var sortDirection: ComboBox;
		public var rotateCCW: Button;
		public var rotateCW: Button;
		public var addAlbum: Button;
		public var addImages: Button;
		public var deleteImages: Button;
		public var dialogClose: Button;
		public var organizeStatus: Label;

		private var _selectedCount:int = 0;

		public var openPath: ArrayCollection;

		[Bindable]
		public var translations:OrganizeText;
		[Bindable]
		public var styles:OrganizeStyle;
		
		[Bindable]
		protected var sortColumnData: ArrayCollection = new ArrayCollection();
		
		[Bindable]
		protected var sortDirectionData: ArrayCollection = new ArrayCollection();
		
		public function OrganizeDialog() {
			super();
			addEventListener(FlexEvent.CREATION_COMPLETE, contentCreationCompleteHandler);
			addEventListener(FlexEvent.PREINITIALIZE, preinitializeHandler);
		}

		protected function contentCreationCompleteHandler(event: FlexEvent): void {
			translations = OrganizeText.instance;
			styles = OrganizeStyle.instance;
			
			BindingUtils.bindProperty(organizeStatus, "text", translations, "statusText");
			BindingUtils.bindProperty(addAlbum, "label", translations, "addAlbum");
			BindingUtils.bindProperty(addImages, "label", translations, "addImages");
			BindingUtils.bindProperty(deleteImages, "label", translations, "deleteSelected");
			BindingUtils.bindProperty(dialogClose, "label", translations, "close");
			
			var params: URLVariables = new URLVariables();
			params.ancestors_for = GalleryRestRequest.baseURL + "item/" + OrganizeParameters.instance.albumId;
			var token: GalleryRestToken = GalleryResource.loadResource("items", params);
			token.addResponder(new GalleryRestResponder(
				function (resource: Object): void {
					openPath = resource as ArrayCollection;
					var rootItem: GalleryAlbum = openPath.removeItemAt(0);
					rootItem.albums.addEventListener("AlbumLoaded", albumsUpdated);
					
					albumTree.dataProvider = [rootItem];
					albumTree.validateNow();
					albumTree.expandItem(rootItem, true, true, true);
				},
				function (fault: Object): void {
					ErrorDialog.display(fault as Fault);
				}));
		}

		protected function albumsUpdated(event: Event): void {
			if (openPath.length > 0) {
				for each (var item: GalleryAlbum in event.target) {
					if (item.url == openPath.getItemAt(0).url) {
						callLater(function(): void {
							openPath.removeItemAt(0);
							if (openPath.length > 0) {
								item.albums.addEventListener("AlbumLoaded", albumsUpdated);
								albumTree.expandItem(item, true, true, true);
								albumTree.invalidateProperties();
							} else {
								albumTree.selectedItem = item;
								onTreeSelectedChange(null);
							}
						});
						break;
					}
				}
			} else {	//	Special case where the selected album is the root
				callLater(function(): void {
					albumTree.selectedItem = albumTree.dataProvider.getItemAt(0);
					onTreeSelectedChange(null);
				});
			}
		}

		protected function preinitializeHandler(event:FlexEvent):void {
			var p: Object = OrganizeParameters.instance;
			var domain: String = OrganizeParameters.instance.domain;
			Security.allowDomain(domain);

			var fileFilter: Object = JSON.decode(OrganizeParameters.instance.fileFilter);

			_typeMap = {};
			_fileFilters = new Array();
			for (var itemType:String in fileFilter) {
				var filter: Object = fileFilter[itemType];
				var filterTypes: String = "";
				for each (var type: String in filter.types) {
					filterTypes += ((filterTypes.length > 0) ? "; " : "") + type;
					_typeMap[type.substr(1)] = itemType;
				}
				_fileFilters.push(new FileFilter(filter.label + " (" + filterTypes + ")", filterTypes));
			}

			var sortField: Object = JSON.decode(OrganizeParameters.instance.sortFields);
			for (var entry:String in sortField) {
				sortColumnData.addItem({label: sortField[entry], data: entry});
			}

			var sortOrder: Object = JSON.decode(OrganizeParameters.instance.sortOrder);
			for (entry in sortOrder) {
				sortDirectionData.addItem({label: sortOrder[entry], data: entry});
			}
			
			GalleryRestRequest.baseURL = OrganizeParameters.instance.baseUrl;
			GalleryRestRequest.accessKey = OrganizeParameters.instance.accessKey;
		}
		
		public function setSortColumn(column: String): void {
			for (var i:int = 0; i < sortColumn.dataProvider.length; i++) {
				if (sortColumn.dataProvider[i].data == column) {
					sortColumn.selectedIndex = i;
					break;
				}
			}
		}
		public function setSortOrder(order: String): void {
			for (var i:int = 0; i < sortDirection.dataProvider.length; i++) {
				if (sortDirection.dataProvider[i].data == order) {
					sortDirection.selectedIndex = i;
					break;
				}
			}
		} 

		protected function onAddAlbum(event:FlexEvent):void {
			// @todo get the form fields as part of the initial download
			var request: URLRequest = new URLRequest(OrganizeParameters.instance.controller + "add_album_fields");
			var loader: URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, function(event: Event): void {
				var fields: Object = JSON.decode(event.currentTarget.data);
				_showAddAlbumDialog(fields);
			});
			loader.addEventListener(IOErrorEvent.IO_ERROR, function(event: IOErrorEvent): void {
				var pattern: RegExp = /^Error #(\d+):\s(.*\.)\s(.*)$/;
				var parts: Array = pattern.exec(event.text);
				ErrorDialog(new Fault(parts[1], parts[2], parts[3]));
			});
			loader.load(request);
		}	

		protected function onRotateCCW(event:FlexEvent):void {
			// @todo implement or remove
		}

		protected function onRotateCW(event:FlexEvent):void {
			// @todo implement or remove
		}

		private function _showAddAlbumDialog(fields: Object): void {
			var dialog: AddAlbumDialog = PopUpManager.createPopUp(this, AddAlbumDialog, true) as AddAlbumDialog;
			dialog.parentAlbum = albumTree.selectedItem as GalleryAlbum;
			dialog.title = OrganizeText.instance.addAlbum;
			dialog.submitForm.label = OrganizeText.instance.addAlbum;
			dialog.cancelForm.label = OrganizeText.instance.cancel;
			dialog.labelTitle.text = fields.title;
			dialog.labelDescription.text = fields.description;
			dialog.labelName.text = fields.name;
			dialog.labelSlug.text = fields.slug;
			PopUpManager.centerPopUp(dialog);
		}
		
		protected function onAddContent(event:FlexEvent):void {
			var fileRefList: FileReferenceList = new FileReferenceList();
			fileRefList.addEventListener(Event.SELECT, function(event:Event): void {
				imageGrid.onFilesSelected(event, _typeMap);
			});
			fileRefList.browse(_fileFilters);
		}	
		
		protected function onTreeSelectedChange(event:Event): void {
			if (albumTree.selectedIndex >= 0) {
				var album: GalleryAlbum = albumTree.selectedItem as GalleryAlbum;
				album.loadChildren();
				imageGrid.dataProvider = album; 
				sortColumn.enabled = album.canEdit;
				sortDirection.enabled = album.canEdit;
				addAlbum.enabled = album.canEdit;
				addImages.enabled = album.canEdit;
				
				setSortColumn(album.sortColumn); 
				setSortOrder(album.sortOrder);
				var chars: Object = {
					"&": "&amp;", "\"": "&quot;", "<": "&lt;", ">": "&gt;"
				};
				var title:String = album.title;
				for (var char: String in chars) {
					StringUtil.replace(title, char, chars[char]);
				} 
				ExternalInterface.call("setTitle", title);
			}
		}
		
		protected function onThumbChangeHandler(event:IndexChangeEvent): void {
			selectionChange();
		}
		
		protected function onThumbValueCommitHandler(event:FlexEvent): void {
			selectionChange();
		}
		
		private function selectionChange(): void {
			var newCount: int = imageGrid.selectedItems.length;
			if (newCount != _selectedCount) {
				var album: GalleryAlbum = albumTree.selectedItem as GalleryAlbum;
				_selectedCount = newCount;
				rotateCW.enabled = rotateCCW.enabled = deleteImages.enabled = _selectedCount > 0 && album.canEdit;
			}
		}

		public function onDialogClose(event:FlexEvent): void {
			ExternalInterface.call("closeOrganizeDialog");
		}
		
		protected function onSortColumnChange(event:IndexChangeEvent): void {
			var item: GalleryItem = albumTree.selectedItem as GalleryItem;
			item.sortColumn = sortColumn.selectedItem.data;
			var queue: ProcessItemQueue = new ProcessItemQueue(ProcessItemQueue.SAVE_OPERATION);
			queue.addItem({"action": "save", "item": item});
			queue.processQueue(
				function(): void {
					item.refreshResource().addResponder(new GalleryRestResponder(
						function(resource: Object): void {
							imageGrid.invalidateProperties();
						},
						function (fault: Fault): void {
							ErrorDialog.display(fault as Fault);
						}));
				});
		}
		
		protected function onSortDirectionChange(event:IndexChangeEvent): void {
			var item: GalleryItem = albumTree.selectedItem as GalleryItem;
			item.sortOrder = sortDirection.selectedItem.data;
			var queue: ProcessItemQueue = new ProcessItemQueue(ProcessItemQueue.SAVE_OPERATION);
			queue.addItem({"action": "save", "item": item});
			queue.processQueue(
				function(): void {
					item.refreshResource().addResponder(new GalleryRestResponder(
						function(resource: Object): void {
							imageGrid.invalidateProperties();
						},
						function (fault: Fault): void {
							ErrorDialog.display(fault as Fault);
						}));
				});
		}
		
		protected function onDeleteSelected(event:FlexEvent):void {
			imageGrid.deleteSelected();
		}
	}
}