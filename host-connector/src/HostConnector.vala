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

public class Amber.HostConnector : Application {
    private SimpleIOStream iostream;

    construct {
        var host_connector_bus_server = HostConnectorBusServer.get_default ();

        var base_input_stream = new UnixInputStream (0, false);
        var base_output_stream = new UnixOutputStream (1, false);
        var input_stream = new DataInputStream (base_input_stream);
        var output_stream = new DataOutputStream (base_output_stream);

        input_stream.set_byte_order (DataStreamByteOrder.LITTLE_ENDIAN);
        output_stream.set_byte_order (DataStreamByteOrder.LITTLE_ENDIAN);

        var host_connection_proxy = new BrowserProxy (
            input_stream, output_stream);

        host_connector_bus_server.message_received.connect ((message) => {
            host_connection_proxy.send_message.begin (message);
        });
        host_connection_proxy.message_received.connect ((type, message) => {
            message_received (type, message);
        });
        host_connection_proxy.start_listening.begin ();
    }

    private void message_received (MessageType message_type, string content) {
        switch (message_type) {
        case MessageType.DESERIALIZE:
            save (content);
            break;
        default:
            assert_not_reached ();
        }
    }

    private int save (string content) {}

}
