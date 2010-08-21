
namespace Xmpedit {

public class PropertyDetailView : Gtk.ScrolledWindow {

    public MetadataTreeView tree_view { get; construct; }

    public PropertyDetailView.connected_to(ImageMetadata image_metadata, MetadataTreeView tree_view) {
        Object(tree_view: tree_view);
    }

    construct {
        set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
        tree_view.cursor_changed.connect(() => {
            Gtk.TreeIter iter;
            tree_view.get_selection().get_selected(null, out iter);
            Value value;
            tree_view.model.get_value(iter, 1, out value);
            PropertyEditor pe = (PropertyEditor) value.get_object();
            pe.refresh();
            //remove(child);
            add_with_viewport(pe);
        });
    }

}

}
