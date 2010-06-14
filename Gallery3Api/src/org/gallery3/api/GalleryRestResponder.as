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
	import mx.rpc.AsyncResponder;
	import mx.rpc.Fault;
	import mx.rpc.IResponder;
	
	/**
	 * This class provides an Gallery RESTFul specific implementation of <code>mx.rpc.IResponder</code>.
	 * 
	 * It allows the creator to associate data (a token) and methods that should be 
	 * called when a request is completed.
	 *
	 * The result method specified must have the following signature:
	 *  <code><pre>
	 *     public function myResultFunction(resource: GalleryResource): void;
	 *  </pre></code>
	 *
	 * The fault method specified must have the following signature:
	 *  <code><pre>
	 *     public function myFaultFunction(info:Object): void;
	 *  </pre></code>
	 * 
	 * Any other signature will result in a runtime error.
	 */	
	public dynamic class GalleryRestResponder implements IResponder {
		private var _resultHandler: Function;
		private var _faultHandler: Function;
		
		/**
		 *  Constructs an instance of the responder with the specified data and 
		 *  handlers.
		 *  
		 *  @param result Function that should be called when the request has
		 *          completed successfully.
		 *          Must have the following signature:
		 *          <pre>public function (resource: Object):void;</pre>
		 *  @param fault Function that should be called when the request has
		 *          completed with errors.
		 *          Must have the following signature:
		 *          <pre>public function (info:Object):void;</pre>
		 */
		public function GalleryRestResponder(result:Function, fault:Function) {
			super();
			_resultHandler = result;
			_faultHandler = fault;
		}
		
		public function result(resource: Object): void {
			_resultHandler(resource);
		}
		
		public function fault(fault: Object): void {
			_faultHandler(fault);
		}
	}
}