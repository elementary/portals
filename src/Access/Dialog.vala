/*
 * SPDX-FileCopyrightText: 2021 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

[DBus (name = "org.freedesktop.impl.portal.Request")]
public class Access.Dialog : Granite.MessageDialog {
    public enum ButtonAction {
        SUGGESTED,
        DESTRUCTIVE
    }

    public uint register_id { get; set; default = 0; }

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

    private Gtk.Button grant_button;
    private Gtk.Button deny_button;
    private List<Choice> choices;
    private Gtk.Box box;

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
        unowned var surface = get_surface ();
        if (surface is Gdk.X11.Surface) {
            unowned var x11_surface = (Gdk.X11.Surface) surface;
            x11_surface.set_skip_taskbar_hint (true);
        }

        resizable = false;
        modal = true;

        choices = new List<Choice> ();

        if (app_id != "") {
            badge_icon = new DesktopAppInfo (app_id + ".desktop").get_icon ();
        }

        deny_button = add_button (_("Deny Access"), Gtk.ResponseType.CANCEL) as Gtk.Button;
        grant_button = add_button (_("Grant Access"), Gtk.ResponseType.OK) as Gtk.Button;

        if (action == ButtonAction.SUGGESTED) {
            grant_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);
            set_default_widget (grant_button);
        } else {
            grant_button.add_css_class (Granite.STYLE_CLASS_DESTRUCTIVE_ACTION);
            set_default_widget (deny_button);
        }

        box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
        custom_bin.append (box);
        box.show ();

        if (parent_window == "") {
            warning ("Unknown parent window: The portal dialog might appear at the wrong spot because we can't assign a transient parent.");

        } else {
            ((Gtk.Widget) this).realize.connect (() => {
                try {
                    ExternalWindow.from_handle (parent_window).set_parent_of (get_surface ());
                } catch (Error e) {
                    warning ("Failed to associate portal window with parent %s: %s", parent_window, e.message);
                }
            });
        }

        response.connect_after (destroy);
    }

    [DBus (visible = false)]
    public void add_choice (Choice choice) {
        choices.append (choice);
        box.append (choice);
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
