
namespace Xmpedit {

public class PropertyDetailView : Gtk.Alignment {

    public MetadataTreeView tree_view { get; construct; }

    public PropertyDetailView.connected_to(ImageMetadata image_metadata, MetadataTreeView tree_view) {
        Object(tree_view: tree_view);
    }

    construct {
        set_padding(0, 10, 10, 10);
        tree_view.cursor_changed.connect(() => {
            Gtk.TreeIter iter;
            tree_view.get_selection().get_selected(null, out iter);
            Value value;
            tree_view.model.get_value(iter, 0, out value);
            PropertyEditor pe = (PropertyEditor) value.get_object();
            if (child != null) {
                child.hide();
                remove(child);
            }
            pe.show();
            add(pe);
        });
    }

}

}
