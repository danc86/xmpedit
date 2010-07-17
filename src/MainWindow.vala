
namespace XmpEdit {

public class MainWindow : Gtk.Window {

    private GExiv2.Metadata image_metadata;
    private PropertyEditor[] property_editors;
    private Gtk.Table table;
    private Gtk.Image image_preview;
    private Gtk.ScrolledWindow tree_view_scrolled;
    private MetadataTreeModel model;
    private MetadataTreeView tree_view;
    private Gtk.ScrolledWindow detail_scrolled;
    
    public MainWindow(string path) throws GLib.Error {
        Object(type: Gtk.WindowType.TOPLEVEL);
        image_metadata = new GExiv2.Metadata();
        image_metadata.open_path(path);
        //for (Exiv2::XmpData::iterator i = data.begin(); i != data.end(); ++ i) {
        //    property_editors.push_back(PropertyEditor::create(*i));
        //}
        table = new Gtk.Table(/* rows */ 2, /* cols */ 2, /* homogeneous */ false);
        image_preview = new Gtk.Image.from_pixbuf(new Gdk.Pixbuf.from_file_at_scale(path, 320, 320, /* preserve aspect */ true));
        tree_view_scrolled = new Gtk.ScrolledWindow(null, null);
        model = new MetadataTreeModel({ });
        tree_view = new MetadataTreeView(model);
        
        title = File.new_for_path(path).get_basename();
        default_width = 640;
        default_height = 480;
        allow_shrink = true;
        
        table.attach(image_preview,
                1, 2, 0, 1,
                Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND, Gtk.AttachOptions.FILL,
                10, 10);
                
        tree_view_scrolled.add(tree_view);
        tree_view_scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        table.attach(tree_view_scrolled,
                0, 1, 0, 2,
                Gtk.AttachOptions.FILL, Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                0, 0);
        
        add(table);
        show_all();
    }

}

}
