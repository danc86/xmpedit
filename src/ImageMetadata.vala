
namespace Xmpedit {

public interface PropertyEditor : Gtk.Widget {

    public static Type[] all_types() {
        return { typeof(Description) };
    }

    public abstract string prop_name { get; }
    public abstract RDF.URIRef subject { get; set; }
    
    public abstract string value_summary();
    public abstract bool populate(RDF.Graph graph);
    public abstract Gee.Collection<RDF.Statement> as_rdf();
    
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
    }

    public string value_summary() {
        string value = text_view.buffer.text;
        return (value.size() > 0 ? value : "<i>not set</i>");
    }

    private RDF.PlainLiteral? find_literal(RDF.Graph graph) {
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
    
    public bool populate(RDF.Graph graph) {
        var literal = find_literal(graph);
        if (literal == null) {
            text_view.buffer.text = "";
            lang_entry.text = "";
            return false;
        } else {
            text_view.buffer.text = literal.lexical_value;
            lang_entry.text = (literal.lang != null ? literal.lang : "");
            return true;
        }
    }
    
    public Gee.Collection<RDF.Statement> as_rdf() {
        var result = new Gee.ArrayList<RDF.Statement>();
        string value = text_view.buffer.text;
        string lang = lang_entry.text;
        if (value.size() > 0) {
            RDF.PlainLiteral object;
            if (lang.size() > 0)
                object = new RDF.PlainLiteral.with_lang(value, lang);
            else
                object = new RDF.PlainLiteral(value);
            result.add(new RDF.Statement(subject, DC_DESCRIPTION, object));
        }
        return result;
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

public class ImageMetadata : Object {

    public string path { get; construct; }
    public Gee.List<PropertyEditor> properties { get; construct; }
    
    public signal void updated();
    
    public ImageMetadata(string path) {
        Object(path: path);
    }
    
    construct {
        properties = new Gee.LinkedList<PropertyEditor>();
    }
    
    public void load() throws GLib.Error {
        var exiv_metadata = new GExiv2.Metadata();
        exiv_metadata.open_path(path);
        string xmp = exiv_metadata.get_xmp_packet();
        stdout.puts(xmp);
        var base_uri = File.new_for_path(path).get_uri();
        var g = new RDF.Graph.from_xml(xmp, base_uri);
        foreach (var s in g.get_statements())
            stdout.puts(@"$s\n");
        var subject = new RDF.URIRef(base_uri);
        foreach (var type in PropertyEditor.all_types()) {
            var pe = (PropertyEditor) Object.new(type);
            pe.subject = subject;
            if (pe.populate(g))
                properties.add(pe);
        }
        //foreach (var tag in exiv_metadata.get_xmp_tags()) {
        //    properties.add(new PropertyEditor(tag, exiv_metadata.get_xmp_tag_string(tag)));
        //}
        updated();
    }
    
    public void save() {
        var g = new RDF.Graph();
        foreach (var pe in properties) {
            foreach (var s in pe.as_rdf()) {
                g.insert(s);
            }
        }
        foreach (var s in g.get_statements())
            stdout.puts(@"$s\n");
        // XXX actually write it out
    }
    
}

}
