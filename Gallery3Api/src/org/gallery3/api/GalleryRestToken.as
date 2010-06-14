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
	import flash.events.EventDispatcher;
	
	import mx.events.PropertyChangeEvent;
	import mx.rpc.AsyncToken;
	import mx.rpc.IResponder;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;

	/**
	 *  Dispatched when a property of the channel set changes.
	 * 
	 *  @eventType mx.events.PropertyChangeEvent.PROPERTY_CHANGE
	 */
	[Event(name="propertyChange", type="mx.events.PropertyChangeEvent")]
	
	public dynamic class GalleryRestToken extends EventDispatcher {
		public function GalleryRestToken() {
			super();
		}

		private var _resource: Object = null;
		private var _responders: Array;
		
		/**
		 * The result that was returned by the associated RPC call.
		 * Once the result property on the token has been assigned
		 * it will be strictly equal to the result property on the associated
		 * ResultEvent.
		 */
		[Bindable(event="propertyChange")]
		public function get resource(): Object {
			return _resource;
		}
		public function set resource(value: Object): void {
			if (_resource !== value) {
				var event:PropertyChangeEvent = PropertyChangeEvent.createUpdateEvent(this, "resource", _resource, value);
				_resource = value;
				dispatchEvent(event);
			}
				
			if (_responders != null) {
				for (var i:uint = 0; i < _responders.length; i++) {
					var responder:IResponder = _responders[i];
					if (responder != null) {
						responder.result(_resource);
					}
				}
			}
		}

		//--------------------------------------------------------------------------
		//
		// Methods
		// 
		//--------------------------------------------------------------------------
		
		/**
		 *  Adds a responder to an Array of responders. 
		 *  The object assigned to the responder parameter must implement
		 *  <code>mx.rpc.IResponder</code>.
		 *
		 *  @param responder A handler which will be called when the asynchronous request completes.
		 * 
		 *  @see mx.rpc.IResponder
		 */
		public function addResponder(responder:IResponder): void {
			if (_responders == null) {
				_responders = [];
			}
			
			_responders.push(responder);
		}
		
		/**
		 * Determines if this token has at least one <code>mx.rpc.IResponder</code> registered.
		 * @return true if at least one responder has been added to this token. 
		 */
		public function hasResponder():Boolean {
			return (_responders != null && _responders.length > 0);
		}
		
		/**
		 * @private
		 */
		internal function applyFault(fault: Object): void {
			if (_responders != null) {
				for (var i:uint = 0; i < _responders.length; i++) {
					var responder:IResponder = _responders[i];
					if (responder != null) {
						responder.fault(fault);
					}
				}
			}
		}
	}
}