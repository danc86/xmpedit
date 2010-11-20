/*
 * xmpedit
 * Copyright 2010 Dan Callaghan <djc@djc.id.au>
 * Released under GPLv2
 */

namespace Xmpedit {

public interface ImageProperty : Object {

    public static Type[] all_types() {
        return { typeof(Description) };
    }

    public abstract string name { get; }
    public abstract RDF.Graph graph { get; construct; }
    public abstract RDF.URIRef subject { get; construct; }
    
    public signal void changed();
    
    /**
     * Examine the graph and return a one-line summary of the value found
     * (or "<i>not set</i>" if no value was found).
     */
    protected abstract string value_summary();
    
    public string display_name() {
        return name.substring(0, 1).up() + name.substring(1);
    }

    public string list_markup() {
	    return @"<b>$(display_name())</b>\n$(value_summary())";
	}
	
}

public class Description : Object, ImageProperty {

    private static RDF.URIRef DC_DESCRIPTION = new RDF.URIRef("http://purl.org/dc/elements/1.1/description");
    
    public string name { get { return "description"; } }
    public RDF.Graph graph { get; construct; }
    public RDF.URIRef subject { get; construct; }

    private string _value;
    private string _lang;
    
    public string value {
        get { return _value; }
        set { _value = value; update(); }
    }
    public string lang {
        get { return _lang; }
        set { _lang = value; update(); }
    }
        
    construct {
        var literal = find_literal();
        if (literal == null) {
            _value = "";
            _lang = "";
        } else {
            _value = literal.lexical_value;
            _lang = (literal.lang != null ? literal.lang : "");
        }
    }

    protected string value_summary() {
        return _value;
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
                    warning("found rdf:Alt with no alternatives for %s", name);
                    return null;
                }
            }
        }
        if (!(description is RDF.PlainLiteral)) {
            warning("found non-literal node for %s", name);
            return null;
        }
        return (RDF.PlainLiteral) description;
    }
    
    private void update() {
        graph.remove_matching_statements(subject, DC_DESCRIPTION, null);
        if (_value.length > 0) {
            var alt = new RDF.Blank();
            graph.insert(new RDF.Statement(subject, DC_DESCRIPTION, alt));
            graph.insert(new RDF.Statement(alt,
                    new RDF.URIRef(RDF.RDF_NS + "type"),
                    new RDF.URIRef(RDF.RDF_NS + "Alt")));
            RDF.PlainLiteral object;
            if (_lang.length > 0)
                object = new RDF.PlainLiteral.with_lang(_value, _lang);
            else
                object = new RDF.PlainLiteral(_value);
            graph.insert(new RDF.Statement(alt,
                    new RDF.URIRef(RDF.RDF_NS + "li"), object));
        }
        changed();
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
    public Gee.List<ImageProperty> properties { get; construct; }
    public bool dirty { get; set; }
    private Exiv2.Image image;
    private size_t xmp_packet_size;
    private RDF.Graph graph;
    private RDF.URIRef subject;
    
    // TreeModel stuff
    private static int last_stamp = 1;
    private int stamp;
    
    public ImageMetadata(string path) {
        Object(path: path, dirty: false);
    }
    
    construct {
        properties = new Gee.LinkedList<ImageProperty>();
        lock (last_stamp) {
            stamp = last_stamp ++;
        }
    }
    
    public void load() {
        return_if_fail(image == null); // only call this once
        image = new Exiv2.Image.from_path(path);
        image.read_metadata();
        read_xmp();
    }
    
    public void revert() {
        return_if_fail(image != null);
        read_xmp();
    }
    
    private void read_xmp() {
        unowned string xmp = image.xmp_packet;
        xmp_packet_size = xmp.length;
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
        clear_properties();
        foreach (var type in ImageProperty.all_types()) {
            add_property(type);
        }
        dirty = false;
    }
    
    public void save() {
        return_if_fail(image != null); // only call after successful loading
        return_if_fail(dirty); // only call if dirty
#if DEBUG
        stderr.puts("=== Final RDF graph:\n");
        foreach (var s in graph.get_statements())
            stderr.puts(@"$s\n");
#endif
        var xml = new StringBuilder.sized(xmp_packet_size);
        xml.append("<?xpacket begin=\"\xef\xbb\xbf\" id=\"W5M0MpCehiHzreSzNTczkc9d\"?>" +
                """<x:xmpmeta xmlns:x="adobe:ns:meta/" x:xmptk="xmpedit 0.0-dev">""");
        xml.append(graph.to_xml(subject));
        xml.append("</x:xmpmeta>");
        var new_size = xml.str.length + 19; // plus trailing PI
        size_t padding;
        if (new_size <= xmp_packet_size)
            padding = xmp_packet_size - new_size;
        else
            padding = new_size + 1024;
        for (size_t i = 0; i < padding; i ++)
            xml.append_c(' ');
        xml.append("""<?xpacket end="w"?>""");
#if DEBUG
        stderr.puts("=== Serialized XMP packet:\n");
        stderr.puts(xml.str);
#endif
        image.xmp_packet = xml.str;
        image.write_metadata();
        dirty = false;
    }
    
    private void clear_properties() {
        for (var i = properties.size - 1; i >= 0; i --) {
            properties.remove_at(i);
            row_deleted(path_for_index(i));
        }
    }
    
    private void add_property(Type type) {
        var index = properties.size;
        var p = (ImageProperty) Object.new(type, graph: graph, subject: subject);
        properties.add(p);
        row_inserted(path_for_index(index), iter_for_index(index));
        p.changed.connect(() => {
            dirty = true;
            row_changed(path_for_index(index), iter_for_index(index));
        });
    }
    
    /****** TREEMODEL IMPLEMENTATION STUFF **********/
    
    private Gtk.TreePath path_for_index(int index) {
        return new Gtk.TreePath.from_indices(index);
    }
    
    private Gtk.TreeIter iter_for_index(int index) {
        return { stamp, (void*) properties[index], null, null };
    }
    
    public Type get_column_type(int column) {
        return_val_if_fail(column == 0, 0);
        return typeof(ImageProperty);
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
        iter = iter_for_index(index);
        return true;
    }

    public Gtk.TreePath get_path(Gtk.TreeIter iter) {
        return_val_if_fail(iter.stamp == stamp, null);
        var p = (ImageProperty) iter.user_data;
        return path_for_index(properties.index_of(p));
    }
    
    public void get_value(Gtk.TreeIter iter, int column, out Value value) {
        return_if_fail(iter.stamp == stamp);
        return_if_fail(column == 0);
        value = Value(typeof(ImageProperty));
        value.set_object((ImageProperty) iter.user_data);
    }
    
    public bool iter_children(out Gtk.TreeIter iter, Gtk.TreeIter? parent) {
        if (parent == null && !properties.is_empty) {
            iter = iter_for_index(0);
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
        var index = properties.index_of((ImageProperty) iter.user_data);
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
