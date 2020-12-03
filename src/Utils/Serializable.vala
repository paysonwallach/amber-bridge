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

public abstract class Amber.Serializable : GLib.Object, Json.Serializable {
    public virtual Value get_property (ParamSpec pspec) {
        Value prop_value = GLib.Value (pspec.value_type);

        (this as GLib.Object).get_property (pspec.name, ref prop_value);

        return prop_value;
    }

    public virtual void set_property (ParamSpec pspec, Value value) {
        (this as GLib.Object).set_property (pspec.name, value);
    }

    public virtual (unowned ParamSpec)[] list_properties () {
        return ((ObjectClass) get_type ().class_ref ()).list_properties ();
    }

    public virtual unowned ParamSpec? find_property (string name) {
        return ((ObjectClass) get_type ().class_ref ()).find_property (name);
    }

    public virtual Json.Node serialize_property (
            string property_name, Value @value, ParamSpec pspec) {
        if (@value.type ().is_a (typeof (Json.Object))) {
            var obj = @value as Json.Object;
            if (obj != null) {
                var node = new Json.Node (Json.NodeType.OBJECT);
                node.set_object (obj);
                return node;
            }
        } else if (@value.type ().is_a (typeof (Gee.ArrayList))) {
            unowned Gee.ArrayList<GLib.Object> list_value = @value as Gee.ArrayList<GLib.Object>;
            if (list_value != null) {
                var array = new Json.Array.sized (list_value.size);
                foreach (var item in list_value) {
                    array.add_element (Json.gobject_serialize (item));
                }

                var node = new Json.Node (Json.NodeType.ARRAY);
                node.set_array (array);
                return node;
            }
        } else if (@value.type ().is_a (typeof (GLib.Array))) {
            unowned GLib.Array<GLib.Object> array_value = @value as GLib.Array<GLib.Object>;
            if (array_value != null) {
                var array = new Json.Array.sized (array_value.length);
                for (int i = 0 ; i < array_value.length ; i++) {
                    array.add_element (
                        Json.gobject_serialize (array_value.index (i)));
                }

                var node = new Json.Node (Json.NodeType.ARRAY);
                node.set_array (array);
                return node;
            }
        } else if (@value.type ().is_a (typeof (HashTable))) {
            var obj = new Json.Object ();
            var ht_string = @value as HashTable<string, string>;
            if (ht_string != null) {
                ht_string.foreach ((k, v) => {
                    obj.set_string_member (k, v);
                });

                var node = new Json.Node (Json.NodeType.OBJECT);
                node.set_object (obj);
                return node;
            } else {
                var ht_object = @value as HashTable<string, GLib.Object>;
                if (ht_object != null) {
                    ht_object.foreach ((k, v) => {
                        obj.set_member (k, Json.gobject_serialize (v));
                    });

                    var node = new Json.Node (Json.NodeType.OBJECT);
                    node.set_object (obj);
                    return node;
                }
            }
        }

        return default_serialize_property (
            property_name, @value, pspec);
    }

    public virtual bool deserialize_property (
            string property_name, out Value @value, ParamSpec pspec, Json.Node property_node) {
        return default_deserialize_property (
            property_name, out @value, pspec, property_node);
    }

}
