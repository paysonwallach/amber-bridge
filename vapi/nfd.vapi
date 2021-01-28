/*
 * Copyright (c) 2021 Payson Wallach
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

[CCode (cprefix = "NFD_", cheader_filename = "nfd.h")]
namespace Nfd {
    [CCode (cname = "nfdresult_t", cprefix = "NFD_", has_type_id = false)]
    public enum Result {
        ERROR,
        OKAY,
        CANCEL
    }

    [CCode (cname = "nfdnfilteritem_t", destroy_function = "")]
    public struct FilterItem {
        string name;
        string spec;
    }

    [CCode (cname = "NFD_Init")]
    public void init ();

    [CCode (cname = "NFD_Quit")]
    public void quit ();

    [CCode (cname = "NFD_SaveDialogN")]
    public Result save_dialog (out string out_path, FilterItem[] filter_list, string? default_path = null, string? default_name = null);

    [CCode (cname = "NFD_GetError")]
    public string get_error ();
}
