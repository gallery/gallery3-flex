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
	import flash.external.ExternalInterface;
	
	import mx.core.FlexGlobals;
	
	import spark.components.Application;
	
	[Bindable]
	public class OrganizeStyle {
		private static var _instance:OrganizeStyle = null;
		
		public static function get instance(): OrganizeStyle {
			if (_instance == null) {
				_instance = new OrganizeStyle();
				var colors:Object = ExternalInterface.call("getOrganizeStyles");
				var appl:Application = FlexGlobals.topLevelApplication as Application;
				for (var key:String in colors) {
					appl.setStyle(key, colors[key]);
				} 
				appl.setStyle("baseColor", colors["backgroundColor"]);
				appl.setStyle("contentBackgroundColor", colors["backgroundColor"]);
			}
			return _instance;
		}
		
		public function OrganizeStyle() {}

		public function get baseColor(): uint {
			return FlexGlobals.topLevelApplication.getStyle("baseColor");
		}
		
		public function get backgroundColor(): uint {
			return FlexGlobals.topLevelApplication.getStyle("backgroundColor");
		}
		
		public function get contentBackgroundColor(): uint {
			return FlexGlobals.topLevelApplication.getStyle("contentBackgroundColor");
		}
		
		public function get color(): uint {
			return FlexGlobals.topLevelApplication.getStyle("color");
		}
		
		public function get borderColor(): uint {
			return FlexGlobals.topLevelApplication.getStyle("borderColor");
		}
		
		public function get rollOverColor(): uint {
			return FlexGlobals.topLevelApplication.getStyle("rollOverColor");
		}
		
		public function get selectionColor(): uint {
			return FlexGlobals.topLevelApplication.getStyle("selectionColor");
		}
	}	
}