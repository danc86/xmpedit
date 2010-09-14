/*
 * xmpedit
 * Copyright 2010 Dan Callaghan <djc@djc.id.au>
 * Released under GPLv2
 */

namespace Xmpedit {

public class MainWindow : Gtk.Window {

    private ImageMetadata image_metadata;
    private Gtk.Table table;
    private Gtk.Image image_preview;
    private Gtk.ScrolledWindow tree_view_scrolled;
    private MetadataTreeView tree_view;
    private PropertyDetailView detail_view;
    
    public MainWindow(string path) throws GLib.Error {
        Object(type: Gtk.WindowType.TOPLEVEL);
        image_metadata = new ImageMetadata(path);
        image_metadata.load();
        table = new Gtk.Table(/* rows */ 2, /* cols */ 2, /* homogeneous */ false);
        var file = File.new_for_path(path);
        
        title = file.get_basename();
        default_width = 640;
        default_height = 480;
        allow_shrink = true;
        
        image_preview = new Gtk.Image.from_pixbuf(new Gdk.Pixbuf.from_file_at_scale(path, 320, 320, /* preserve aspect */ true));
        ((Atk.Object) image_preview.get_accessible())
                .set_name("Image preview");
        ((Atk.Object) image_preview.get_accessible())
                .set_role(Atk.Role.IMAGE);
        ((Atk.Image) image_preview.get_accessible())
                .set_image_description(@"Preview of $(file.get_basename())");
        table.attach(image_preview,
                1, 2, 0, 1,
                Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND, 0,
                10, 10);
        
        tree_view = new MetadataTreeView.connected_to(image_metadata);
        ((Atk.Object) tree_view.get_accessible())
                .set_name("Image properties");
        tree_view_scrolled = new Gtk.ScrolledWindow(null, null);
        tree_view_scrolled.add(tree_view);
        tree_view_scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        table.attach(tree_view_scrolled,
                0, 1, 0, 2,
                Gtk.AttachOptions.FILL, Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                0, 0);
        
        detail_view = new PropertyDetailView.connected_to(image_metadata, tree_view);
        table.attach(detail_view,
                1, 2, 1, 2,
                Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                0, 0);
        
        add(table);
        show_all();
        
        destroy.connect(() => {
            image_metadata.save();
        });
    }

}

}
