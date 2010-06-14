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
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.external.ExternalInterface;
	import flash.utils.flash_proxy;
	import flash.utils.Proxy;
	
	import mx.events.PropertyChangeEvent;

	[Bindable("propertyChange")]
	dynamic public class OrganizeText extends Proxy implements IEventDispatcher {
		private static var _instance:OrganizeText = null;
		
		private var _evtDispatcher: IEventDispatcher;
		private var _data: Object;
		
		public static function get instance(): OrganizeText {
			if (_instance == null) {
				_instance = new OrganizeText();
			}
			return _instance;
		}
		
		public function OrganizeText() {
			_evtDispatcher = new EventDispatcher();
			_data = ExternalInterface.call("getTextStrings");
			for (var key: String in _data) {
				dispatchEvent(PropertyChangeEvent.createUpdateEvent(this, key, null, _data[key]));
			}
		}
		
		flash_proxy override function getProperty(name: *): * {
			return _data[name];
		}
		
		flash_proxy override function setProperty(name: *, value: *): void {
			var oldValue: * = _data[name];
			_data[name] = value;
			dispatchEvent(PropertyChangeEvent.createUpdateEvent(this, name, oldValue, value));
		}
		
		public function addEventListener(type: String, listener: Function, useCapture: Boolean = false, priority:int=0.0, useWeakReference:Boolean=false): void {
			_evtDispatcher.addEventListener(type, listener, useCapture);
		}
		
		public function removeEventListener(type: String, listener: Function, useCapture: Boolean = false): void {
			_evtDispatcher.removeEventListener(type, listener, useCapture);
		}
		
		public function dispatchEvent(event: Event): Boolean {
			return _evtDispatcher.dispatchEvent(event);
		}
		
		public function hasEventListener(type: String): Boolean {
			return _evtDispatcher.hasEventListener(type);
		}
		
		public function willTrigger(type: String): Boolean {
			return _evtDispatcher.willTrigger(type);
		}
	}
}