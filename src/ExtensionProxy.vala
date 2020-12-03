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

private class Amber.ExtensionProxy : Object {
    private Cancellable cancellable;
    private DataInputStream input_stream;
    private DataOutputStream output_stream;
    private uint8[] message_length_buffer;
    private uint8[] message_content_buffer;
    private size_t message_length;

    private static Once<ExtensionProxy> instance;

    public static unowned ExtensionProxy get_default () {
        return instance.once (() => {
            return new ExtensionProxy ();
        });
    }

    public signal void message_received (string body);

    private ExtensionProxy () {
        reset ();
    }

    public void reset () {
        cancellable.cancel ();

        var base_input_stream = new UnixInputStream (Posix.STDIN_FILENO, false);
        var base_output_stream = new UnixOutputStream (Posix.STDOUT_FILENO, false);
        input_stream = new DataInputStream (base_input_stream);
        output_stream = new DataOutputStream (base_output_stream);
        cancellable = new Cancellable ();
    }

    private size_t decode_message_length (uint8[] message_length_buffer) {
        return (
            (message_length_buffer[3] << 24)
            + (message_length_buffer[2] << 16)
            + (message_length_buffer[1] << 8)
            + (message_length_buffer[0]));
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
        try {
            input_stream.read_async.end (result);

            info (@"received message: $((string) message_content_buffer)");
            message_received ((string) message_content_buffer);

            if (input_stream != null) {
                message_length_buffer = new uint8[4];
                input_stream.read_async.begin (message_length_buffer,
                                               Priority.DEFAULT, cancellable, message_length_read_cb);
            }
        } catch (IOError err) {
            warning (err.message);
        }
    }

    private void message_length_read_cb (Object? object, AsyncResult result) {
        try {
            input_stream.read_async.end (result);

            message_length = decode_message_length (message_length_buffer);

            if (message_length == 0) {
                message_length_buffer = new uint8[4];
                input_stream.read_async.begin (message_length_buffer,
                                               Priority.DEFAULT, cancellable, message_length_read_cb);
            } else {
                message_content_buffer = new uint8[message_length];

                info (@"reading message with length $message_length");
                input_stream.read_async.begin (message_content_buffer,
                                               Priority.DEFAULT, cancellable, message_content_read_cb);
            }
        } catch (IOError err) {
            warning (err.message);
        }
    }

    public async void start_listening () {
        message_length_buffer = new uint8[4];

        input_stream.read_async.begin (message_length_buffer,
                                       Priority.DEFAULT, cancellable, message_length_read_cb);

    }

    public async void send_message (string message) {
        try {
            output_stream.write (encode_message_length (message.length));
            output_stream.write (message.data);
        } catch (IOError err) {
            warning (err.message);
        }
    }

}
