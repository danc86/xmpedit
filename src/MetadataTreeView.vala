
namespace Xmpedit {

public class MetadataTreeModel : Gtk.ListStore {

    public MetadataTreeModel() {
        set_column_types({ typeof(string), typeof(PropertyEditor) });
    }
    
    public void populate(ImageMetadata metadata) {
        clear(); // XXX probably inefficient
        foreach (var property_editor in metadata.properties) {
            Gtk.TreeIter row;
            append(out row);
            set_value(row, 0, property_editor.list_markup());
            set_value(row, 1, property_editor);
        }
    }

}

public class MetadataTreeView : Gtk.TreeView {

    private MetadataTreeModel custom_model = new MetadataTreeModel();

    public MetadataTreeView.connected_to(ImageMetadata metadata) {
        model = custom_model;
        custom_model.populate(metadata);
        metadata.updated.connect((t) => { custom_model.populate(t); });
    }
    
    construct {
        Gtk.TreeViewColumn column = new Gtk.TreeViewColumn();
        column.title = "Image properties";
        column.sizing = Gtk.TreeViewColumnSizing.FIXED;
        column.fixed_width = 300;
        Gtk.CellRendererText cell_renderer = new Gtk.CellRendererText();
        column.pack_start(cell_renderer, /* expand */ true);
        column.add_attribute(cell_renderer, "markup", 0);
        append_column(column);
        get_selection().set_mode(Gtk.SelectionMode.BROWSE);
    }

}

}
