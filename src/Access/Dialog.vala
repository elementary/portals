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
        // TODO: Gtk4 Migration: wm_role seems to be completely removed
        // set_role ("AccessDialog"); // used in Gala.CloseDialog

        // TODO: Gtk4 Migration: https://valadoc.org/gtk4/Gdk.ToplevelState.html
        // set_keep_above (true);

        if (app_id != "") {
            badge_icon = new DesktopAppInfo (app_id + ".desktop").get_icon ();
        }

        deny_button = add_button (_("Deny Access"), Gtk.ResponseType.CANCEL) as Gtk.Button;
        grant_button = add_button (_("Grant Access"), Gtk.ResponseType.OK) as Gtk.Button;
        // unowned var grant_context = grant_button.get_style_context ();

        if (action == ButtonAction.SUGGESTED) {
            // TODO: Gtk4 Migration: Gtk.STYLE_CLASS_SUGGESTED_ACTION is gone
            grant_button.add_css_class ("suggested-action");
            set_default_widget (grant_button);
        } else {
            // TODO: Gtk4 Migration: Gtk.GTK_STYLE_CLASS_DESTRUCTIVE_ACTION is gone
            grant_button.add_css_class ("destructive-action");
            set_default_widget (deny_button);
        }

        box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
        custom_bin.append (box);
        box.show ();

        if (parent_window != "") {
            ((Gtk.Widget) this).realize.connect (() => {
                try {
                    var parent = ExternalWindow.from_handle (parent_window);
                    parent.set_parent_of (this);
                } catch (Error e) {
                    warning ("Failed to associate portal window with parent %s: %s", parent_window, e.message);
                }
            });
        }

        show.connect (() => {
            // TODO: Gtk4 Migration
            //  var window = get_window ();
            //  if (window == null) {
            //      return;
            //  }

            //  window.focus (Gdk.CURRENT_TIME);
        });

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
