public class ScreenCast.Dialog : Granite.Dialog {
    public SourceType source_types { get; construct; }
    public bool allow_multiple { get; construct; }

    private List<SelectionRow> window_rows;
    private List<SelectionRow> monitor_rows;

    private Gtk.Widget accept_button;

    private int n_selected = 0;

    public Dialog (SourceType source_types, bool allow_multiple) {
        Object (source_types: source_types, allow_multiple: allow_multiple);
    }

    construct {
        window_rows = new List<SelectionRow> ();
        monitor_rows = new List<SelectionRow> ();

        var list_box = new Gtk.ListBox () {
            selection_mode = MULTIPLE,
            vexpand = true
        };
        list_box.add_css_class ("boxed-list");
        list_box.add_css_class (Granite.STYLE_CLASS_RICH_LIST);
        list_box.set_header_func (header_func);

        Gtk.CheckButton? group = null;

        if (WINDOW in source_types) {
            //TODO: populate windows
        }

        if (MONITOR in source_types) {
            var monitor_tracker = new MonitorTracker ();

            foreach (var monitor in monitor_tracker.monitors) {
                var row = new SelectionRow (MONITOR, monitor.connector,
                    monitor.display_name, null, allow_multiple ? null : group);

                monitor_rows.append (row);

                group = row.check_button;

                list_box.append (row);

                row.notify["selected"].connect (() => {
                    if (row.selected) {
                        n_selected++;
                    } else {
                        n_selected--;
                    }

                    update_sensitivity ();
                });
            }
        }

        get_content_area ().append (list_box);

        add_button (_("Cancel"), Gtk.ResponseType.CANCEL);
        accept_button = add_button (_("Share"), Gtk.ResponseType.ACCEPT);
        accept_button.add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);
        accept_button.sensitive = false;
    }

    private void update_sensitivity () {
        accept_button.sensitive = n_selected > 0;
    }

    private void header_func (Gtk.ListBoxRow row, Gtk.ListBoxRow? prev) {
        if (!(row is SelectionRow) && prev != null && !(prev is SelectionRow)) {
            return;
        }

        var selection_row = (SelectionRow) row;

        if (prev == null || ((SelectionRow) prev).source_type != selection_row.source_type) {
            var label = selection_row.source_type == WINDOW ? _("Windows") : _("Monitors");
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
}