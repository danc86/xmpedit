
namespace Xmpedit {

public class MetadataTreeView : Gtk.TreeView {

    public MetadataTreeView.connected_to(ImageMetadata metadata) {
        Object(model: metadata);
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
