/*
 * SPDX-FileCopyrightText: 2025 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

namespace Screenshot.Utils {
    private bool? is_redacted_font_available = null;

    public bool get_redacted_font_available () {
        if (is_redacted_font_available != null) {
            return is_redacted_font_available;
        }

        (unowned Pango.FontFamily)[] families;
        Pango.CairoFontMap.get_default ().list_families (out families);

        is_redacted_font_available = false;
        foreach (unowned var family in families) {
            if (family.get_name () == "Redacted Script") {
                is_redacted_font_available = true;
                break;
            }
        }

        return is_redacted_font_available;
    }
}
