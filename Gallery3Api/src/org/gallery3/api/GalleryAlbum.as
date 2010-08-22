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
	import com.adobe.utils.ArrayUtil;
	
	import flash.events.Event;
	import flash.net.URLVariables;
	import flash.utils.flash_proxy;
	
	import mx.collections.ArrayCollection;
	import mx.collections.ICollectionView;
	import mx.collections.IList;
	import mx.collections.IViewCursor;
	import mx.collections.Sort;
	import mx.collections.SortField;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.events.PropertyChangeEvent;
	import mx.events.PropertyChangeEventKind;
	import mx.rpc.Fault;
	import mx.rpc.events.FaultEvent;
	import mx.utils.ArrayUtil;
	import mx.utils.ObjectUtil;

	use namespace flash_proxy;	
	
	[Event(name="collectionChange", type="mx.events.CollectionEvent")]
	[Bindable("propertyChange")]
	[Bindable("collectionChange")]
	public dynamic class GalleryAlbum extends GalleryItem implements IList, ICollectionView {
		private var _childrenLoaded: Boolean = false;
		private var _albumsLoaded: Boolean = false;
		private var _children:ArrayCollection = new ArrayCollection();
		private var _albums:ArrayCollection = new ArrayCollection();
		
		public function GalleryAlbum() {
			this.members = new ArrayCollection();
			var self: GalleryAlbum = this;
			_children.addEventListener(CollectionEvent.COLLECTION_CHANGE, 
				function(event: CollectionEvent): void {
					var newEvent: CollectionEvent = 
						new CollectionEvent(CollectionEvent.COLLECTION_CHANGE, event.bubbles, event.cancelable, event.kind,
							event.location, event.oldLocation, event.items);
					self.dispatchEvent(newEvent);
				});
		}		

		public function get sortColumn(): String {
			return this.entity.sort_column;
		}
		public function set sortColumn(value:String): void {
			this.entity.sort_column = value;
		}

		public function get sortOrder(): String {
			return this.entity.sort_order;
		}
		public function set sortOrder(value:String): void {
			this.entity.sort_order = value;
		}

		flash_proxy override function getProperty(name: *): * {
			switch (name.localName) {
				case "label":
					return super.getProperty("title") + " (" + super.getProperty("members").length + ")";
				case "albums":
					if ((!_albumsLoaded && (this.members.source as Array).length > 0)) {
						loadAlbums();
					}
					return _albums;
				default:
					// Do nothing;
					break;
			}
			return super.getProperty(name);
		}

		flash_proxy override function setProperty(name: *, value:  *): void {
			if (name == "albums") {
				var oldValue: * = _albums;
				_albums = value;
				var kind:String = PropertyChangeEventKind.UPDATE;
				dispatchEvent(new PropertyChangeEvent(PropertyChangeEvent.PROPERTY_CHANGE, false, false, kind, name, oldValue, value, this));
			} else {
				super.setProperty(name, value);
			}
		}
		
		public function insert(at:int, items: Vector.<Object>): void {
			for (var idx: int=at; items.length > 0; idx++) {
				var item: GalleryItem = items.shift();
				this.members.addItemAt(item.url, idx);
			}
			_dirty.push("members");
			sortColumn = "weight";
			sortOrder = "ASC";
		}

		/**
		 *  @see mx.collections.ICollectionView#refresh()
		 */
		public override function refreshResource(): GalleryRestToken {
			var membersDirty: Boolean = _dirty.indexOf("members") > -1;
			var token: GalleryRestToken = super.refreshResource();
			var self: GalleryAlbum = this;
			token.addResponder(new GalleryRestResponder(
				function (resource: Object): void {
					loadChildren();
					loadAlbums();
				},
				function (fault: Fault): void {
					isLoading = false;
					token.dispatchEvent(new FaultEvent(FaultEvent.FAULT, false, true, fault));
				}));
			return token;
		}

		public function loadChildren():void {
			if (!isLoading) {
				isLoading = true;
				
				if (this.members.length > 0) {
					var params: URLVariables = new URLVariables();
					params.urls = JSON.encode(this.members.source);
					
					var token: GalleryRestToken = GalleryResource.loadResource("items", params);
					var self: GalleryAlbum = this;
					token.addResponder(new GalleryRestResponder(
						function (resource: Object): void {
							_updateChildren(resource);
						},
						function (fault: Fault): void {
							isLoading = false;
							// @todo just throw it now and let flex's global error handler deal with it
							// in a future release, they will probably have some kind glabal error handler.
							throw fault;
						}));
				} else {
					_updateChildren();
				}
	  		}
		}
		
		public function loadAlbums():void {
			if (this.members.length > 0) {
				var params: URLVariables = new URLVariables();
				params.urls = JSON.encode(this.members.source);
				params.type = "album";
				var token: GalleryRestToken = GalleryResource.loadResource("items", params);
				token.addResponder(new GalleryRestResponder(
					function (resource: Object): void {
						_updateAlbums(resource);
					},
					function (fault: Fault): void {
						// @todo just throw it now and let flex's global error handler deal with it
						// in a future release, they will probably have some kind glabal error handler.
						throw fault;
					}));
			} else {
				_updateAlbums();
			}
			_albumsLoaded = true;
		}
		
		private function _updateChildren(items:Object=null):void {
			isLoading = false;
			_childrenLoaded = true;
			_children.removeAll();
			for each (var element:Object in items) {
				_children.addItem(element);
			}
		}

		private function _updateAlbums(items:Object=null):void {
			_albums.removeAll();
			for each (var element:Object in items) {
				_albums.addItem(element);
			}
			_albums.dispatchEvent(new Event("AlbumLoaded", true));
		}

		//--------------------------------------------------------------------------
		//  ICollectionView Interface Implementation
		//--------------------------------------------------------------------------
		/**
		 *  @see mx.collections.ICollectionView#filterFunction()
		 */
		public function get filterFunction():Function {
			return _children.filterFunction;
		}
		
		/**
		 *  @see mx.collections.ICollectionView#filterFunction()
		 *  @private
		 */
		public function set filterFunction(value:Function):void {
			_children.filterFunction = value;
		}
		
		/**
		 *  @see mx.collections.ICollectionView#sort()
		 */
		public function get sort():Sort {
			return _children.sort;
		}
		
		/**
		 *  @see mx.collections.ICollectionView#sort()
		 *  @private
		 */
		public function set sort(value:Sort):void {
			_children.sort = value;
		}
		
		/**
		 *  @see mx.collections.ICollectionView#createCursor()
		 */
		public function createCursor():IViewCursor {
			return _children.createCursor();
		}
		
		/**
		 *  @see mx.collections.ICollectionView#contains()
		 */
		public function contains(item:Object):Boolean {
			return _children.contains(item);
		}
		
		/**
		 *  @see mx.collections.ICollectionView#disableAutoUpdate()
		 */
		public function disableAutoUpdate():void {
			_children.disableAutoUpdate();
		}
		
		/**
		 *  @see mx.collections.ICollectionView#enableAutoUpdate()
		 */
		public function enableAutoUpdate():void {
			_children.enableAutoUpdate();
		}
		
		/**
		 *  @see mx.collections.ICollectionView#refresh()
		 */
		public function refresh():Boolean {
			loadChildren();
			return true;
		}

		//--------------------------------------------------------------------------
		//  IList Interface Implementation
		//--------------------------------------------------------------------------
		/**
		 *  @see mx.collections.ICollectionView#length()
		 *  @see mx.collections.IList#length()
		 */
		public function get length():int {
			return isLoading ? -1: this._children.length;
		}
			
		/**
		 *  @see mx.collections.IList#addItem()
		 */
		public function addItem(item:Object):void {
			addItemAt(item, _children.length);
		}
			
		/**
		 *  @see mx.collections.IList
		 */
		public function addItemAt(item:Object, index:int):void {
			this.members.addItemAt(item.url, index);
			this._children.addItemAt(item, index);
			itemUpdated(item);
		}
			
		/**
		 *  @see mx.collections.IList
		 */
		public function getItemAt(index:int, prefetch:int = 0):Object {
			return this._children.getItemAt(index, prefetch);
		}
			
		/**
		 *  @see mx.collections.IList
		 */
		public function getItemIndex(item:Object):int {
			return this._children.getItemIndex(item);
		}
			
		/**
		 *  @see mx.collections.ICollectionView#itemUpdated()
		 *  @see mx.collections.IList
		 */
		public function itemUpdated(item:Object, property:Object = null, 
							 oldValue:Object = null, 
							 newValue:Object = null):void {
			_children.itemUpdated(item, property, oldValue, newValue);
		}
		
		/** 
		 * @see mx.collections.IList#removeAll()
		 * 
		 * Note: This does not update the remote server, its effect is only local.
		 */
		public function removeAll():void {
			_children.removeAll();
		}
		
		/**
		 * @see mx.collections.IList#removeItemAt()
		 * 
		 * Note: This doesn't update the remote server, its effect is only local.
		 */
		public function removeItemAt(index:int):Object {
			this.members.removeItemAt(index);
			var o:GalleryItem = _children.removeItemAt(index) as GalleryItem;
			itemUpdated(o);
			return o;
		}
		
		/**
		 * @see mx.collections.IList#setItemAt()
		 * 
		 * Note: This does not update the remote server, its effect is only local.
		 */
		public function setItemAt(item:Object, index:int):Object {
			this.members.setItemAt(item.url, index);
			var o:GalleryItem = _children.setItemAt(item, index) as GalleryItem;
			
			itemUpdated(o);
			return o;
		}
			
		/**
		 *  @see mx.collections.IList
		 */ 
		public function toArray():Array {
			return _children.toArray();
		}
	}
}