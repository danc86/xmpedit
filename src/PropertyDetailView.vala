/*
 * xmpedit
 * Copyright 2010 Dan Callaghan <djc@djc.id.au>
 * Released under GPLv2
 */

namespace Xmpedit {

private class DescriptionView : Gtk.Table {

    public Description description { get; construct; }
    
    public DescriptionView(Description description) {
        Object(description: description);
    }
    
    construct {
        n_rows = 2;
        n_columns = 2;
        homogeneous = false;
        
        var text_view = new Gtk.TextView();
        text_view.wrap_mode = Gtk.WrapMode.WORD;
        
        var label = new Gtk.Label(description.display_name());
        label.xalign = 0;
        label.mnemonic_widget = text_view;
        attach(label,
                0, 1, 0, 1,
                Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND, 0,
                0, 0);
        set_row_spacing(0, 4);
        
        var lang_hbox = new Gtk.HBox(/* homogeneous */ false, /* spacing */ 4);
        var lang_entry = new Gtk.Entry(); // XXX make a combo
        lang_entry.width_chars = 8;
        var lang_label = new Gtk.Label("Language:");
        lang_label.xalign = 1;
        lang_label.mnemonic_widget = lang_entry;
        lang_hbox.add(lang_label);
        lang_hbox.add(lang_entry);
        attach(lang_hbox,
                1, 2, 0, 1,
                0, 0,
                0, 0);
        set_col_spacing(0, 10);
        
        var text_scrolled = new Gtk.ScrolledWindow(null, null);
        text_scrolled.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
        text_scrolled.shadow_type = Gtk.ShadowType.ETCHED_IN;
        text_scrolled.add(text_view);
        attach(text_scrolled,
                0, 2, 1, 2,
                Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND, Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                0, 0);
        
        
        text_view.buffer.text = description.value;
        lang_entry.text = description.lang;
        text_view.buffer.changed.connect(() => {
            description.value = text_view.buffer.text;
        });
        lang_entry.changed.connect(() => {
            description.lang = lang_entry.text;
        });
    }

}

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
            var p = (ImageProperty) value.get_object();
            if (child != null) {
                remove(child);
            }
            // XXX
            var d = new DescriptionView((Description) p);
            add(d);
            d.show_all();
        });
    }

}

}
