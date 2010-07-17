
namespace XmpEdit {

public class MetadataTreeModel : Gtk.ListStore {

    public MetadataTreeModel(PropertyEditor[] property_editors) {
        set_column_types({ typeof(string) });
        foreach (var property_editor in property_editors) {
            Gtk.TreeIter row;
            append(out row);
            set_value(row, 1, property_editor.get_list_markup());
        }
    }

}

}
