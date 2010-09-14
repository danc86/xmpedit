/*
 * xmpedit
 * Copyright 2010 Dan Callaghan <djc@djc.id.au>
 * Released under GPLv2
 */

namespace Xmpedit {

private class PropertySummaryCellRenderer : Gtk.CellRendererText {

    private PropertyEditor _property_editor;
    public PropertyEditor property_editor {
        get {
            return _property_editor;
        }
        set {
            _property_editor = value;
            markup = value.list_markup();
        }
    }

}

public class MetadataTreeView : Gtk.TreeView {

    public MetadataTreeView.connected_to(ImageMetadata metadata) {
        Object(model: metadata);
    }
    
    construct {
        Gtk.TreeViewColumn column = new Gtk.TreeViewColumn();
        column.title = "Image properties";
        column.sizing = Gtk.TreeViewColumnSizing.FIXED;
        column.fixed_width = 300;
        var cell_renderer = new PropertySummaryCellRenderer();
        column.pack_start(cell_renderer, /* expand */ true);
        column.add_attribute(cell_renderer, "property_editor", 0);
        append_column(column);
        get_selection().set_mode(Gtk.SelectionMode.BROWSE);
    }

}

}
