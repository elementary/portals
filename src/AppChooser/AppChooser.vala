/*
 * Copyright 2019 elementary, Inc. (https://elementary.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

public class AppChooser.Dialog : Gtk.Dialog {
    public string? content_type { get; construct; }
    public string? uri { get; construct; }
    public string[] choices { get; set; }

    public Dialog.for_content_type (string content_type) {
        Object (content_type: content_type);
    }

    public Dialog.for_uri (string uri) {
        Object (uri: uri);
    }

    construct {

    }
}
