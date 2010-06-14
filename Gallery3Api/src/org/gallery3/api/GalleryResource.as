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
	import com.adobe.serialization.json.JSON;
	import com.adobe.utils.StringUtil;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.net.URLVariables;
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;
	
	import mx.collections.ArrayCollection;
	import mx.core.IUID;
	import mx.events.PropertyChangeEvent;
	import mx.events.PropertyChangeEventKind;
	import mx.rpc.AsyncResponder;
	import mx.rpc.Fault;
	import mx.rpc.events.FaultEvent;
	import mx.utils.ObjectUtil;
	import mx.utils.UIDUtil;
	
	use namespace flash_proxy;	
	[Bindable("propertyChange")]
	public dynamic class GalleryResource extends Proxy implements IEventDispatcher, IUID {

		protected var _eventDispatcher:EventDispatcher;
		protected var _values: Object = {};
		protected var _dirty:Vector.<String> = new Vector.<String>();
		protected var _isNew: Boolean;
		
		public static function loadResource(resourceUri: String, data: URLVariables=null): GalleryRestToken {
			return GalleryRestRequest.factory()
				.setUri(resourceUri)
				.setData(data)
				.setMethod("GET")
				.sendRequest(function(token: GalleryRestToken, data: Object): void {
					var item: Object = JSON.decode(String(data)) as Object;
					
					// matches[1] has the resource type
					// matches[2] should be undefined or an s if the resource is a collection
					// matches[3] should have the resource ID
					var matches: Array = token.uri.match(/(.*?)(s){0,1}(?:\/(\d*))?$/i);
					if (matches[2] != "s") {
						token.resource = GalleryResource.factory(matches[1], item);
					} else {
						var collection: ArrayCollection = new ArrayCollection();
						for (var member: Object in item) {
							collection.addItem(GalleryResource.factory(matches[1], item[member]));
						}
						token.resource = collection;
					}
				});
		}

		public static function factory(resourceType: String, data: Object=null): GalleryResource {
			var resource: GalleryResource;
			switch (resourceType) {
			case "item":
				if (data == null || data.entity.type != "album") {
					resource = new GalleryItem();
					break;
				}
			case "album":
				resource = new GalleryAlbum();
				break;
			case "tag":
				resource = new GalleryTag();
				break;
			default:
				resource = new GalleryResource();
			}
			if (data != null) {
				resource.isNew = false;
				for (var property: String in data) {
					resource[property] = (property == "members") ? new ArrayCollection(data[property]) : data[property];
				}
			}
			
			resource.original = ObjectUtil.clone(resource.entity);

			// Reset the dirty flags
			resource._dirty = new Vector.<String>();
			return resource;
		}

		public function GalleryResource() {
			super();
			_eventDispatcher = new EventDispatcher(this);
			this.entity = {};
			this.relationships = {};
			this.isNew = true;
		}
		
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
		
		flash_proxy override function getProperty(name: *): * {
			return _values[name] || null;
		}
		
		flash_proxy override function setProperty(name: *, value:  *): void {
			var oldValue: * = _values[name];
			_values[name] = value;
			var kind:String = PropertyChangeEventKind.UPDATE;
			_dirty.push(name);
			dispatchEvent(new PropertyChangeEvent(PropertyChangeEvent.PROPERTY_CHANGE, false, false, kind, name, oldValue, value, this));
		}

		/**
		 * Save any local changes made to this resource.  If this is an existing resource, we'll return
		 * the resource itself.  If we're creating a new resource, return the newly created resource.
		 *
		 * @return object  AsyncToken
		 */
		public function save(): GalleryRestToken {
			var dirty: Boolean = isDirty;
			
			var params: URLVariables = new URLVariables();
			params.entity = JSON.encode(this.entity); 
			if (this.members != null) {
				params.members = JSON.encode(this.members.source);
			}
			if (_values.hasOwnProperty("file")) {
				params.file = new URLFileVariable(this.file.data, this.file.name);
			}

			var self: GalleryResource = this;
			return GalleryRestRequest.factory()
				.setUrl(this.url)
				.setData(params)
				.setMethod(isNew ? "POST" : "PUT")
				.sendRequest(function(token: GalleryRestToken, data: Object): void {
					if (token.action == "POST") {
						var item: Object = JSON.decode(String(data)) as Object;
						self.url = item.url;
					}
					
					// Reset the dirty flags
					self._dirty = new Vector.<String>();
					
					token.resource = self;
				});
		}

		/**
		 * Refresh the resource from the server
		 * @param responder Optional responder to handle the results of the refresh
		 * @return object  AsyncToken
		 */
		public function refreshResource(): GalleryRestToken {
			var self: GalleryResource = this;
			return GalleryRestRequest.factory()
				.setUrl(this.url)
				.setMethod("GET")
				.sendRequest(function(token: GalleryRestToken, data: Object): void {
					var item: Object = JSON.decode(String(data)) as Object;
					for (var property: String in item) {
						self[property] = (property == "members") ? new ArrayCollection(item[property]) : item[property];
					}
					
					// Reset the dirty flags
					self._dirty = new Vector.<String>();
	
					token.resource = self;
				});
		}
		
		/**
		 * Refresh the resource from the server
		 * @param responder Optional responder to handle the results of the refresh
		 * @return object  AsyncToken
		 */
		public function deleteResource(): GalleryRestToken {
			return GalleryRestRequest.factory()
				.setUrl(this.url)
				.setMethod("DELETE")
				.sendRequest();
		}
		
		public function toString():String {
			return ObjectUtil.toString(_values);
		}
		
		public function isEntity(): Boolean {
			return _values.hasOwnProperty("entity");
		}
		
		public function isCollection(): Boolean {
			return _values.hasOwnProperty("members");
		}

		public function get isDirty(): Boolean {
			return ObjectUtil.compare(this.original, this.entity) != 0 || _dirty.length > 0;
		}
		
		public function get isNew(): Boolean {
			return _isNew;
		}
		public function set isNew(value: Boolean): void {
			_isNew = value;
		}

		//----------------------------------
		//  IUID interface implementation
		//----------------------------------
		/**
		 *  The unique identifier for this object.
		 */
		public function get uid(): String {
			return this.entity["id"];
		}
		
		/**
		 *  @private
		 */
		public function set uid(value:String): void {
			this.entity["id"] = value;
		}
}
}