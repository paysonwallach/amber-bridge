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

    public static int main (string[] args) {
        var loop = new MainLoop (null, false);
        var sigterm_source = new Unix.SignalSource (Posix.Signal.TERM);

        sigterm_source.set_callback (() => {
            loop.quit ();

            return Source.REMOVE;
        });
        sigterm_source.attach ();

        var app = new HostConnector ();

        return Posix.EXIT_SUCCESS;
    }

}
