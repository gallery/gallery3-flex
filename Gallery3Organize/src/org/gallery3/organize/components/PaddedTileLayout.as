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
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import mx.core.ILayoutElement;
	import mx.core.IVisualElement;
	
	import spark.components.DataGroup;
	import spark.components.List;
	import spark.components.supportClasses.GroupBase;
	import spark.layouts.supportClasses.DropLocation;
	import spark.layouts.supportClasses.LayoutBase;
	
	public class PaddedTileLayout extends LayoutBase {
		private var _previousRenderer: Object = null;
		//---------------------------------------------------------------
		//
		//  Class properties
		//
		//---------------------------------------------------------------
		private var _usableWidth:Number		
		private var _dropIndicator:DropIndicator;

		//---------------------------------------------------------------
		//  columnWidth
		//---------------------------------------------------------------
		private var _columnCount:Number;
		public function get columnCount(): Number {
			return _columnCount;
		}

		//---------------------------------------------------------------
		//  columnWidth
		//---------------------------------------------------------------
		private var _columnWidth:Number = 100;
		public function get columnWidth(): Number {
			return _columnWidth;
		}
		public function set columnWidth(value:Number): void {
			_columnWidth = value;
			
			// We must invalidate the layout
			var layoutTarget:GroupBase = target;
			if (layoutTarget) {
				layoutTarget.invalidateSize();
				layoutTarget.invalidateDisplayList();
			}
		}
		
		//---------------------------------------------------------------
		//  rowHeight
		//---------------------------------------------------------------
		private var _rowHeight:Number = 10;
		public function get rowHeight(): Number {
			return _rowHeight;
		}
		public function set rowHeight(value:Number): void {
			_rowHeight = value;
			
			// We must invalidate the layout
			var layoutTarget:GroupBase = target;
			if (layoutTarget) {
				layoutTarget.invalidateSize();
				layoutTarget.invalidateDisplayList();
			}
		}

		//---------------------------------------------------------------
		//  rowCount
		//---------------------------------------------------------------
		private var _rowCount:Number;
		public function get rowCount(): Number {
			return _rowCount;
		}

		//---------------------------------------------------------------
		//  horizontalGap
		//---------------------------------------------------------------
		private var _horizontalGap:Number = 10;
		private var _measuredHGap:Number = -1;
		public function get horizontalGap(): Number {
			return _measuredHGap == -1 ? _horizontalGap : _measuredHGap;
		}
		public function set horizontalGap(value:Number): void {
			_horizontalGap = value;
			
			// We must invalidate the layout
			var layoutTarget:GroupBase = target;
			if (layoutTarget) {
				layoutTarget.invalidateSize();
				layoutTarget.invalidateDisplayList();
			}
		}
		
		//---------------------------------------------------------------
		//  verticalGap
		//---------------------------------------------------------------
		private var _verticalGap:Number = 10;
		public function get verticalGap(): Number {
			return _verticalGap;
		}
		public function set verticalGap(value:Number): void {
			_verticalGap = value;
			
			// We must invalidate the layout
			var layoutTarget:GroupBase = target;
			if (layoutTarget) {
				layoutTarget.invalidateSize();
				layoutTarget.invalidateDisplayList();
			}
		}
		
		//---------------------------------------------------------------
		//  verticalAlign
		//---------------------------------------------------------------
		private var _verticalAlign:String = "bottom";
		public function set verticalAlign(value:String): void {
			_verticalAlign = value;
			
			// We must invalidate the layout
			var layoutTarget:GroupBase = target;
			if (layoutTarget) {
				layoutTarget.invalidateSize();
				layoutTarget.invalidateDisplayList();
			}
		}
		
		//---------------------------------------------------------------
		//  horizontalAlign
		//---------------------------------------------------------------
		private var _horizontalAlign:String = "left"; // center, right
		
		public function set horizontalAlign(value:String): void {
			_horizontalAlign = value;
			
			// We must invalidate the layout
			var layoutTarget:GroupBase = target;
			if (layoutTarget) {
				layoutTarget.invalidateSize();
				layoutTarget.invalidateDisplayList();
			}
		}
		
		//---------------------------------------------------------------
		//
		//  Class methods
		//
		//---------------------------------------------------------------
		override public function updateDisplayList(containerWidth:Number, containerHeight:Number): void {
			var element:ILayoutElement;
			var layoutTarget:GroupBase = target;
			var count:int = layoutTarget.numElements;
			
			_usableWidth = containerWidth - 2 * _horizontalGap;
			_columnCount = Math.floor(_usableWidth / (_columnWidth + _horizontalGap));
			_rowCount = Math.ceil(count / _columnCount);
			
			if (_horizontalAlign == "justify") {
				_measuredHGap = _horizontalGap + (_usableWidth - (_columnCount * (_columnWidth + _horizontalGap))) / (_columnCount + 1);
			} else {
				_measuredHGap = -1;
			}
			// The position for the current element
			var x:Number = 0;
			var y:Number = _verticalGap;
			var elementWidth:Number;
			var elementHeight:Number;
			
			var vAlign:Number = 0;
			switch (_verticalAlign) {
			case "middle" : 
				vAlign = 0.5; 
				break;
			case "bottom" : 
				vAlign = 1; 
				break;
			}
			
			// Keep track of per-row height, maximum row width
			var maxRowWidth:Number = 0;
						
			// loop through the elements
			// while we can start a new row
			var rowStart:int = 0;
			while (rowStart < count) {
				var hGap:Number = horizontalGap;
				// The row always contains the start element
				element = useVirtualLayout ? layoutTarget.getVirtualElementAt(rowStart) :
					layoutTarget.getElementAt(rowStart);
				
				var rowWidth:Number = element.getPreferredBoundsWidth();
				var rowHeight:Number = element.getPreferredBoundsHeight();
				
				// Find the end of the current row
				var rowEnd:int = rowStart;
				while (rowEnd + 1 < count) {
					element = useVirtualLayout ? layoutTarget.getVirtualElementAt(rowEnd + 1) :
						layoutTarget.getElementAt(rowEnd + 1);
					
					// Since we haven't resized the element just yet, get its preferred size
					elementWidth = element.getPreferredBoundsWidth();
					elementHeight = element.getPreferredBoundsHeight();

					// Can we add one more element to this row?
					if (rowWidth + hGap + elementWidth > _usableWidth) {
						break;
					}
					
					rowWidth += hGap + elementWidth;
					rowHeight = Math.max(rowHeight, elementHeight);
					rowEnd++;
				}
				
				// Update the position to the beginning of the row
				x = hGap;
				switch (_horizontalAlign) {
				case "center" : 
					x = Math.round(_usableWidth - rowWidth) / 2; 
					break;
				case "right" : 
					x = _usableWidth - rowWidth;
					break;
				case "justify" : 
				}
				
				// Keep track of the maximum row width so that we can
				// set the correct contentSize
				maxRowWidth = Math.max(maxRowWidth, x + rowWidth + hGap);
				
				// Layout all the elements within the row
				for (var i:int = rowStart; i <= rowEnd; i++) {
					element = useVirtualLayout ? layoutTarget.getVirtualElementAt(i) : 
						layoutTarget.getElementAt(i);
					
					// Resize the element to its preferred size by passing
					// NaN for the width and height constraints
					element.setLayoutBoundsSize(NaN, NaN);
					
					// Find out the element's dimensions sizes.
					// We do this after the element has been already resized
					// to its preferred size.
					elementWidth = element.getLayoutBoundsWidth();
					elementHeight = element.getLayoutBoundsHeight();
					
					// Calculate the position within the row
					var elementY:Number = Math.round((rowHeight - elementHeight) * vAlign);
					
					// Position the element
					element.setLayoutBoundsPosition(x, y + elementY);
					
					x += hGap + elementWidth;
				}
				
				// Next row will start with the first element after the current row's end
				rowStart = rowEnd + 1;
				
				y += rowHeight + _verticalGap;
			}
			
			// Set the content size which determines the scrolling limits
			// and is used by the Scroller to calculate whether to show up
			// the scrollbars when the the scroll policy is set to "auto"
			layoutTarget.setContentSize(maxRowWidth, y);
		}
		
		override protected function calculateDropIndicatorBounds(dropLocation:DropLocation) : Rectangle {
			var bounds:Rectangle = new Rectangle();
			bounds.width = 3;
			bounds.height = 110;
			
			var insertPosition: Object = calculateInsertRenderer(dropLocation.dropPoint);
			if (insertPosition.renderer) {
				if (insertPosition.isBefore) {
					bounds.x = insertPosition.renderer.x - (horizontalGap / 2);
				} else {
					bounds.x = insertPosition.renderer.x + insertPosition.renderer.width + (horizontalGap / 2);
				}
				bounds.y = insertPosition.renderer.y;
			} 

			return bounds;
		}
		
		protected function calculateInsertRenderer(dropPoint: Point): Object {
			var insertPosition: Object = {renderer: null, isBefore: true, index: -1};
			var renderer: IVisualElement = null;

			var maxWidth: Number = _columnCount * (_columnWidth + _horizontalGap) + _horizontalGap;
			var position:Point = new Point(Math.min(dropPoint.x, maxWidth), dropPoint.y);
			var dataGroup: DataGroup = DataGroup(target);			
			for each (var itemIndex:Number in dataGroup.getItemIndicesInView()) {
				renderer = dataGroup.getElementAt(itemIndex);
				var rendererBounds:Rectangle = new Rectangle(renderer.x, renderer.y, renderer.width, renderer.height);
				rendererBounds.inflate(horizontalGap, verticalGap);
				if (rendererBounds.containsPoint(position)) {
					break;
				}
			}
			if (renderer) {
				if (dropPoint.x >= rendererBounds.x + rendererBounds.width / 2) {
					insertPosition.isBefore = false;
				}
				insertPosition.renderer = renderer;
				insertPosition.index = itemIndex;
				_previousRenderer = insertPosition;
			} else {
				insertPosition.renderer = insertPosition;
			} 
			return insertPosition;
		}
		
		override protected function calculateDropIndex(x:Number, y:Number) : int {
			var insertPosition: Object = calculateInsertRenderer(new Point(x, y));
			
			// the return value is in the range 0 - number of elements.  
			return insertPosition.index + (insertPosition.isBefore ? 0 : 1);
		}
	}
}
