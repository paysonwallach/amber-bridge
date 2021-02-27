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
    [DBus (name = "com.paysonwallach.amber.bridge")]
    private class HostConnectorBusServer : Object {
        private uint owner_id = 0U;

        [DBus (visible = false)]
        public signal void message_received (string serialized_request);

        private static Once<HostConnectorBusServer> instance;

        public static unowned HostConnectorBusServer get_default () {
            return instance.once (() => {
                return new HostConnectorBusServer ();
            });
        }

        construct {
            /* *INDENT-OFF* */
            owner_id = Bus.own_name (
                BusType.SESSION, Config.APP_ID,
                BusNameOwnerFlags.ALLOW_REPLACEMENT | BusNameOwnerFlags.REPLACE,
                (connection) => {
                    try {
                        connection.register_object (
                            "/com/paysonwallach/amber/bridge", get_default ());
                    } catch (IOError err) {
                        warning (err.message);
                    }
                },
                () => {},
                () => { error ("could not acquire bus name"); });
            /* *INDENT-ON* */
        }

        ~HostConnectorBusServer () {
            if (owner_id != 0U)
                Bus.unown_name (owner_id);
        }

        public bool open (string[] urls) throws DBusError, IOError {
            foreach (var url in urls) {
                string contents;
                try {
                    var file = File.new_for_uri (url);
                    if (FileUtils.get_contents (file.get_path (), out contents, null)) {
                        debug (@"serializing $contents...");
                        message_received (
                            Json.gobject_to_data (new OpenSessionRequest (url, contents), null));
                    }
                } catch (GLib.Error err) {
                    warning (err.message);
                }
            }

            return true;
        }

    }

    public static LogWriterOutput log_writer_func (LogLevelFlags log_level, LogField[] fields) {
        if (log_level > LogLevelFlags.LEVEL_INFO || Environment.get_variable ("G_MESSAGES_DEBUG") == "all")
            return LogWriterOutput.UNHANDLED;

        GLib.Log.writer_journald (log_level, fields);

        return LogWriterOutput.HANDLED;
    }

    public void route (string message) {
        Message deserialized_message;

        try {
            deserialized_message = Json.gobject_from_data (typeof (Message), message) as Message;
        } catch (GLib.Error err) {
            warning (err.message);
            return;
        }

        debug (@"method: $(deserialized_message.method)");
        switch (deserialized_message.method) {
        case "open":
            ExtensionProxy.get_default ().send_message.begin (message);
            break;
        case "create":
            try {
                create_session (
                    Json.gobject_from_data (
                        typeof (CreateSessionRequest),
                        message) as CreateSessionRequest);
            } catch (GLib.Error err) {
                warning (err.message);
            }
            break;
        default:
            assert_not_reached ();
        }
    }

    public void create_session (CreateSessionRequest request) {
        string path;
        CreateSessionResult session_result;
        Nfd.FilterItem[] filter_list = { { "Browser Sessions", "ambr" } };
        var result = Nfd.save_dialog (
            out path, filter_list,
            Environment.get_home_dir (), @"$(request.session_name)");

        ExtensionProxy.get_default ().send_message.begin (
            Json.gobject_to_data (new Event ("dialog-shown"), null));

        switch (result) {
        case ERROR:
            session_result = new CreateSessionResult.with_error (
                request.id, -1, Nfd.get_error ());
            break;
        case OKAY:
            var file = File.new_for_path (path);
            var uri = file.get_uri ();
            var success = false;

            try {
                success = file.replace_contents (
                    request.data.data, null,
                    false, GLib.FileCreateFlags.NONE, null, null);
                session_result = new CreateSessionResult.with_success (
                    request.id,
                    Utils.get_session_name (uri),
                    uri);
            } catch (GLib.Error error) {
                session_result = new CreateSessionResult.with_error (
                    request.id, error.code, error.message);
            }

            break;
        case CANCEL:
            session_result = new CreateSessionResult.with_success (request.id);
            break;
        default:
            assert_not_reached ();
        }

        ExtensionProxy.get_default ().send_message.begin (
            Json.gobject_to_data (session_result, null));
    }

    public static int main (string[] args) {
        GLib.Log.set_writer_func (log_writer_func);
        Intl.setlocale ();

        Nfd.init ();

        var loop = new MainLoop ();
        var sigterm_source = new Unix.SignalSource (Posix.Signal.TERM);
        var extension_proxy = ExtensionProxy.get_default ();

        sigterm_source.set_callback (() => {
            loop.quit ();
            Nfd.quit ();

            return Source.REMOVE;
        });
        sigterm_source.attach ();

#if _WIN32
#else
        var ppid = Posix.getppid ();
        Timeout.add_seconds (60, () => {
            if (Posix.kill (ppid, 0) != 0) {
                Posix.kill (Posix.getpid (), Posix.Signal.TERM);

                return Source.REMOVE;
            }

            return Source.CONTINUE;
        });
#endif

        HostConnectorBusServer.get_default ().message_received.connect (route);
        extension_proxy.message_received.connect (route);
        extension_proxy.start_listening.begin ();

        loop.run ();

        return Posix.EXIT_SUCCESS;
    }

}
