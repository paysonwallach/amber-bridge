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

private class Amber.BrowserProxy : Object {
    private HostConnectorInputStream input_stream;
    private DataOutputStream output_stream;
    private bool is_first_call = true;
    private bool in_shutdown = false;
    private uint8[] message_length_buffer;
    private uint8[] message_content_buffer;

    public signal void message_received (string body);

    public BrowserProxy (HostConnectorInputStream input_stream, DataOutputStream output_stream) {
        Object (input_stream, output_stream);
    }

    private int decode_message_length (uint8[] buffer) {
        return;
    }

    private uint8[] encode_message_length (int length) {
        var buffer = new uint8[4];

        buffer[3] = (uint8) ((length >> 24) & 0xFF);
        buffer[2] = (uint8) ((length >> 16) & 0xFF);
        buffer[1] = (uint8) ((length >> 8) & 0xFF);
        buffer[0] = (uint8) (length & 0xFF);

        return buffer;
    }

    private void message_content_read_cb (Object? object, AsyncResult result) {
        var stream = object as HostConnectorInputStream;

        try {
            stream.read_bytes_async.end (result);

            message_received (message_content_buffer);

            if (input_stream != null && in_shutdown == false) {
                input_stream.read_async.begin (message_length_buffer,
                                               Priority.DEFAULT, null, message_length_read_cb);
            }
        } catch (IOError err) {}
    }

    private void message_length_read_cb (Object? object, AsyncResult result) {
        var stream = object as HostConnectorInputStream;

        try {
            stream.read_async.end (result);
            var message_length = message_length_buffer;

            message_content_buffer = new uint8[message_length];

            stream.read_bytes_async.begin (message_content_buffer,
                                           Priority.DEFAULT, null, message_content_read_cb);
        } catch (IOError err) {}
    }

    public async void start_listening () {
        if (is_first_call) {
            is_first_call = false;
            message_length_buffer = new uint8[4];

            yield this.read_async.begin (message_length_buffer,
                                         Priority.DEFAULT, null, message_length_read_cb);

        }
    }

    public async void send_message (string content) {
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
        var message_length_buffer = encode_message_length (message.length);

        output_stream.write (message_length_buffer);
        output_stream.write (message.data);
    }

}
