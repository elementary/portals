/*
 * SPDX-FileCopyrightText: 2025 elementary, Inc. (https://elementary.io)
 * SPDX-License-Identifier: LGPL-2.1-or-later
 */

[DBus (name = "org.freedesktop.Notifications")]
public interface Notification.FdoInterface : Object {
    public enum CloseReason {
        EXPIRED = 1,
        DISMISSED = 2,
        CLOSE_NOTIFICATION_CALL = 3,
        UNDEFINED = 4
    }

    public signal void notification_closed (uint32 id, uint32 reason);
    public signal void action_invoked (uint32 id, string action_key);

    public abstract uint32 notify (string app_name, uint32 replaces_id, string app_icon, string summary, string body, string[] actions, HashTable<string, Variant> hints, int32 expire_timeout) throws Error;
    public abstract void close_notification (uint32 id) throws Error;
}
