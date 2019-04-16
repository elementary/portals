/*-
 * Copyright (c) 2019 elementary, Inc. (https://elementary.io)
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

enum ResponseType {
    SUCCESS = 0,
    CANCELLED,
    ENDED
}

public struct FileRequestResponse {
    uint32 response;
    HashTable<string, Variant> results;
}

[DBus (name = "org.freedesktop.impl.portal.FileChooser")]
public class FileChooser : Object {
    public FileChooser () {
        var mapp = new Marlin.Application ();
        mapp.initialize ();

        var app = new Application ("io.elementary.files-portal", ApplicationFlags.NON_UNIQUE);
        Application.set_default (app);
    }

    public void open_file (ObjectPath handle, string app_id, string parent_window, string title,
                        HashTable<string, Variant> options, out uint32 response, out HashTable<string, Variant> results) throws Error {
        results = show_dialog (parent_window, title, options, out response);
    }

    public void save_file (ObjectPath handle, string app_id, string parent_window, string title,
                        HashTable<string, Variant> options, out uint32 response, out HashTable<string, Variant> results) throws Error {
        results = show_dialog (parent_window, title, options, out response);
    }


    private static HashTable<string, Variant> show_dialog (string parent_window, string title,
                                                        HashTable<string, Variant> options,
                                                        out uint32 response) {

        uint32 _resp = ResponseType.SUCCESS;
        var results = new HashTable<string, Variant> (str_hash, null);                                       
        var loop = new MainLoop ();

        var dialog = new FileChooserDialog (title);

        ulong destroy_id = dialog.destroy.connect (() => {
            results.insert ("uris", create_with_selection (new List<GOF.File> ()));
            _resp = ResponseType.CANCELLED;

            loop.quit ();
        });

        dialog.selected.connect ((selection) => {
            results.insert ("uris", create_with_selection (selection));
            loop.quit ();

            dialog.disconnect (destroy_id);
            dialog.destroy ();
        });

        dialog.show_all ();

        loop.run ();

        response = _resp;
        return results;
    }

    private static Variant create_with_selection (List<GOF.File> selection) {
        var builder = new VariantBuilder (VariantType.STRING_ARRAY);
        foreach (var file in selection) {
            builder.add ("s", file.uri);
        }

        return builder.end ();
    }
}
