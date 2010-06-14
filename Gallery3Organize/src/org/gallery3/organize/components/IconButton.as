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
	import spark.components.Button;
	import spark.primitives.BitmapImage;
	
	public class IconButton extends Button 	{
		public function IconButton() {
			super();
		}

		//--------------------------------------------------------------------------
		//
		//    Properties
		//
		//--------------------------------------------------------------------------
		
		//----------------------------------
		//  icon
		//----------------------------------
		
		/**
		 *  @private
		 *  Internal storage for the icon property.
		 */
		private var _icon:Class;
		
		[Bindable]
		
		/**
		 *  
		 */
		public function get icon():Class {
			return _icon;
		}
		
		/**
		 *  @private
		 */
		public function set icon(val:Class): void {
			_icon = val;
			
			if (iconElement != null) {
				iconElement.source = _icon;
			}
		}
		
		//--------------------------------------------------------------------------
		//
		//  Skin Parts
		//
		//--------------------------------------------------------------------------
		
		[SkinPart("false")]
		public var iconElement:BitmapImage;
		
		
		//--------------------------------------------------------------------------
		//
		//  Overridden methods
		//
		//--------------------------------------------------------------------------
		
		/**
		 *  @private
		 */
		override protected function partAdded(partName:String, instance:Object):void {
			super.partAdded(partName, instance);
			
			if (icon !== null && instance == iconElement)
				iconElement.source = icon;
		}
}
}