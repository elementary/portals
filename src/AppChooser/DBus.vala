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

[DBus (name = "org.freedesktop.impl.portal.AppChooser")]
public class AppChooser.DBus : Object {
    public void choose_application (
        ObjectPath handle,
        string app_id,
        string parent_window,
        string[] choices,
        HashTable<string, Variant> options,
        out uint32 response,
        out HashTable<string, Variant> results
    ) throws Error {
        unowned Variant? variant = null;

        AppChooser.Dialog dialog;

        if ((variant = hints.lookup ("content-type")) != null && variant.is_of_type (VariantType.STRING)) {
            dialog = new AppChooser.Dialog.for_content_type (variant.get_string ());
        } else if ((variant = hints.lookup ("uri")) != null && variant.is_of_type (VariantType.STRING)) {
            dialog = new AppChooser.Dialog.for_uri (variant.get_string ());
        }

        if ((variant = hints.lookup ("modal")) != null && variant.is_of_type (VariantType.BOOLEAN)) {
            dialog.modal = variant.get_boolean ();
        }
    }

    public void update_choices (ObjectPath handle, string[] choices) {

    }
}
