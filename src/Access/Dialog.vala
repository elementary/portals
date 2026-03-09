/*
 * SPDX-FileCopyrightText: 2021-2023 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

[DBus (name = "org.freedesktop.impl.portal.Request")]
public class Access.Dialog : PortalDialog {
    public string body {
        set {
            if (value != "") {
                secondary_text += "\n\n" + value;
            }
        }
    }

    private List<Choice> choices;
    private Granite.Box? custom_bin = null;

    construct {
        choices = new List<Choice> ();
    }

    [DBus (visible = false)]
    public void add_choice (Choice choice) {
        if (custom_bin == null) {
            custom_bin = new Granite.Box (VERTICAL, HALF);
            content = custom_bin;
        }

        choices.append (choice);
        custom_bin.append (choice);
    }

    [DBus (visible = false)]
    public unowned List<Choice> get_choices () {
        return choices;
    }

    [DBus (name = "Close")]
    public void on_close () throws DBusError, IOError {
        response (DELETE_EVENT);
    }
}
