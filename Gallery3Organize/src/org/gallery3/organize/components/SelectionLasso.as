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
    import flash.display.BitmapData;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    import mx.core.UIComponent;
    
    import org.gallery3.organize.OrganizeStyle;
    
    import spark.core.IViewport;

	public class SelectionLasso extends UIComponent {
		private var _horizontalBitmap:BitmapData;
        private var _verticalBitmap:BitmapData;
        private var _bitmapScroll:Number = 0;
		private var _startPos:Point = null;
        private var _rawRegion:Rectangle = new Rectangle();
		private var _constraints:Rectangle;
		
		/**
		 * Create a selection lasso
		 * 
		 * @param constraints Point maximum height and width of the selection region.
		 */
		public function SelectionLasso(constraints:Point) {
			super();
			_constraints = new Rectangle(0, 0, constraints.x, constraints.y);
            includeInLayout = false;
            initBitmaps();
            invalidateDisplayList();
		}

		public function get rectangle(): Rectangle {
			return _constraints.intersection(_rawRegion.clone());
		}

		/**
		 * Set the current position of the mouse
		 * @param mousePos Point location of the mouse in the owner content coordinates
		 */
		public function setMousePosition(mousePos:Point):void {
			_startPos = _startPos == null ? mousePos : _startPos;

			_rawRegion.topLeft = _startPos;
			_rawRegion.bottomRight = mousePos;
			if (_rawRegion.height < 0) {
				var rawRegionY:Number = _rawRegion.top;
				_rawRegion.top = _rawRegion.bottom;
				_rawRegion.bottom = rawRegionY;
			}
			if (_rawRegion.width < 0) {
				var rawRegionX:Number = _rawRegion.left;
				_rawRegion.left = _rawRegion.right;
				_rawRegion.right = rawRegionX;
			}
			
			if (initialized) {
				update();
			}
		}

        private function scrollBitmaps():void {
            _bitmapScroll = (++_bitmapScroll) % 4;
        }
        
        private function initBitmaps():void {
			_horizontalBitmap = new BitmapData(4, 2, false, OrganizeStyle.instance.borderColor);
			_verticalBitmap = new BitmapData(2, 4, false, OrganizeStyle.instance.borderColor);
        	for(var _x:Number = 0; _x < 2; _x++){
                for(var _y:Number = 0; _y < 2; _y++){
                    _horizontalBitmap.setPixel(_x, _y, OrganizeStyle.instance.contentBackgroundColor);
                    _verticalBitmap.setPixel(_x, _y, OrganizeStyle.instance.contentBackgroundColor);
                }
            }
        }
        
        private function update():void {
            scrollBitmaps();
            graphics.clear();

			// Get a copy of the selection lasso coordinates
			var rect:Rectangle = rectangle;
			var viewPort:IViewport = ThumbGrid(owner).scroller.viewport;
			
			// Create the clipping region that corresponds to the visible area of the owner
			var clippingRect: Rectangle = new Rectangle(0, viewPort.verticalScrollPosition, owner.width, 
				viewPort.verticalScrollPosition + owner.height);
			rect = clippingRect.intersection(rect);
			
			var drawTop:Boolean = rectangle.x >= rect.x;
			var drawBottom:Boolean = rectangle.bottom >= rect.bottom;

			// Reset the clipping rectangle to visible coordinates
			rect.offset(0, -viewPort.verticalScrollPosition);

			// Convert the clipping rectangle to this coordinate system
			var ownerRect:Rectangle = owner.getBounds(parent);
			rect.offsetPoint(ownerRect.topLeft);

			graphics.beginBitmapFill(_horizontalBitmap, new Matrix(1, 0, 0, 1, _bitmapScroll, 0),true,false);
			if (drawTop) {
				graphics.drawRect(rect.x, rect.y - 1, rect.width, 1);
			}
			if (drawBottom) {
				graphics.drawRect(rect.x, rect.bottom, rect.width, 1);
			}
			
            graphics.beginBitmapFill(_verticalBitmap, new Matrix(1, 0, 0, 1, 0, _bitmapScroll),true,false);
            graphics.drawRect(rect.x - 1, rect.y - 1, 1, rect.height + 2);
            graphics.drawRect(rect.right, rect.y - 1, 1, rect.height + 2);
        }
	}
}