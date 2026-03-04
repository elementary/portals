/*
 * SPDX-FileCopyrigthText: 2026 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

[DBus (name = "org.freedesktop.impl.portal.Request")]
public class Account.Dialog : PortalDialog {
    // The ID used to register this dialog on the DBusConnection
    public uint register_id { get; set; default = 0; }

    // The ID of the app sending the request
    public string app_id { get; construct; }

    public string user_name;
    public string image_filename;
    public string real_name;

    private Adw.Avatar avatar;

    public string reason {
        set {
            secondary_text = _("It provided the following reason, “%s”").printf (value);
        }
    }

    public Dialog (string app_id) {
        Object (app_id: app_id);
    }

    construct {
        default_height = -1;
        title = _("An application wants to access your personal information");
        secondary_icon = new ThemedIcon ("emblem-portal-account");
        secondary_text = _("It did not provide a reason for this request.");

        if (app_id != "") {
            var app_info = new DesktopAppInfo (app_id + ".desktop");
            if (app_info != null) {
                primary_icon = app_info.get_icon ();
                title = _("“%s” wants to access your name and photo").printf (app_info.get_display_name ());
            }
        }

        user_name = Environment.get_user_name ();
        real_name = Environment.get_real_name ();

        avatar = new Adw.Avatar (32, null, false);
        avatar.add_css_class (Granite.STYLE_CLASS_FLAT);

        var username_label = new Gtk.Label (user_name) {
            halign = START
        };
        username_label.add_css_class (Granite.CssClass.DIM);
        username_label.add_css_class (Granite.CssClass.SMALL);

        var name_box = new Granite.Box (VERTICAL, NONE) {
            valign = CENTER
        };
        name_box.append (new Gtk.Label (real_name));
        name_box.append (username_label);

        var box = new Granite.Box (HORIZONTAL, SINGLE);
        box.append (avatar);
        box.append (name_box);

        var listitem = new Granite.ListItem () {
            child = box,
            margin_top = 12,
            margin_end = 12,
            margin_bottom = 12,
            margin_start = 12
        };
        listitem.add_css_class (Granite.CssClass.CARD);

        content = listitem;

        var usermanager = Act.UserManager.get_default ();
        if (usermanager.is_loaded) {
            on_usermanager_loaded (usermanager);
        } else {
            usermanager.notify["is-loaded"].connect (() => on_usermanager_loaded (usermanager));
        }
    }

    private void on_usermanager_loaded (Act.UserManager usermanager) {
        var user = usermanager.get_user (user_name);
        if (user.is_loaded) {
            on_user_loaded (user);
        } else {
            user.notify["is-loaded"].connect (() => on_user_loaded (user));
        }

    }

    private void on_user_loaded (Act.User user) {
        image_filename = user.get_icon_file ();
        try {
            avatar.custom_image = Gdk.Texture.from_filename (image_filename);
        } catch {
            debug ("unable to set avatar");
        }
    }

    [DBus (name = "Close")]
    public void on_close () throws DBusError, IOError {
        response (DELETE_EVENT);
    }
}
