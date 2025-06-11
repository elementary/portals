/*
 * SPDX-FileCopyrightText: 2024 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 *
 * Authored by: Leonhard Kargl <leo.kargl@proton.me>
 */

public class ScreenCast.Dialog : Granite.Dialog {
    public SourceType source_types { get; construct; }
    public bool allow_multiple { get; construct; }

    public int n_selected { get; private set; default = 0; }

    private List<SelectionRow> window_rows;
    private List<SelectionRow> monitor_rows;
    private SelectionRow? virtual_row;

    private Gtk.ListBox list_box;
    private Gtk.CheckButton? group = null;

    public Dialog (SourceType source_types, bool allow_multiple) {
        Object (source_types: source_types, allow_multiple: allow_multiple);
    }

    construct {
        window_rows = new List<SelectionRow> ();
        monitor_rows = new List<SelectionRow> ();

        list_box = new Gtk.ListBox () {
            vexpand = true
        };
        list_box.add_css_class (Granite.STYLE_CLASS_RICH_LIST);
        list_box.set_header_func (header_func);

        if (MONITOR in source_types) {
            var monitor_tracker = new MonitorTracker ();

            foreach (var monitor in monitor_tracker.monitors) {
                var row = new SelectionRow (
                    MONITOR, monitor.connector, monitor.display_name, new ThemedIcon ("video-display"), allow_multiple ? null : group
                );

                monitor_rows.append (row);
                setup_row (row);
            }
        }

        if (WINDOW in source_types) {
            populate_windows.begin ();
        }

        if (VIRTUAL in source_types) {
            virtual_row = new SelectionRow (VIRTUAL, "unused", _("Entire Display"),
                new ThemedIcon ("preferences-desktop-display"), allow_multiple ? null : group);
            setup_row (virtual_row);
        }

        var scrolled_window = new Gtk.ScrolledWindow () {
            child = list_box,
            hscrollbar_policy = NEVER
        };

        var frame = new Gtk.Frame (null) {
            child = scrolled_window
        };

        get_content_area ().append (frame);

        default_height = 400;
        default_width = 300;

        add_button (_("Cancel"), Gtk.ResponseType.CANCEL);

        var accept_button = add_button (_("Share"), Gtk.ResponseType.ACCEPT);
        accept_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);
        bind_property ("n-selected", accept_button, "sensitive", SYNC_CREATE, (binding, from_val, ref to_val) => {
            to_val.set_boolean (n_selected > 0);
            return true;
        });
    }

    private async void populate_windows () {
        var desktop_integration = yield Gala.DesktopIntegration.get_instance ();

        if (desktop_integration == null) {
            return;
        }

        Gala.DesktopIntegration.Window[] windows;
        try {
            windows = yield desktop_integration.get_windows ();
        } catch (Error e) {
            warning ("Failed to get windows from desktop integration: %s", e.message);
            return;
        }

        foreach (var window in windows) {
            var label = _("Unknown Window");
            string? description = null;

            if ("title" in window.details) {
                label = (string) window.details["title"];
            }

            Icon icon = new ThemedIcon ("application-default-icon");
            if ("app-id" in window.details) {
                var app_info = new DesktopAppInfo ((string) window.details["app-id"]);
                if (app_info != null && app_info.get_icon () != null) {
                    icon = app_info.get_icon ();
                    description = label;
                    label = app_info.get_display_name ();
                }
            }

            var row = new SelectionRow (
                WINDOW, window.uid, label, icon, allow_multiple ? null : group
            );

            if (description != null) {
                row.description = description;
            }

            window_rows.append (row);
            setup_row (row);
        }
    }

    private void setup_row (SelectionRow row) {
        group = row.check_button;

        list_box.append (row);

        row.notify["selected"].connect (() => {
            if (row.selected) {
                n_selected++;
            } else {
                n_selected--;
            }
        });
    }

    private void header_func (Gtk.ListBoxRow row, Gtk.ListBoxRow? prev) {
        if (!(row is SelectionRow) && prev != null && !(prev is SelectionRow)) {
            return;
        }

        var selection_row = (SelectionRow) row;

        if (prev == null || ((SelectionRow) prev).source_type != selection_row.source_type) {
            string label = "";

            switch (selection_row.source_type) {
                case WINDOW:
                    label = _("Windows");
                    break;

                case MONITOR:
                    label = _("Monitors");
                    break;

                case VIRTUAL:
                    label = _("Entire Display");
                    break;
            }

            selection_row.set_header (new Granite.HeaderLabel (label));
        }
    }

    public uint64[] get_selected_windows () {
        uint64[] result = {};
        foreach (var row in window_rows) {
            if (row.selected) {
                result += (uint64) row.id;
            }
        }
        return result;
    }

    public string[] get_selected_monitors () {
        string[] result = {};
        foreach (var row in monitor_rows) {
            if (row.selected) {
                result += (string) row.id;
            }
        }
        return result;
    }

    public bool get_virtual () {
        return virtual_row != null && virtual_row.selected;
    }
}
