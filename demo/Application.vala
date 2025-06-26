/*
 * SPDX-FileCopyrigthText: 2021 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

public class PortalsDemo.Application: Gtk.Application {

    public Application () {
        Object (
            application_id: "io.elementary.portals.demo",
            flags: GLib.ApplicationFlags.FLAGS_NONE
        );
    }

    protected override void activate () {
        var main_window = new MainWindow (this);
        main_window.show_all ();
    }

    public static int main (string[] args) {
        return new Application ().run (args);
    }
}
