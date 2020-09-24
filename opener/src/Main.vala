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

namespace Amber {
    [DBus (name = "com.paysonwallach.amber.connector")]
    public interface HostConnectorBusIFace HostConnector : Object {
        public abstract void open (string[] urls) throws DBusError, IOError;

    }

    public class Opener : Application {
        private HostConnectorBusIFace? host_connector = null;

        private Opener () {
            Object (application_id: "com.paysonwallach.amber.opener", flags : ApplicationFlags.HANDLES_OPEN);
        }

        // public override void activate () {
        //     // NOTE: when doing a longer-lasting action here that returns
        //     //  to the mainloop, you should use g_application_hold() and
        //     //  g_application_release() to keep the application alive until
        //     //  the action is completed.
        //     print ("activated\n");
        // }

        public override void open (File[] files, string hint) {
            hold ();

            var watch_id = Bus.watch_name (BusType.SESSION, "com.paysonwallach.ambr",
                                           BusNameWatcherFlags.NONE, (connection, name, name_owner) => {
                try {
                    host_connector = connection.get_proxy_sync (
                        "com.paysonwallach.amber.connector",
                        "/com/paysonwallach/amber/connector"
                        );
                } catch (IOError err) {
                    warning (err.message);
                }
            },
                                           (connection, name) => {
                Bus.unwatch_name (watch_id);
            });

            var i = 0;
            var uris = string[files.length];
            foreach (File file in files) {
                uris[i++] = file.get_uri ();
            }

            try {
                host_connector.open (uris);

                Wnck.Screen? screen = Wnck.Screen.get_default ();

                screen.force_update ();
                screen.get_windows ().@foreach ((window) => {
                    if (window.get_state () == Wnck.WindowState.DEMANDS_ATTENTION)
                        window.activate_transient (Gdk.x11_get_server_time (Gdk.get_default_root_window ()));
                });
            } catch (DBusError err) {
                warning (@"DBusError: $(err.message)");
            } catch (IOError err) {
                warning (@"IOError: $(err.message)");
            }

            release ();
        }

    }

    public static int main (string[] args) {
        var app = new Opener ();
        return app.run (args);
    }

}
