
/*
 * Copyright 2019 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

public class PortalsDemo.Views.AppChooser: Gtk.Grid {

    construct {
        var header_label = new Granite.HeaderLabel ("AppChooser Portal");
        add (header_label);
    }
}