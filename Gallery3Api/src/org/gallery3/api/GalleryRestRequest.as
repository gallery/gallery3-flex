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
 * 
 * This code is based on the work of Mike Stead (http://blog.mikestead.me/category/actionscript-3-0/)
 * 
 */
package org.gallery3.api {
	import com.adobe.serialization.json.JSON;
	import com.adobe.utils.StringUtil;
	
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.utils.ByteArray;
	
	import mx.messaging.messages.HTTPRequestMessage;
	import mx.rpc.Fault;

	public class GalleryRestRequest {
		public static var HTTP_STATUS: Object = {
			"100": "Continue",
			"200": "Ok",
			"302": "Found",
			"304": "Not Modified",
			"400": "Bad Request",
			"401": "Unauthorized",
			"403": "Forbidden",
			"404": "Not Found",
			"405": "Method Not Allowed",
			"500": "Internal Server Error"
		}
		private static const X_GALLERY_REQUEST_METHOD: String = "X-Gallery-Request-Method";
		private static const X_GALLERY_REQUEST_KEY: String = "X-Gallery-Request-Key";
		private static const MULTIPART_BOUNDARY: String  = "----------196f00b77b968397849367c61a2080";
		private static const MULTIPART_MARK: String      = "--";
		private static const LF: String                  = "\r\n";
		
		private static var _baseUrl: String;
		private static var _accessKey: String;
		
		public static function get baseURL(): String {
			if (_baseUrl == null) {
				throw new Error("REST interface base URL has not been set");
			}
			return _baseUrl; 
		}
		public static function set baseURL(url: String): void {
			_baseUrl = url;
		}

		public static function get accessKey(): String {
			if (_accessKey == null) {
				throw new Error("REST interface access key has not been set");
			}
			return _accessKey; 
		}
		public static function set accessKey(accessKey: String): void {
			_accessKey = accessKey;
		}
		
		public static function factory(accessKey: String=null): GalleryRestRequest {
			return new GalleryRestRequest(accessKey);
		}
		
		private var _contentType: String = null;
		private var _data: URLVariables = new URLVariables;
		private var _digest: String = null;
		private var _method: String = URLRequestMethod.GET;
		private var _uri: String = null;
		private var _requestHeaders: Array = new Array();
		private var _requestAccessKey: String = null;
		
		public function GalleryRestRequest(accessKey: String=null) {
			_requestAccessKey = accessKey == null ? GalleryRestRequest.accessKey : accessKey;
		}
		
		public function get data(): URLVariables {return _data;}
		public function setData(value: URLVariables): GalleryRestRequest {
			_data = value != null ? value : new URLVariables();
			return this;
		}

		public function get digest(): String {return _digest;}
		public function setDigest(value: String): GalleryRestRequest {
			_digest = value;
			return this;
		}
		
		public function get method(): String {return _method;}
		public function setMethod(value: String): GalleryRestRequest {
			_method = value;
			return this;
		}
		
		public function get url(): String {return _method;}
		public function setUrl(value: String): GalleryRestRequest {
			_uri = value.substr(baseURL.length);
			return this;
		}
		
		public function get uri(): String {return _uri;}
		public function setUri(value: String): GalleryRestRequest {
			_uri = value;
			return this;
		}

		public function sendRequest(responseHandler: Function=null): GalleryRestToken {
			var token: GalleryRestToken = new GalleryRestToken();
			token.action = method;
			token.uri = uri;
			
			var loader: URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, function(event:Event): void {
				if (responseHandler != null) {
					responseHandler(token, loader.data);
				} else {
					token.data = loader.data;
					token.resource = null;
				}
			});
			loader.addEventListener(ProgressEvent.PROGRESS, function(event: ProgressEvent): void {
				token.dispatchEvent(event);			
			});
			loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, function (event:HTTPStatusEvent): void {
				token.statusText = HTTP_STATUS[event.status];
				token.statusCode = event.status;
			});
			loader.addEventListener(IOErrorEvent.IO_ERROR, function(event:IOErrorEvent): void {
				var fault: Fault; 
				if (token.statusCode == 0) {
					// Seem to get this branch when we try to upload files. Not consistently
					var pattern: RegExp = /^Error #(\d+):\s(.*\.)\s(.*)$/;
					var parts: Array = pattern.exec(event.text);
					fault = new Fault(parts[1], parts[2], parts[3]);
				} else {
					if (loader.data != null) {
						var detail: Object = JSON.decode(String(loader.data)) as Object;
						fault = new Fault(token.statusCode, token.statusText, detail.message);
						fault.content = detail.fields != null ? detail.fields : null;
					} else {
						fault = new Fault(token.statusCode, token.statusText, event.text);
					}
				}
				loader.close();
				fault.rootCause = event;
				token.applyFault(fault);
			});
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, function(event:SecurityErrorEvent): void {
				var fault: Fault = new Fault(token.statusCode, token.statusText, loader.data != null ? loader.data : event.text);
				fault.rootCause = event;
				loader.close();
				token.applyFault(fault);
			});
			loader.load(_createRequest());
			
			return token;
		}

		private function _createRequest(): URLRequest {
			var request: URLRequest = new URLRequest(baseURL + uri);
			request.method = URLRequestMethod.POST;
			if (_digest != null) {
				request.digest = _digest;
			}
			
			var isMultipartData: Boolean = false;
			var hasData: Boolean = false;
			for each (var variable:* in _data) {
				hasData = true;
				if (variable is URLFileVariable) {
					isMultipartData = true;
				}
			}
			
			if (!hasData) {
				_data.noop = 1;
			}
			request.requestHeaders = [
				new URLRequestHeader("Accept", "*/*"),
				new URLRequestHeader("Cache-Control", "no-cache"),
				new URLRequestHeader("X_GALLERY_REQUEST_METHOD", _method),
				new URLRequestHeader("X_GALLERY_REQUEST_KEY", _requestAccessKey)
				];
			if (isMultipartData) {
				request.data = _buildMultipartBody();
				_addMultipartHeadersTo(request);
			} else {
				request.data = _data;
			}

			return request;
		}

		/**
		 * Build a ByteArray instance containing the <code>multipart/form-data</code> encoded URLVariables.
		 *
		 * @return ByteArray containing the encoded variables
		 */
		private function _buildMultipartBody(): ByteArray {
			var body:ByteArray = new ByteArray();
			
			// Write each encoded field into the request body
			for (var id:String in _data) {
				body.writeBytes(_encodeMultipartVariable(id, _data[id]));
			}
			
			// Mark the end of the request body
			// Note, we writeUTFBytes and not writeUTF because it can corrupt parsing on the server
			body.writeUTFBytes(MULTIPART_MARK + MULTIPART_BOUNDARY + MULTIPART_MARK + LF);
			return body;
		}
		
		/**
		 * Encode a variable using <code>multipart/form-data</code>.
		 *
		 * @param id    The unique id of the variable
		 * @param value The value of the variable
		 */
		private function _encodeMultipartVariable(id:String, variable:Object): ByteArray {
			return variable is URLFileVariable ?
				_encodeMultipartFile(id, URLFileVariable(variable)) :
				_encodeMultipartString(id, variable.toString());
		}
		
		/**
		 * Encode a file using <code>multipart/form-data</code>.
		 *
		 * @param id   The unique id of the file variable
		 * @param file The URLFileVariable containing the file name and file data
		 *
		 * @return The encoded variable
		 */
		private function _encodeMultipartFile(id:String, file:URLFileVariable): ByteArray {
			var field:ByteArray = new ByteArray();
			// Note, we writeUTFBytes and not writeUTF because it can corrupt parsing on the server
			field.writeUTFBytes(MULTIPART_MARK + MULTIPART_BOUNDARY + LF +
				"Content-Disposition: form-data; name=\"" + id +  "\"; " +
				"filename=\"" + file.name + "\"" + LF +
//				"Content-Type: image/png" + LF + LF);
				"Content-Type: application/octet-stream" + LF + LF);
			
			field.writeBytes(file.data);
			field.writeUTFBytes(LF);
			field.position = 0;
			return field;
		}
		
		/**
		 * Encode a string using <code>multipart/form-data</code>.
		 *
		 * @param id   The unique id of the string
		 * @param text The value of the string
		 *
		 * @return The encoded variable
		 */
		private function _encodeMultipartString(id:String, text:String): ByteArray {
			var field:ByteArray = new ByteArray();
			// Note, we writeUTFBytes and not writeUTF because it can corrupt parsing on the server
			field.writeUTFBytes(MULTIPART_MARK + MULTIPART_BOUNDARY + LF +
				"Content-Disposition: form-data; name=\"" + id + "\"" + LF + LF +
				text + LF);
			return field;
		}
		
		/**
		 * Add the relevant <code>multipart/form-data</code> headers to a URLRequest.
		 */
		private function _addMultipartHeadersTo(request:URLRequest): void {
			request.requestHeaders.push(
				new URLRequestHeader("Content-Type", "multipart/form-data; boundary=" + MULTIPART_BOUNDARY)
			);
			
			// Note, the headers: Content-Length and Connection:Keep-Alive are auto set by URLRequest
		}
	}
}