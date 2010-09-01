
namespace RDF {

private class Writer {

    private Graph graph;
    private Genx.Writer genx_writer = new Genx.Writer();
    private StringBuilder output = new StringBuilder();
    
    public Writer(Graph graph) {
        this.graph = graph;
    }
    
    public string get_xml() {
        return output.str;
    }
    
    /**
     * N.B. not a general RDF writer,
     * only includes statements reachable from start_node!
     */
    public void write(URIRef start_node) {
        Genx.Status status;
        status = genx_writer.start_doc(output);
        assert(status == Genx.Status.SUCCESS);
        unowned Genx.Namespace rdf_ns = genx_writer.declare_namespace(RDF_NS, "rdf", out status);
        assert(status == Genx.Status.SUCCESS);
        unowned Genx.Element rdf_el = genx_writer.declare_element(rdf_ns, "RDF", out status);
        assert(status == Genx.Status.SUCCESS);
        
        rdf_description_el = genx_writer.declare_element(rdf_ns, "Description", out status);
        assert(status == Genx.Status.SUCCESS);
        rdf_about_attr = genx_writer.declare_attribute(rdf_ns, "about", out status);
        assert(status == Genx.Status.SUCCESS);
        unowned Genx.Namespace xml_ns = genx_writer.declare_namespace(XML_NS, "xml", out status);
        assert(status == Genx.Status.SUCCESS);
        xml_lang_attr = genx_writer.declare_attribute(xml_ns, "lang", out status);
        assert(status == Genx.Status.SUCCESS);
        
        status = rdf_el.start();
        assert(status == Genx.Status.SUCCESS);
        write_resource(start_node);
        status = genx_writer.end_element();
        assert(status == Genx.Status.SUCCESS);
        status = genx_writer.end_doc();
        assert(status == Genx.Status.SUCCESS);
    }
    
    /* for efficiency */
    private unowned Genx.Element rdf_description_el;
    private unowned Genx.Attribute rdf_about_attr;
    private unowned Genx.Attribute xml_lang_attr;
    
    private void write_resource(URIRef node) {
        Genx.Status status;
        status = rdf_description_el.start();
        assert(status == Genx.Status.SUCCESS);
        status = rdf_about_attr.add(node.uri);
        assert(status == Genx.Status.SUCCESS);
        foreach (var statement in graph.find_matching_statements(node, null, null)) {
            write_property(statement.predicate, statement.object);
        }
        status = genx_writer.end_element();
        assert(status == Genx.Status.SUCCESS);
    }
    
    private void write_property(URIRef predicate, Node object) {
        unowned Genx.Namespace ns;
        string local_name;
        split_uri(predicate.uri, out ns, out local_name);
        Genx.Status status;
        unowned Genx.Element property_el; // XXX reuse
        property_el = genx_writer.declare_element(ns, local_name, out status);
        assert(status == Genx.Status.SUCCESS);
        status = property_el.start();
        assert(status == Genx.Status.SUCCESS);
        if (object is PlainLiteral) {
            PlainLiteral literal = (PlainLiteral) object;
            if (literal.lang != null) {
                status = xml_lang_attr.add(literal.lang);
                assert(status == Genx.Status.SUCCESS);
            }
            status = genx_writer.add_text(literal.lexical_value);
            assert(status == Genx.Status.SUCCESS);
        } else {
            assert_not_reached();
        }
        status = genx_writer.end_element();
        assert(status == Genx.Status.SUCCESS);
    }
    
    private void split_uri(string uri,
            out unowned Genx.Namespace ns, out string local_name) {
        var last_slash = uri.pointer_to_offset(uri.rchr(-1, '/')); // XXX crude
        var ns_uri = uri.substring(0, last_slash + 1);
        var ns_prefix = is_wellknown_ns(ns_uri);
        Genx.Status status;
        ns = genx_writer.declare_namespace(ns_uri, ns_prefix, out status);
        assert(status == Genx.Status.SUCCESS);
        local_name = uri.substring(last_slash + 1);
    }
    
    private string? is_wellknown_ns(string ns) {
        for (int i = 0; i < WELL_KNOWN_NAMESPACES.length[0]; i ++)
            if (WELL_KNOWN_NAMESPACES[i,1] == ns)
                return WELL_KNOWN_NAMESPACES[i,0];
        return null;
    }
    
    private static string[,] WELL_KNOWN_NAMESPACES = {
        { "foaf", "http://xmlns.com/foaf/0.1/" }
    };

}

#if TEST

namespace WriterTests {

public void test_literal_property() {
    var person = new URIRef("http://example.com/");
    var foaf_name = new URIRef("http://xmlns.com/foaf/0.1/name");
    var person_name = new PlainLiteral.with_lang("Person", "en");
    
    var g = new Graph();
    g.insert(new Statement(person, foaf_name, person_name));
    assert_equal(
        """<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">""" +
            """<rdf:Description rdf:about="http://example.com/">""" +
                """<foaf:name xmlns:foaf="http://xmlns.com/foaf/0.1/" xml:lang="en">Person</foaf:name>""" +
            """</rdf:Description>""" +
        """</rdf:RDF>""",
        g.to_xml(person));
}

private void assert_equal(string expected, string actual) {
    if (actual != expected) {
        stderr.puts(@"\nActual: [$(actual)]\nExpected: [$(expected)]\n");
        assert(actual == expected);
    }
}

}

public void register_writer_tests() {
    Test.add_func("/rdf/writer/test_literal_property", WriterTests.test_literal_property);
}

#endif

}
