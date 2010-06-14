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
	
	import mx.collections.ArrayCollection;
	import mx.collections.CursorBookmark;
	import mx.collections.ICollectionView;
	import mx.collections.IViewCursor;
	import mx.controls.Tree;
	import mx.controls.treeClasses.ITreeDataDescriptor;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	
	import org.gallery3.api.GalleryAlbum;
	
	import spark.components.Application;
	
	public class OrganizeDataDescriptor implements ITreeDataDescriptor {
		public function OrganizeDataDescriptor() {}

		public function getChildren(node:Object, model:Object=null):ICollectionView {
			return node.albums;
		}
		
		public function hasChildren(node:Object, model:Object=null):Boolean {
			return node.members.length > 0;
		}
		
		public function isBranch(node:Object, model:Object=null):Boolean {
			return node.type == "album";
		}
		
		public function getData(node:Object, model:Object=null):Object {
			return node;
		}
				
		public function addChildAt(parent:Object, newChild:Object, index:int, model:Object=null):Boolean {
			return false;
		}
		
		public function removeChildAt(parent:Object, child:Object, index:int, model:Object=null):Boolean {
			return false;
		}
	}
}