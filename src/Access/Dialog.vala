/*
 * SPDX-FileCopyrightText: 2021-2023 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

[DBus (name = "org.freedesktop.impl.portal.Request")]
public class Access.Dialog : Granite.MessageDialog, PantheonWayland.ExtendedBehavior {
    public enum ButtonAction {
        SUGGESTED,
        DESTRUCTIVE
    }

    public ButtonAction action { get; construct; }

    public string parent_window { get; construct; }

    public string app_id { get; construct; }

    public string deny_label {
        set {
            deny_button.label = value;
        }
    }

    public string grant_label {
        set {
            grant_button.label = value;
        }
    }

    public string body {
        set {
            if (value != "") {
                secondary_text += "\n\n" + value;
            }
        }
    }

    private unowned Gtk.Button grant_button;
    private unowned Gtk.Button deny_button;
    private List<Choice> choices;

    public Dialog (ButtonAction action, string app_id, string parent_window, string icon) {
        Object (
            action: action,
            app_id: app_id,
            parent_window: parent_window,
            image_icon: new ThemedIcon (icon),
            buttons: Gtk.ButtonsType.NONE
        );
    }

    construct {
        resizable = false;
        modal = true;

        choices = new List<Choice> ();

        if (app_id != "") {
            badge_icon = new DesktopAppInfo (app_id + ".desktop").get_icon ();
        }

        deny_button = add_button (_("Deny Access"), Gtk.ResponseType.CANCEL) as Gtk.Button;
        grant_button = add_button (_("Grant Access"), Gtk.ResponseType.OK) as Gtk.Button;

        if (action == ButtonAction.SUGGESTED) {
            grant_button.add_css_class (Granite.CssClass.SUGGESTED);
            default_widget = grant_button;
        } else {
            grant_button.add_css_class (Granite.CssClass.DESTRUCTIVE);
            default_widget = deny_button;
        }

        custom_bin.orientation = Gtk.Orientation.VERTICAL;
        custom_bin.spacing = 6;

        if (parent_window == "") {
            child.realize.connect (() => {
                connect_to_shell ();
                make_centered ();
                set_keep_above ();
            });
        }
    }

    public override void show () {
        ((Gtk.Widget) base).realize ();

        unowned var toplevel = (Gdk.Toplevel) get_surface ();

        if (parent_window != "") {
            try {
                ExternalWindow.from_handle (parent_window).set_parent_of (toplevel);
            } catch (Error e) {
                warning ("Failed to associate portal window with parent '%s': %s", parent_window, e.message);
            }
        }

        base.show ();
        toplevel.focus (Gdk.CURRENT_TIME);
    }

    public override void close () {
        response (Gtk.ResponseType.CANCEL);
        base.close ();
    }

    [DBus (visible = false)]
    public void add_choice (Choice choice) {
        choices.append (choice);
        custom_bin.append (choice);
    }

    [DBus (visible = false)]
    public unowned List<Choice> get_choices () {
        return choices;
    }

    [DBus (name = "Close")]
    public void on_close () throws DBusError, IOError {
        response (Gtk.ResponseType.DELETE_EVENT);
    }
}
