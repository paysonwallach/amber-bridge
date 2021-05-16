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
    public enum Method {
        EVENT,
        CREATE,
        OPEN,
        UPDATE;

        public string to_string () {
            switch (this) {
                case EVENT:
                    return "event";
                case CREATE:
                    return "create";
                case OPEN:
                    return "open";
                case UPDATE:
                    return "update";
                default:
                    assert_not_reached();
            }
        }
    }

    public class Message : Serializable {
        [CCode (cname = "apiVersion")]
        public string api_version { get; construct set; }

        public string id { get; construct set; }

        public string method { get; construct set; }

        public string? context { get; construct set; }

        public Message (Method method, string? context = null) {
            this.api_version = Config.API_VERSION;
            this.id = Uuid.string_random ();
            this.method = method.to_string ();
            this.context = context;
        }
    }

    public class Event : Message {
        public string name { get; construct set; }

        public Event (string name) {
            base (Method.EVENT);

            this.name = name;
        }
    }

    public class Error : Serializable {
        public int code { get; construct set; }

        public string description { get; construct set; }

        public Error (int code, string description) {
            this.code = code;
            this.description = description;
        }
    }

    public class CreateSessionRequest : Message {
        [CCode (cname = "sessionName")]
        public string session_name { get; construct set; }

        public string data { get; construct set; }

        public CreateSessionRequest (string session_name, string data) {
            base (Method.CREATE);

            this.session_name = session_name;
            this.data = data;
        }
    }

    public class CreateSessionResult : Message {
        public class CreateSessionResultData : Serializable {
            public string name { get; construct set; }

            public string uri { get; construct set; }

            public CreateSessionResultData (string name, string uri) {
                this.name = name;
                this.uri = uri;
            }
        }

        public CreateSessionResultData? data { get; construct set; }

        public Error? error { get; construct set; }

        private CreateSessionResult () {
            base (Method.CREATE);
        }

        public CreateSessionResult.with_success (string context, string? name = null, string? uri = null) {
            base (Method.CREATE, context);

            if (name != null && uri != null)
                this.data = new CreateSessionResultData (name, uri);
        }

        public CreateSessionResult.with_error (string context, int error_code, string error_description) {
            base (Method.CREATE, context);

            this.error = new Error (error_code, error_description);
        }
    }

    public class OpenSessionRequest : Message {
        public class OpenSessionRequestData : Serializable {
            [CCode (cname = "autoSave")]
            public bool auto_save { get; construct set; }

            [CCode (cname = "sessionData")]
            public string session_data { get; construct set; }

            public OpenSessionRequestData (string session_data, bool auto_save) {
                this.auto_save = auto_save;
                this.session_data = session_data;
            }
        }

        public string name { get; construct set; }

        public string uri { get; construct set; }

        public OpenSessionRequestData data { get; construct set; }

        public OpenSessionRequest (string uri, string data, bool auto_save) {
            base (Method.OPEN);

            this.name = Utils.get_session_name (uri);
            this.uri = uri;
            this.data = new OpenSessionRequestData (data, auto_save);
        }
    }

    public class OpenSessionResult : Message {
        public class OpenSessionResultData : Serializable {
            public bool success { get; construct set; }

            public OpenSessionResultData (bool success) {
                this.success = success;
            }
        }

        public OpenSessionResultData? data { get; construct set; }

        public Error? error { get; construct set; }

        private OpenSessionResult () {
            base (Method.OPEN);
        }

        public OpenSessionResult.with_success (string context, bool success) {
            base (Method.OPEN, context);

            this.data = new OpenSessionResultData (success);
        }

        public OpenSessionResult.with_error (string context, int error_code, string error_description) {
            base (Method.OPEN, context);

            this.error = new Error (error_code, error_description);
        }
    }

    public class UpdateSessionRequest : Message {
        public string uri { get; construct set; }

        public string data { get; construct set; }

        public UpdateSessionRequest (string uri, string data) {
            base (Method.UPDATE);

            this.uri = uri;
            this.data = data;
        }
    }

}
