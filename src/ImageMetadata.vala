
namespace Xmpedit {

public interface PropertyEditor : Gtk.Widget {

    public static Type[] all_types() {
        return { typeof(Description) };
    }

    public abstract string prop_name { get; }
    public abstract RDF.Graph graph { get; set; }
    public abstract RDF.URIRef subject { get; set; }
    
    public abstract bool exists_in_graph();
    public abstract string value_summary();
    public abstract void refresh();

    public string list_markup() {
        var display_name = prop_name.substring(0, 1).up() + prop_name.substring(1);
	    return @"<b>$(display_name)</b>\n$(value_summary())";
	}
	
}

private class Description : Gtk.Table, PropertyEditor {

    private static RDF.URIRef DC_DESCRIPTION = new RDF.URIRef("http://purl.org/dc/elements/1.1/description");
    
    public string prop_name { get { return "description"; } }
    public RDF.Graph graph { get; set; }
    public RDF.URIRef subject { get; set; }
    private Gtk.TextView text_view = new Gtk.TextView();
    
    construct {
        n_rows = 1;
        n_columns = 1;
        homogeneous = false;
        attach(text_view,
                0, 1, 0, 1,
                Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND, Gtk.AttachOptions.FILL | Gtk.AttachOptions.EXPAND,
                10, 10);
    }

    public bool exists_in_graph() {
        return graph.find_objects(subject, DC_DESCRIPTION).size > 0;
    }
    
    public string value_summary() {
        var description = graph.find_object(subject, DC_DESCRIPTION);
        if (description == null)
            return "<i>(not set)</i>";
        if (description is RDF.SubjectNode) {
            var node = (RDF.SubjectNode) description;
            if (graph.has_matching_statement(node,
                    new RDF.URIRef(RDF.RDF_NS + "type"),
                    new RDF.URIRef(RDF.RDF_NS + "Alt"))) {
                description = select_alternative(node, graph);
            }
        }
        if (!(description is RDF.PlainLiteral)) {
            return "<i>(non-literal node)</i>";
        }
        var literal = (RDF.PlainLiteral) description;
        return literal.lexical_value;
    }
    
    public void refresh() {
        text_view.buffer.text = value_summary();
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
    
    // ugh, for exceptions
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
            pe.graph = g;
            pe.subject = subject;
            if (pe.exists_in_graph())
                properties.add(pe);
        }
        //foreach (var tag in exiv_metadata.get_xmp_tags()) {
        //    properties.add(new PropertyEditor(tag, exiv_metadata.get_xmp_tag_string(tag)));
        //}
        updated();
    }

}

}
