
namespace Xmpedit {

public interface PropertyEditor : Gtk.Widget {

    public static Type[] all_types() {
        return { typeof(Description) };
    }

    public abstract string prop_name { get; }
    public abstract RDF.Graph graph { get; set; }
    public abstract RDF.URIRef subject { get; set; }
    
    /**
     * Examine the graph and return a one-line summary of the value found
     * (or "<i>not set</i>" if no value was found).
     */
    protected abstract string value_summary();
    
    public string prop_display_name() {
        return prop_name.substring(0, 1).up() + prop_name.substring(1);
    }

    public string list_markup() {
	    return @"<b>$(prop_display_name())</b>\n$(value_summary())";
	}
	
}

private class Description : Gtk.Table, PropertyEditor {

    private static RDF.URIRef DC_DESCRIPTION = new RDF.URIRef("http://purl.org/dc/elements/1.1/description");
    
    public string prop_name { get { return "description"; } }
    public RDF.Graph graph { get; set; }
    public RDF.URIRef subject { get; set; }

    private Gtk.ScrolledWindow text_scrolled = new Gtk.ScrolledWindow(null, null);
    private Gtk.TextView text_view = new Gtk.TextView();
    private Gtk.Entry lang_entry = new Gtk.Entry(); // XXX make a combo
    
    construct {
        n_rows = 2;
        n_columns = 2;
        homogeneous = false;
        
        var label = new Gtk.Label(prop_display_name());
        label.xalign = 0;
        label.mnemonic_widget = text_view;
        attach(label,
                0, 1, 0, 1,
                Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND, 0,
                0, 0);
        set_row_spacing(0, 4);
        
        var lang_hbox = new Gtk.HBox(/* homogeneous */ false, /* spacing */ 4);
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

        text_view.wrap_mode = Gtk.WrapMode.WORD;
        
        text_scrolled.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
        text_scrolled.shadow_type = Gtk.ShadowType.ETCHED_IN;
        text_scrolled.add(text_view);
        attach(text_scrolled,
                0, 2, 1, 2,
                Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND, Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                0, 0);
        
        show.connect(load);
        hide.connect(commit);
    }

    protected string value_summary() {
        var literal = find_literal();
        return (literal != null ? literal.lexical_value : "<i>not set</i>");
    }

    private RDF.PlainLiteral? find_literal() {
        var description = graph.find_object(subject, DC_DESCRIPTION);
        if (description == null)
            return null;
        if (description is RDF.SubjectNode) {
            var node = (RDF.SubjectNode) description;
            if (graph.has_matching_statement(node,
                    new RDF.URIRef(RDF.RDF_NS + "type"),
                    new RDF.URIRef(RDF.RDF_NS + "Alt"))) {
                description = select_alternative(node, graph);
                if (description == null) {
                    warning("found rdf:Alt with no alternatives for %s", prop_name);
                    return null;
                }
            }
        }
        if (!(description is RDF.PlainLiteral)) {
            warning("found non-literal node for %s", prop_name);
            return null;
        }
        return (RDF.PlainLiteral) description;
    }
    
    private void load() {
        var literal = find_literal();
        if (literal == null) {
            text_view.buffer.text = "";
            lang_entry.text = "";
        } else {
            text_view.buffer.text = literal.lexical_value;
            lang_entry.text = (literal.lang != null ? literal.lang : "");
        }
    }
    
    private void commit() {
        graph.remove_matching_statements(subject, DC_DESCRIPTION, null);
        string value = text_view.buffer.text;
        string lang = lang_entry.text;
        if (value.size() > 0) {
            RDF.PlainLiteral object;
            if (lang.size() > 0)
                object = new RDF.PlainLiteral.with_lang(value, lang);
            else
                object = new RDF.PlainLiteral(value);
            graph.insert(new RDF.Statement(subject, DC_DESCRIPTION, object));
        }
    }

}

/** Given an rdf:Alt node, returns the "best" alternative */
private RDF.Node? select_alternative(RDF.SubjectNode alt_node, RDF.Graph graph) {
    var preferred_lang = get_preferred_lang();
    var alternatives = graph.find_objects(alt_node, new RDF.URIRef(RDF.RDF_NS + "li"));
    if (alternatives.size == 0)
        return null;
    foreach (var alternative in alternatives) {
        if (alternative is RDF.PlainLiteral) {
            var literal = (RDF.PlainLiteral) alternative;
            if (literal.lang == preferred_lang)
                return literal;
        }
    }
    return alternatives[0];
}

// XXX make this a user pref somehow?
private string get_preferred_lang() {
    var lang = Environment.get_variable("LANG");
    return (lang != null ? lang.substring(0, 2) : "en");
}

public class ImageMetadata : Object, Gtk.TreeModel {

    public string path { get; construct; }
    public Gee.List<PropertyEditor> properties { get; construct; }
    private Exiv2.Image image;
    private size_t xmp_packet_size;
    private RDF.Graph graph;
    private RDF.URIRef subject;
    
    public signal void updated();
    
    // TreeModel stuff
    private static int last_stamp = 1;
    private int stamp;
    
    public ImageMetadata(string path) {
        Object(path: path);
    }
    
    construct {
        properties = new Gee.LinkedList<PropertyEditor>();
        lock (last_stamp) {
            stamp = last_stamp ++;
        }
    }
    
    public void load() {
        return_if_fail(image == null); // only call this once
        image = new Exiv2.Image.from_path(path);
        image.read_metadata();
        unowned string xmp = image.xmp_packet;
        xmp_packet_size = xmp.size();
#if DEBUG
        stderr.puts("=== Extracted XMP packet:\n");
        stderr.puts(xmp);
        stderr.putc('\n');
#endif
        var base_uri = File.new_for_path(path).get_uri();
        graph = new RDF.Graph.from_xml(xmp, base_uri);
#if DEBUG
        stderr.puts("=== Parsed RDF graph:\n");
        foreach (var s in graph.get_statements())
            stderr.puts(@"$s\n");
#endif
        subject = new RDF.URIRef(base_uri);
        foreach (var type in PropertyEditor.all_types()) {
            var pe = (PropertyEditor) Object.new(type);
            pe.graph = graph;
            pe.subject = subject;
            properties.add(pe);
        }
        //foreach (var tag in exiv_metadata.get_xmp_tags()) {
        //    properties.add(new PropertyEditor(tag, exiv_metadata.get_xmp_tag_string(tag)));
        //}
        updated();
    }
    
    public void save() {
        return_if_fail(image != null); // only call after successful loading
        // XXX shouldn't write if not dirty!
#if DEBUG
        stderr.puts("=== Final RDF graph:\n");
        foreach (var s in graph.get_statements())
            stderr.puts(@"$s\n");
#endif
        var xml = new StringBuilder.sized(xmp_packet_size);
        xml.append("<?xpacket begin=\"\xef\xbb\xbf\" id=\"W5M0MpCehiHzreSzNTczkc9d\"?>" +
                """<x:xmpmeta xmlns:x="adobe:ns:meta/" x:xmptk="xmpedit 0.0-dev">""");
        xml.append(graph.to_xml(subject));
        var new_size = xml.str.size() + 12; // plus </x:xmpmeta>
        size_t padding;
        if (new_size <= xmp_packet_size)
            padding = xmp_packet_size - new_size;
        else
            padding = new_size + 1024;
        for (size_t i = 0; i < padding; i ++)
            xml.append_c(' ');
        xml.append("""</x:xmpmeta>""");
#if DEBUG
        stderr.puts("=== Serialized XMP packet:\n");
        stderr.puts(xml.str);
#endif
        image.xmp_packet = xml.str;
        image.write_metadata();
    }
    
    /****** TREEMODEL IMPLEMENTATION STUFF **********/
    
    public Type get_column_type(int column) {
        return_val_if_fail(column == 0, 0);
        return typeof(PropertyEditor);
    }
    
    public int get_n_columns() {
        return 1;
    }
    
    public Gtk.TreeModelFlags get_flags() {
        return Gtk.TreeModelFlags.LIST_ONLY;
    }
    
    public bool get_iter(out Gtk.TreeIter iter, Gtk.TreePath path) {
        if (path.get_depth() > 1) return false;
        var index = path.get_indices()[0];
        if (index > properties.size - 1) return false;
        iter = { stamp, (void*) properties[index], null, null };
        return true;
    }

    public Gtk.TreePath get_path(Gtk.TreeIter iter) {
        return_val_if_fail(iter.stamp == stamp, null);
        var pe = (PropertyEditor) iter.user_data;
        return new Gtk.TreePath.from_indices(properties.index_of(pe));
    }
    
    public void get_value(Gtk.TreeIter iter, int column, out Value value) {
        return_if_fail(iter.stamp == stamp);
        return_if_fail(column == 0);
        value = Value(typeof(PropertyEditor));
        value.set_object((PropertyEditor) iter.user_data);
    }
    
    public bool iter_children(out Gtk.TreeIter iter, Gtk.TreeIter? parent) {
        if (parent == null) {
            iter = { stamp, (void*) properties[0], null, null };
            return true;
        }
        return false;
    }
    
    public bool iter_has_child(Gtk.TreeIter iter) {
        return false;
    }
    
    public int iter_n_children(Gtk.TreeIter? iter) {
        if (iter == null)
            return properties.size;
        return 0;
    }
    
    public bool iter_next(ref Gtk.TreeIter iter) {
        return_val_if_fail(iter.stamp == stamp, false);
        var index = properties.index_of((PropertyEditor) iter.user_data);
        if (index < properties.size - 1) {
            iter.user_data = (void*) properties[index + 1];
            return true;
        }
        return false;
    }
    
    public bool iter_nth_child(out Gtk.TreeIter iter, Gtk.TreeIter? parent, int n) {
        if (parent == null && n <= properties.size - 1) {
            iter = { stamp, (void*) properties[n], null, null };
            return true;
        }
        return false;
    }
    
    public bool iter_parent(out Gtk.TreeIter iter, Gtk.TreeIter child) {
        return false;
    }
    
    public void ref_node(Gtk.TreeIter iter) {
    }
    
    public void unref_node(Gtk.TreeIter iter) {
    }
    
}

}
