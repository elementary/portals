public class ScreenCast.Dialog : Granite.Dialog {
    public SourceType source_types { get; construct; }
    public bool allow_multiple { get; construct; }

    public Dialog (SourceType source_types, bool allow_multiple) {
        Object (source_types: source_types, allow_multiple: allow_multiple);
    }

    private List<SelectionRow> window_rows;
    private List<SelectionRow> monitor_rows;

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
            }
        }

        get_content_area ().append (list_box);

        add_button (_("Cancel"), Gtk.ResponseType.CANCEL);
        add_button (_("Share"), Gtk.ResponseType.ACCEPT).add_css_class (Granite.STYLE_CLASS_SUGGESTED_ACTION);
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