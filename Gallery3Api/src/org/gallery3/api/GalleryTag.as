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
	public dynamic class GalleryTag extends GalleryResource {
		public function GalleryTag() {}

		public function get id(): int {
			return this.entity.id;
		}

		public function get count(): Number {
			return Number(this.entity.count);
		}
		public function set count(value:Number): void {
			this.entity.count = value;
		}

		public function get name(): String {
			return this.entity.name;
		}
		public function set name(value:String): void {
			this.entity.name = value;
		}
	}
}