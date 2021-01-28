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

namespace Amber.Utils {
    public string get_session_name (string uri) {
        var file = File.new_for_uri (uri);
        var basename = file.get_basename ();

        return basename.slice (0, basename.last_index_of (".", 0));
    }

}
