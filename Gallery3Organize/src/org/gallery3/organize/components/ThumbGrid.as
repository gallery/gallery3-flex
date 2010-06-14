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
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.FileReference;
	import flash.net.FileReferenceList;
	
	import mx.core.DragSource;
	import mx.core.IFlexDisplayObject;
	import mx.events.DragEvent;
	import mx.managers.DragManager;
	import mx.rpc.Fault;
	
	import org.gallery3.api.GalleryAlbum;
	import org.gallery3.api.GalleryItem;
	import org.gallery3.api.GalleryResource;
	import org.gallery3.api.GalleryRestResponder;
	
	import spark.components.Group;
	import spark.components.IItemRenderer;
	import spark.components.List;
	import spark.core.IViewport;
	import spark.layouts.supportClasses.DropLocation;
	
	[States("normal")]
	public class ThumbGrid extends List {
		private var _lasso:SelectionLasso;
		private var _originalSelection:Vector.<int>;
		private var _dragStart:Point = null;
		private var _tolerance:Number = 5;
		private var _isCtrlKey:Boolean = false;
		private var _items:Vector.<Object>;

		private var _saveQueue: Vector.<Object> = new Vector.<Object>();

		public function ThumbGrid() {
			super();
			useVirtualLayout = false;
			dragMoveEnabled = true;
			this.layout = new PaddedTileLayout();
			with (PaddedTileLayout(this.layout)) {
				verticalAlign = "middle";
				horizontalAlign = "justify";
				verticalGap = 15;
				horizontalGap = 15;
				columnWidth = 100;
				rowHeight = 110;
			}

			addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
			addEventListener(DragEvent.DRAG_START, dragStartHandler);
		}

		public function deleteSelected(): void {
			if (selectedIndices.length > 0) {
				var indices:Vector.<int> = selectedIndices;
				var queue: ProcessItemQueue = new ProcessItemQueue(ProcessItemQueue.DELETE_OPERATION);
				var album: GalleryAlbum = dataProvider as GalleryAlbum;
				for (var i:int=0; i < indices.length; i++) {
					queue.addItem({"action": "delete", "item": album.getItemAt(indices[i])});
				}
				queue.processQueue(
					function(): void {
						GalleryAlbum(dataProvider).refreshResource().addResponder(new GalleryRestResponder(
							function(resource: Object): void {},
							function (fault: Fault): void {
								ErrorDialog.display(fault as Fault);
							}));
					});
			}
		}

		public function onFilesSelected(event:Event, typeMap: Object): void {
			var files: FileReferenceList = event.target as FileReferenceList;
			var queue: ProcessItemQueue = new ProcessItemQueue(ProcessItemQueue.UPLOAD_OPERATION);
			var album: GalleryAlbum = dataProvider as GalleryAlbum;
			for each (var fileRef: FileReference in files.fileList) {
				var item: GalleryItem = GalleryResource.factory("item") as GalleryItem;
				item.url = album.url;			//	When we add set the url to the parent
				item.type = typeMap[fileRef.type.toLowerCase()];
				item.file = fileRef;
				item.name = fileRef.name;
				queue.addItem({"action": "loadFile", "item": item});
			}
			queue.processQueue(
				function(): void {
					GalleryAlbum(dataProvider).refreshResource().addResponder(new GalleryRestResponder(
						function(resource: Object): void {},
						function (fault: Fault): void {
							ErrorDialog.display(fault as Fault);
						}));
				});
		}
		
		// ---------------------------------------------------------------------------
		// Mouse event handlers
		// ---------------------------------------------------------------------------
		protected function mouseDownHandler(event:MouseEvent): void {
			// In the tilelist grid, we are about to either drag or select
			var viewPort:IViewport = scroller.viewport;
			
			// If we are over an actual item, then don't start the lasso
			var eventPos:Point = new Point(event.stageX, event.stageY);
			if (mouseX <= viewPort.contentWidth) {
				_isCtrlKey = event.ctrlKey;
				if (_rendererUnderMouse(eventPos) == null) {
					var parent:Group = this.parent as Group;
					_lasso = new SelectionLasso(new Point(viewPort.contentWidth, viewPort.contentHeight));
					_lasso.owner = this;
					if (!_isCtrlKey) {
						selectedIndices = new Vector.<int>();
						_originalSelection = selectedIndices;
					} else {
						_originalSelection = selectedIndices;
					}
					parent.addElement(_lasso);
				} else {
					_dragStart = eventPos;
					
				}
				stage.addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
				stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
			}
		}

		private function _rendererUnderMouse(eventPos:Point): IItemRenderer {
			var objects:Array = parent.getObjectsUnderPoint(eventPos);
			for (var i:String in objects) {
				if (objects[i] is IItemRenderer) {
					return objects[i];
				}
			}
			return null;
		}
		
		override protected function mouseMoveHandler(event:MouseEvent): void {
			var viewPort:IViewport = scroller.viewport;
			if (_lasso != null) {
				_scrollViewport(viewPort);

				_lasso.setMousePosition(new Point(contentMouseX, contentMouseY + viewPort.verticalScrollPosition));

				_updateSelectedItems(viewPort);
			} else {
				if (DragManager.isDragging) {
					_scrollViewport(viewPort);
				}
				super.mouseMoveHandler(event);
			}
		}

		override public function createDragIndicator() : IFlexDisplayObject {
			var indices:Vector.<int> = selectedIndices;
			indices.sort(function(x:int, y:int): Number{
				return y - x;
			});
			for (var i:int=0; i < indices.length; i++) {
				dataProvider.removeItemAt(indices[i]);
			}
			selectedIndices = new Vector.<int>();

			var proxy:DragProxy = new DragProxy(_items);
			proxy.x = mouseX; proxy.y = mouseY;
			return proxy;
		}
		
		override public function addDragData(dragSource:DragSource) : void {
			_items = selectedItems.splice(0, selectedItems.length);
			dragSource.addHandler(getDragItems, "items");
		}
		
		override protected function mouseUpHandler(event:Event): void {
			if (_lasso) {
				stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
				Group(this.parent).removeElement(_lasso);
				_lasso = null;
			} else {
				// hopefully its already null, but make sure now.
				_dragStart = null;
				super.mouseUpHandler(event);
			}
			// Only process the mouse up event once
			event.stopPropagation();
		}

		//user moves the drag proxy onto the drop target, so allow drop
		override protected function dragEnterHandler(event:DragEvent): void {
			if (!event.isDefaultPrevented()) {
				_acceptItems(event, true);
			}
		}

		//user moves the drag proxy onto the drop target, so allow drop
		override protected function dragOverHandler(event:DragEvent) : void {
			if (!event.isDefaultPrevented()) {
				_acceptItems(event);
			}
		}

		private function _acceptItems(event:DragEvent, onEnter:Boolean= false): void {
			if (event.dragSource.hasFormat("items")) {
				var dropLocation:DropLocation = layout.calculateDropLocation(event); 
				if (dropLocation) {
					if (onEnter) {
						DragManager.acceptDragDrop(this);
						
						// Create the dropIndicator instance. The layout will take care of
						// parenting, sizing, positioning and validating the dropIndicator.
						createDropIndicator();
					}
					
					// Notify manager we can drop
					DragManager.showFeedback(DragManager.MOVE);
					
					// Show drop indicator
					layout.showDropIndicator(dropLocation);
				} else {
					// Hide if previously showing
					layout.hideDropIndicator();
					
					// Notify manager we can't drop
					DragManager.showFeedback(DragManager.NONE);
				}
			}
		}

		override protected function dragCompleteHandler(event:DragEvent): void { 
			var items: Vector.<Object> = event.dragSource.dataForFormat("items") as Vector.<Object>;
			while (items.length > 0) {
				dataProvider.addItem(items.shift());
			}
			super.dragCompleteHandler(event);
		}
		
		override protected function dragDropHandler(event:DragEvent): void {
			//super.dragDropHandler(event);
			if (event.isDefaultPrevented()) {
				return;
			}
			
			// Hide the drop indicator
			layout.hideDropIndicator();
			destroyDropIndicator();
			
			// Get the dropLocation
			var dropLocation:DropLocation = layout.calculateDropLocation(event);
			if (!dropLocation) {
				return;
			}
			
			// Find the dropIndex
			var dropIndex:int = dropLocation.dropIndex;
			
			var items: Vector.<Object> = event.dragSource.dataForFormat("items") as Vector.<Object>;
			var album: GalleryAlbum = dataProvider as GalleryAlbum;
			album.insert(dropIndex, items);

			var self: ThumbGrid = this;
			var queue: ProcessItemQueue = new ProcessItemQueue(ProcessItemQueue.SAVE_OPERATION);
			queue.addItem({"action": "save", "item": album});
			queue.processQueue(
				function(): void {
					album.refreshResource().addResponder(new GalleryRestResponder(
						function(resource: Object): void {
							self.invalidateProperties();
						},
						function (fault: Fault): void {
							ErrorDialog.display(fault as Fault);
						}));
				});
		}
		
		private function _scrollViewport(viewPort:IViewport): void {
			var delta:Number = 30;
			// @todo make sure that x is inside our width
			// @todo look at setting up a scroll timer to see if the mouse
			// is still within the bottom or top 30 as opposed outside the
			// bounds.
			if (-30 < contentMouseY && contentMouseY <= 0) {
				if (scroller.verticalScrollBar.value > scroller.verticalScrollBar.minimum) {
					var minScroll:Number = scroller.verticalScrollBar.value - scroller.verticalScrollBar.minimum;
					delta = minScroll < delta ? -minScroll : -delta;
					viewPort.verticalScrollPosition += delta;
				}
			} else if (height <= contentMouseY && contentMouseY < height + 30) {
				if (scroller.verticalScrollBar.value < scroller.verticalScrollBar.maximum) {
					var maxScroll:Number = scroller.verticalScrollBar.maximum - scroller.verticalScrollBar.value;
					delta = maxScroll < delta ? maxScroll : delta;
					viewPort.verticalScrollPosition += delta;
				}					
			}
		}
		
		private function _updateSelectedItems(viewPort:IViewport): void {
			var selection:Vector.<int> = new Vector.<int>();
			var lassoCoord:Rectangle = _lasso.rectangle;
			var tileLayout: PaddedTileLayout = layout as PaddedTileLayout;

			var columnWidth:int = tileLayout.horizontalGap + tileLayout.columnWidth;
			var rowHeight:int = tileLayout.verticalGap + tileLayout.rowHeight;
			var numberOfColumns:int = Math.round(viewPort.contentWidth / columnWidth);
			
			lassoCoord.inflate(-tileLayout.horizontalGap, -tileLayout.verticalGap);
			var startRow:int = Math.floor(lassoCoord.y / rowHeight)
			var maxRow:int = Math.ceil(lassoCoord.bottom / rowHeight)
			var startCol:int = Math.floor(lassoCoord.x / columnWidth);
			var maxColumn:int = Math.ceil(lassoCoord.right / columnWidth);
			
			for (var row:int = startRow; row < maxRow; row++) {
				for (var column:int = startCol; column < maxColumn; column++) {
					var index:int = row * numberOfColumns + column;
					if (index < dataProvider.length) {
						selection.push(index);
					}
				}
			}
			
			selectedIndices = _union(_originalSelection, selection);
		}
		
		private function _union(array1:Vector.<int>, array2:Vector.<int>): Vector.<int> {
			var union:Vector.<int> = new Vector.<int>;
			if (array1 != null) {
				for (var i:int = 0; i < array1.length; i++) {
					union[i] = array1[i];
				}
				for (i = 0; i < array2.length; i++) {
					if (array1.indexOf(array2[i]) == -1) {
						union.push(array2[i]);
					}
				}
			} else {
				for (i = 0; i < array2.length; i++) {
					union[i] = array2[i];
				}
			}
			return union;
		}
		
		public function getDragItems(): Vector.<Object> {
			return _items;
		}
	}
}