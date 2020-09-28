/*
 * Copyright (c) 2020 Payson Wallach
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

[DBus (name = "com.paysonwallach.amber.connector")]
public class Amber.HostConnectorBusServer : Object {
    private uint owner_id = 0U;

    [DBus (visible = false)]
    public signal void message_received (MessageType message_type, string content);

    private static Once<HostConnectorBusServer> instance;

    public static unowned HostConnectorBusServer get_default () {
        return instance.once (() => {
            return new HostConnectorBusServer ();
        });
    }

    construct {
        owner_id = Bus.own_name (
            BusType.SESSION, "com.paysonwallach.amber.connector",
            BusNameOwnerFlags.NONE, (connection) => {
                try {
                    connection.register_object (
                        "/com/paysonwallach/amber/connector", get_default ());
                } catch (IOError err) {
                    error (err.message);
                }
            },
            () => {},
            () => { error ("could not acquire name"); });
    }

    ~HostConnectorBusServer () {
        if (owner_id != 0U)
            Bus.unown_name (owner_id);
    }

    public void open (string[] urls) throws DBusError, IOError {
        message_received (MessageType.DESERIALIZE, url);
    }

}
