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
	import org.gallery3.api.GalleryItem;
	import spark.components.BorderContainer;
	
	import spark.components.BorderContainer;
	import spark.layouts.ColumnAlign;
	import spark.layouts.RowAlign;
	import spark.layouts.VerticalAlign;
	import spark.layouts.TileLayout;
	import spark.layouts.TileOrientation;
	import spark.primitives.BitmapImage;
	
	public class DragProxy extends BorderContainer {
		public function DragProxy(items:Vector.<Object>) {
			super();
			setStyle("backgroundAlpha", 0.5);
			
			var proxyLayout: TileLayout = new TileLayout();
			
			var dragColumns:int = Math.min(items.length, 6);
			var dragRows:int = Math.ceil(items.length / 6);
			with (proxyLayout) {
				orientation = TileOrientation.ROWS;
				columnAlign = ColumnAlign.JUSTIFY_USING_WIDTH;
				columnWidth = 20;
				horizontalGap = 2;
				requestedColumnCount = dragColumns;
				rowAlign = RowAlign.TOP;
				verticalAlign = VerticalAlign.MIDDLE;
			}
			
			layout = proxyLayout;
			width = 4 + dragColumns * (200 * 0.1)/*maxProxyWidth*/ + (dragColumns - 1) * 2;
			height = 4 + dragRows * ((200 * 0.1) /*maxProxyHeight*/ + 2);
			
			for (var i:int = 0; i < items.length; i++) {
				var image:BitmapImage = new BitmapImage();
				image.source = GalleryItem(items[i]).thumbnailData;
				image.scaleY = image.scaleX = .1;
				addElement(image);
			}
		}
	}
}