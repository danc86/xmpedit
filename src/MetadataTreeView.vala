
namespace XmpEdit {

public class MetadataTreeView : Gtk.TreeView {

    public MetadataTreeView(MetadataTreeModel model) {
        set_model(model);
        Gtk.TreeViewColumn column = new Gtk.TreeViewColumn();
        column.title = "Image properties";
        column.sizing = Gtk.TreeViewColumnSizing.FIXED;
        column.fixed_width = 300;
        Gtk.CellRendererText cell_renderer = new Gtk.CellRendererText();
        column.pack_start(cell_renderer, /* expand */ true);
        column.add_attribute(cell_renderer, "markup", 1);
        append_column(column);
    }

}

}
