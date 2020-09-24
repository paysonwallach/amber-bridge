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
    public enum MessageType {
        DESERIALIZE,
        SERIALIZE;

        public string to_string () {
            switch (this) {
            case DESERIALIZE:
                return "deserialize";
            case SERIALIZE:
                return "serialize";
            default:
                assert_not_reached ();
            }
        }

    }

    [DBus (name = "com.paysonwallach.amber.connector")]
    public class HostConnectorBusServer : Object {
        private uint owner_id = 0U;

        private static Once<HostConnectorBusServer> instance;

        public static unowned HostConnectorBusServer get_default () {
            return instance.once (() => {
                return new HostConnectorBusServer ();
            });
        }

        construct {
            owner_id = Bus.own_name (BusType.SESSION,
                                     "com.paysonwallach.amber.connector",
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
            post_message (MessageType.DESERIALIZE.to_string (), url);
        }

        private void post_message (string message_type, string body) throws DBusError, IOError {
            var builder = new Json.Builder ();

            builder.begin_object ();
            builder.set_member_name ("type");
            builder.add_string_value (message_type);

            builder.set_member_name ("body");
            builder.add_string_value (body);
            builder.end_object ();

            var generator = new Json.Generator ();
            var root = builder.get_root ();

            generator.set_root (root);

            var message = generator.to_data (null);
            var message_length_buffer = new uint8[4];

            message_length_buffer[3] = (uint8) ((message.length >> 24) & 0xFF);
            message_length_buffer[2] = (uint8) ((message.length >> 16) & 0xFF);
            message_length_buffer[1] = (uint8) ((message.length >> 8) & 0xFF);
            message_length_buffer[0] = (uint8) (message.length & 0xFF);

            stdout.write (message_length_buffer);
            stdout.write (message.data);
            stdout.flush ();
        }

    }

    public class HostConnector : Application {}

    public static int main (string[] args) {
        var loop = new MainLoop (null, false);
        var host_connector_bus_server = HostConnectorBusServer.get_default ();
        var sigterm_source = new Unix.SignalSource (Posix.Signal.TERM);

        sigterm_source.set_callback (() => {
            loop.quit ();

            return Source.REMOVE;
        });
        sigterm_source.attach ();

        var base_input_stream = new UnixInputStream (0, false);
        var input_stream = new DataInputStream (base_input_stream);

        input_stream.set_byte_order (DataStreamByteOrder.LITTLE_ENDIAN);
    }

}
