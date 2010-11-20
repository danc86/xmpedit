/*
 * xmpedit
 * Copyright 2010 Dan Callaghan <djc@djc.id.au>
 * Released under GPLv2
 */

namespace Xmpedit {

private const string STOCK_CLOSE_WITHOUT_SAVING = "xmpedit-close-without-saving";

public class MainWindow : Gtk.Window {

    private File file;
    private ImageMetadata image_metadata;
    private Gtk.Table table;
    private Gtk.Image image_preview;
    private MetadataTreeView tree_view;
    private PropertyDetailView detail_view;
    
    static construct {
        add_stock();
    }
    
    public MainWindow(string path) throws GLib.Error {
        Object(type: Gtk.WindowType.TOPLEVEL);
        file = File.new_for_path(path);
        image_metadata = new ImageMetadata(path);
        image_metadata.load();
        table = new Gtk.Table(/* rows */ 2, /* cols */ 2, /* homogeneous */ false);
        
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
        var tree_view_scrolled = new Gtk.ScrolledWindow(null, null);
        tree_view_scrolled.add(tree_view);
        tree_view_scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        var revert_button = new Gtk.Button.from_stock(Gtk.Stock.REVERT_TO_SAVED);
        revert_button.clicked.connect(() => {
            image_metadata.revert();
            tree_view.set_cursor(new Gtk.TreePath.first(), null, false);
        });
        var save_button = new Gtk.Button.from_stock(Gtk.Stock.SAVE);
        save_button.clicked.connect(() => {
            image_metadata.save();
        });
        revert_button.sensitive = false;
        save_button.sensitive = false;
        image_metadata.notify.connect((p) => {
            if (p.name == "dirty") {
                revert_button.sensitive = image_metadata.dirty;
                save_button.sensitive = image_metadata.dirty;
            }
        });
        var left_button_box = new Gtk.HButtonBox();
        left_button_box.spacing = 5;
        left_button_box.layout_style = Gtk.ButtonBoxStyle.END;
        left_button_box.add(revert_button);
        left_button_box.add(save_button);
        var left_vbox = new Gtk.VBox(/* homogeneous */ false, /* spacing */ 0);
        left_vbox.pack_start(tree_view_scrolled, /* expand */ true, /* fill */ true);
        left_vbox.pack_start(left_button_box, /* expand */ false, /* fill */ false,
                /* padding */ 5);
        table.attach(left_vbox,
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
        
        delete_event.connect(() => {
            if (image_metadata.dirty) {
                var dialog = new Gtk.MessageDialog.with_markup(
                        /* parent */ this, Gtk.DialogFlags.MODAL,
                        Gtk.MessageType.WARNING, Gtk.ButtonsType.NONE,
                        "<big><b>Your changes to image \"%s\" have not been saved.</b></big>\n\n" +
                        "Save changes before closing?",
                        file.get_basename());
                dialog.add_button(STOCK_CLOSE_WITHOUT_SAVING, 1);
                dialog.add_button(Gtk.Stock.CANCEL, 2);
                dialog.add_button(Gtk.Stock.SAVE, 3);
                dialog.set_default_response(3);
                var response = dialog.run();
                dialog.destroy();
                switch (response) {
                    case 3: // save
                        image_metadata.save();
                        return false;
                    case 1: // close
                        return false;
                    case 2: // cancel
                    default:
                        return true;
                }
            }
            return false;
        });
        
        add_stock();
    }
    
    private static Gtk.StockItem[] STOCK = {
        Gtk.StockItem() {
            stock_id = STOCK_CLOSE_WITHOUT_SAVING,
            label = "Close _without saving",
            modifier = 0,
            keyval = 0,
            translation_domain = null
        }
    };
    
    /** Create custom stock entries used in the application. */
    private static void add_stock() {
        Gtk.Stock.add_static(STOCK);
    
        var icon_factory = new Gtk.IconFactory();
        icon_factory.add(STOCK_CLOSE_WITHOUT_SAVING,
                Gtk.IconFactory.lookup_default(Gtk.Stock.CLOSE));
        icon_factory.add_default();
    }
    
}

}
