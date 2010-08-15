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
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.errors.IOError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.net.FileReference;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	
	import mx.collections.ArrayCollection;
	import mx.collections.Sort;
	import mx.collections.SortField;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.events.PropertyChangeEvent;
	import mx.events.Request;
	import mx.rpc.AsyncToken;
	
	import org.osmf.utils.URL;
	
	[Bindable("propertyChange")]
	public dynamic class GalleryItem extends GalleryResource {
		private var _isLoading:Boolean = false;
		private var _isLoadingThumbnail:Boolean = false;
		private var _thumbnailData: BitmapData = null;
	
		public function GalleryItem() {}
	
		public function get id(): int {
			return this.entity.id;
		}

		public function get canEdit(): Boolean {
			return this.entity.can_edit;
		}
		
		public function get albumCover(): String {
			return this.entity.album_cover;
		}
		public function set albumCover(value:String): void {
			this.entity.album_cover = value;
		}

		public function get captured(): Date {
			var date: Date = new Date();
			date.setTime(this.entity.captured * 1000);
			return date;
		}
		public function set captured(value: Date): void {
			this.entity.captured = Math.round(value.getTime() / 1000);
		}

		public function get created(): Date {
			var date: Date = new Date();
			date.setTime(this.entity.created * 1000);
			return date;
		}

		public function get description(): String {
			return this.entity.description;
		}
		public function set description(value:String): void {
			this.entity.description = value;
		}

		public function get fullsizeUrl(): String {
			return this.entity.fullsize_url;
		}
				
		public function get height(): String {
			return this.entity.height;
		}
		public function set height(value:String): void {
			this.entity.height = value;
		}

		public function get mimeType(): String {
			return this.entity.mime_type;
		}
		public function set mimeType(value:String): void {
			this.entity.mime_type = value;
		}
		
		public function get name(): String {
			return this.entity.name;
		}
		public function set name(value:String): void {
			this.entity.name = value;
		}
		
		public function get parent(): String {
			return this.entity.parent;
		}
		public function set parent(value:String): void {
			this.entity.parent = value;
		}
		
		public function get randKey(): String {
			return this.entity.rand_key;
		}
		public function set randKey(value:String): void {
			this.entity.rand_key = value;
		}

		public function get resizeDirty(): Boolean {
			return this.entity.resize_dirty;
		}
		public function set resizeDirty(value:Boolean): void {
			this.entity.resize_dirty = value;
		}
		
		public function get resizeHeight(): Number {
			return Number(this.entity.resize_height);
		}
		public function set resizeHeight(value:Number): void {
			this.entity.resize_height = value;
		}

		public function get resizeUrl(): String {
			return this.entity.resize_url;
		}

		public function get resizeWidth(): Number {
			return Number(this.entity.resize_width);
		}
		public function set resizeWidth(value:Number): void {
			this.entity.resize_width = value;
		}

		public function get slug(): String {
			return this.entity.slug;
		}
		public function set slug(value:String): void {
			this.entity.slug = value;
		}
		
		[Bindable(event=PropertyChangeEvent.PROPERTY_CHANGE)]
		public function get thumbnailData(): BitmapData {
			if (_thumbnailData == null && !_isLoadingThumbnail) {
				if (!_isLoadingThumbnail) {
					_isLoadingThumbnail = true;
					var loader:Loader = new Loader();
					var self:GalleryItem = this;
					loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(event:Event): void {
						_thumbnailData = Bitmap(loader.content).bitmapData.clone();
						dispatchEvent(PropertyChangeEvent.createUpdateEvent(self, "thumbnailData", null, _thumbnailData));
						_isLoadingThumbnail = false;
					});
					loader.contentLoaderInfo.addEventListener(HTTPStatusEvent.HTTP_STATUS, function(event:HTTPStatusEvent): void {
						_isLoadingThumbnail = false;
						if (event.status != 200 && event.status != 404) {
							// log the error, but don't display an error... the user will just see the default image
							trace(event.status + ": " + GalleryRestRequest.HTTP_STATUS);
						}
					});
					loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,  function(event:IOErrorEvent): void {
						// log the error, but don't display an error... the user will just see the default image
						trace(event.text);
					});
					
					// If there's a public url, use that because it'll be faster.  Else make a RESTful request
					// to the data resource.
					if (thumbUrlPublic) {
						loader.load(new URLRequest(thumbUrlPublic));
					} else {
						// @todo: refactor this into GalleryRestRequest
						var req:URLRequest = new URLRequest(thumbUrl);
						req.method = URLRequestMethod.POST;
						req.requestHeaders = [
							new URLRequestHeader("Accept", "*/*"),
							new URLRequestHeader("Cache-Control", "no-cache"),
							new URLRequestHeader("X_GALLERY_REQUEST_METHOD", "GET"),
							new URLRequestHeader("X_GALLERY_REQUEST_KEY", GalleryRestRequest.accessKey)
						];
						var url:URL = new URL(thumbUrl);
						var size:String = url.getParamValue("size");
						var urlVariables:URLVariables = new URLVariables();
						urlVariables.size = size;
						req.data = urlVariables;
						loader.load(req);
					}
				}
			}			
			return _thumbnailData;
		}
		
		public function get thumbHeight(): Number {
			return Number(this.entity.thumb_height);
		}
		public function set thumbHeight(value:Number): void {
			this.entity.thumb_height = value;
		}

		public function get thumbUrl(): String {
			return this.entity.thumb_url;
		}
		
		public function get thumbUrlPublic(): String {
			return this.entity.thumb_url_public;
		}
		
		public function get thumbWidth(): Number {
			return Number(this.entity.thumb_width);
		}
		public function set thumbWidth(value:Number): void {
			this.entity.thumb_width = value;
		}

		public function get title(): String {
			return this.entity.title;
		}
		public function set title(value:String): void {
			this.entity.title = value;
		}
		
		public function get type(): String {
			return this.entity.type;
		}
		public function set type(value:String): void {
			this.entity.type = value;
		}
		
		public function get updatedDate(): Date {
			var date: Date = new Date();
			date.setTime(this.entity.updated * 1000);
			return date;
		}
		
		public function get viewCount(): Number {
			return Number(this.entity.view_count);
		}
		public function set viewCount(value:Number): void {
			this.entity.view_count = value;
		}
		
		public function get weight(): Number {
			return Number(this.entity.weight);
		}
		public function set weight(value:Number): void {
			this.entity.weight = value;
		}
		
		public function get width(): Number {
			return Number(this.entity.width);
		}
		public function set width(value:Number): void {
			this.entity.width = value;
		}
		
		public function get isLoading(): Boolean {
			return this._isLoading;
		}
		public function set isLoading(value:Boolean): void {
			this._isLoading = value;
		}
		
		public function get label(): String {
			return title;
		}

		public function loadFile(): GalleryRestToken {
			var token: GalleryRestToken = new GalleryRestToken();
			var self: GalleryItem = this;
			this.file.addEventListener(Event.COMPLETE, function(event: Event): void {
				token.resource = self;
			});
			this.file.load();
			return token;
		}
	}
}