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
package org.gallery3.api {
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;

	import mx.core.IUID;
	import mx.events.PropertyChangeEvent;
	import mx.events.PropertyChangeEventKind;

	use namespace flash_proxy;	
	[Bindable("propertyChange")]
	public dynamic class GalleryEntity extends Proxy implements IEventDispatcher, IUID {
		protected var _eventDispatcher:EventDispatcher;
		protected var _values: Object = {};
		protected var _dirty:Vector.<String> = new Vector.<String>();
		
		public function GalleryEntity() {
			super();
			_eventDispatcher = new EventDispatcher(this);
		}

		flash_proxy override function getProperty(name: *): * {
			return name.localName == "dirty" ? this._dirty : (_values[name.localName] || null);
		}
		
		flash_proxy override function setProperty(name: *, value:  *): void {
			if (name.localName == "dirty") {
				this._dirty = value;
			} else {
				var oldValue: * = _values[name.localName];
				_values[name.localName] = value;
				var kind:String = PropertyChangeEventKind.UPDATE;
				_dirty.push(name.localName);
				dispatchEvent(new PropertyChangeEvent(PropertyChangeEvent.PROPERTY_CHANGE, false, false, kind, name, oldValue, value, this));
			}
		}
		
		protected var _propertyNames:Array; // array of object's properties
		flash_proxy override function nextNameIndex(index:int):int {
			if (index == 0) { 					// initial call 
				_propertyNames = new Array(); 
				for (var x:* in _values) { 
					_propertyNames.push(x);
				}
			}
			return (index < _propertyNames.length) ? index + 1 : 0;
		}
		
		override flash_proxy function nextValue(index:int):* {
			return _values[index - 1];
		}
		override flash_proxy function nextName(index:int):String { 
			return _propertyNames[index - 1];
		}
		
		public function get isDirty(): Boolean {
			return _dirty.length > 0;
		}
		
		//----------------------------------
		//  IEventDispatcher interface implementation
		//----------------------------------
		public function addEventListener(type:String, listener:Function, useCapture:Boolean=false, 
										 priority:int=0, useWeakReference:Boolean=false): void {
			_eventDispatcher.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
		
		public function removeEventListener(type:String, listener:Function, useCapture:Boolean=false): void {
			_eventDispatcher.removeEventListener(type, listener, useCapture);
		}
		
		public function dispatchEvent(event:Event): Boolean {
			return _eventDispatcher.dispatchEvent(event);
		}
		
		public function hasEventListener(type:String): Boolean {
			return _eventDispatcher.hasEventListener(type);
		}
		
		public function willTrigger(type:String): Boolean {
			return _eventDispatcher.willTrigger(type);
		}

		//----------------------------------
		//  IUID interface implementation
		//----------------------------------
		/**
		 *  The unique identifier for this object.
		 */
		public function get uid(): String {
			return this._values["id"];
		}
		
		/**
		 *  @private
		 */
		public function set uid(value:String): void {
			this._values["id"] = value;
			this._dirty.push("id");
		}
	}
}