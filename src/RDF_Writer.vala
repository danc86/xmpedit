/*
 * xmpedit
 * Copyright 2010 Dan Callaghan <djc@djc.id.au>
 * Released under GPLv2
 */

namespace RDF {

private class Writer {

    private static Regex local_name_regex;
    static construct {
        try {
            local_name_regex = new Regex(".*?([_a-zA-Z][-_.a-zA-Z0-9]*)$");
        } catch (RegexError e) {
            error(@"local_name_regex is broken: $(e.message)");
        }
    }

    private Graph graph;
    private Genx.Writer genx_writer = new Genx.Writer();
    private StringBuilder output = new StringBuilder();
    private Gee.Set<Statement> written_statements = new Gee.HashSet<Statement>();
    
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
        genx_writer.start_doc(output);
        unowned Genx.Namespace rdf_ns = genx_writer.declare_namespace(RDF_NS, "rdf");
        unowned Genx.Element rdf_el = genx_writer.declare_element(rdf_ns, "RDF");
        
        rdf_description_el = genx_writer.declare_element(rdf_ns, "Description");
        rdf_about_attr = genx_writer.declare_attribute(rdf_ns, "about");
        rdf_resource_attr = genx_writer.declare_attribute(rdf_ns, "resource");
        unowned Genx.Namespace xml_ns = genx_writer.declare_namespace(XML_NS, "xml");
        xml_lang_attr = genx_writer.declare_attribute(xml_ns, "lang");
        
        rdf_el.start();
        write_resource(start_node, true);
        genx_writer.end_element();
        genx_writer.end_document();
    }
    
    /* for efficiency */
    private unowned Genx.Element rdf_description_el;
    private unowned Genx.Attribute rdf_about_attr;
    private unowned Genx.Attribute rdf_resource_attr;
    private unowned Genx.Attribute xml_lang_attr;
    
    private void write_resource(SubjectNode node, bool is_start = false) {
        if (is_start) {
            rdf_description_el.start();
            rdf_about_attr.add("");
        } else {
            URIRef type = null;
            foreach (var statement in graph.find_matching_statements(
                    node, new URIRef(RDF_NS + "type"), null)) {
                if (statement.object is URIRef) {
                    type = (URIRef) statement.object;
                    written_statements.add(statement);
                    break;
                }
            }
            if (type != null) {
                unowned Genx.Namespace ns;
                string local_name;
                split_uri(((URIRef) type).uri, out ns, out local_name);
                unowned Genx.Element resource_el; // XXX reuse
                resource_el = genx_writer.declare_element(ns, local_name);
                resource_el.start();
            } else {
                rdf_description_el.start();
            }
            if (node is URIRef) {
                rdf_about_attr.add(((URIRef) node).uri);
            }
        }
        foreach (var statement in graph.find_matching_statements(node, null, null)) {
            if (!(statement in written_statements)) {
                write_property(statement.predicate, statement.object);
                written_statements.add(statement);
            }
        }
        genx_writer.end_element();
    }
    
    private void write_property(URIRef predicate, Node object) {
        unowned Genx.Namespace ns;
        string local_name;
        split_uri(predicate.uri, out ns, out local_name);
        unowned Genx.Element property_el; // XXX reuse
        property_el = genx_writer.declare_element(ns, local_name);
        property_el.start();
        if (object is PlainLiteral) {
            PlainLiteral literal = (PlainLiteral) object;
            if (literal.lang != null) {
                xml_lang_attr.add(literal.lang);
            }
            genx_writer.add_text(literal.lexical_value);
        } else if (object is URIRef) {
            URIRef uriref = (URIRef) object;
            if (graph.has_matching_statement(uriref, null, null)) {
                write_resource(uriref);
            } else {
                rdf_resource_attr.add(uriref.uri);
            }
        } else if (object is Blank) {
            write_resource((Blank) object);
        } else {
            critical(@"Unhandled object type: $(object)");
        }
        genx_writer.end_element();
    }
    
    private void split_uri(string uri,
            out unowned Genx.Namespace ns, out string local_name) {
        MatchInfo match_info;
        local_name_regex.match(uri, 0, out match_info);
        if (!match_info.matches())
            error(@"Cannot match local name part of $(uri)");
        local_name = match_info.fetch(1);
        var ns_uri = uri.substring(0, uri.length - local_name.length);
        var ns_prefix = is_wellknown_ns(ns_uri);
        ns = genx_writer.declare_namespace(ns_uri, ns_prefix);
    }
    
    private string? is_wellknown_ns(string ns) {
        for (int i = 0; i < WELL_KNOWN_NAMESPACES.length[0]; i ++)
            if (WELL_KNOWN_NAMESPACES[i,1] == ns)
                return WELL_KNOWN_NAMESPACES[i,0];
        return null;
    }
    
    private static string[,] WELL_KNOWN_NAMESPACES = {
        { "foaf", "http://xmlns.com/foaf/0.1/" },
        { "dc", "http://purl.org/dc/elements/1.1/" },
        { "Iptc4xmlCore", "http://iptc.org/std/Iptc4xmpCore/1.0/xmlns/" }
    };

}

#if TEST

namespace WriterTests {

public void test_literal_object() {
    var person = new URIRef("http://example.com/");
    var foaf_name = new URIRef("http://xmlns.com/foaf/0.1/name");
    var person_name = new PlainLiteral.with_lang("Person", "en");
    
    var g = new Graph();
    g.insert(new Statement(person, foaf_name, person_name));
    assert_equal(
        """<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">""" +
            """<rdf:Description rdf:about="">""" +
                """<foaf:name xmlns:foaf="http://xmlns.com/foaf/0.1/" xml:lang="en">Person</foaf:name>""" +
            """</rdf:Description>""" +
        """</rdf:RDF>""",
        g.to_xml(person));
}

public void test_resource_object() {
    var person = new URIRef("http://example.com/");
    var buddy = new URIRef("http://example.com/buddy");
    var foaf_knows = new URIRef("http://xmlns.com/foaf/0.1/knows");
    var foaf_name = new URIRef("http://xmlns.com/foaf/0.1/name");
    var buddy_name = new PlainLiteral("My Buddy");
    
    var g = new Graph();
    g.insert(new Statement(person, foaf_knows, buddy));
    g.insert(new Statement(buddy, foaf_name, buddy_name));
    assert_equal(
        """<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">""" +
            """<rdf:Description rdf:about="">""" +
                """<foaf:knows xmlns:foaf="http://xmlns.com/foaf/0.1/">""" +
                    """<rdf:Description rdf:about="http://example.com/buddy">""" +
                        """<foaf:name>My Buddy</foaf:name>""" +
                    """</rdf:Description>""" +
                """</foaf:knows>""" +
            """</rdf:Description>""" +
        """</rdf:RDF>""",
        g.to_xml(person));
}

public void test_blank_object() {
    var person = new URIRef("http://example.com/");
    var buddy = new Blank();
    var foaf_knows = new URIRef("http://xmlns.com/foaf/0.1/knows");
    var foaf_name = new URIRef("http://xmlns.com/foaf/0.1/name");
    var buddy_name = new PlainLiteral("My Buddy");
    
    var g = new Graph();
    g.insert(new Statement(person, foaf_knows, buddy));
    g.insert(new Statement(buddy, foaf_name, buddy_name));
    assert_equal(
        """<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">""" +
            """<rdf:Description rdf:about="">""" +
                """<foaf:knows xmlns:foaf="http://xmlns.com/foaf/0.1/">""" +
                    """<rdf:Description>""" +
                        """<foaf:name>My Buddy</foaf:name>""" +
                    """</rdf:Description>""" +
                """</foaf:knows>""" +
            """</rdf:Description>""" +
        """</rdf:RDF>""",
        g.to_xml(person));
}

public void test_leaf_resource_object() {
    var person = new URIRef("http://example.com/");
    var foaf_knows = new URIRef("http://xmlns.com/foaf/0.1/knows");
    var other_person = new URIRef("http://example.com/other");
    
    var g = new Graph();
    g.insert(new Statement(person, foaf_knows, other_person));
    assert_equal(
        """<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">""" +
            """<rdf:Description rdf:about="">""" +
                """<foaf:knows xmlns:foaf="http://xmlns.com/foaf/0.1/" """ +
                    """rdf:resource="http://example.com/other">""" +
                """</foaf:knows>""" +
            """</rdf:Description>""" +
        """</rdf:RDF>""",
        g.to_xml(person));
}

public void test_rdf_type() {
    var person = new URIRef("http://example.com/");
    var foaf_knows = new URIRef("http://xmlns.com/foaf/0.1/knows");
    var other_person = new URIRef("http://example.com/other");
    var foaf_person = new URIRef("http://xmlns.com/foaf/0.1/Person");
    
    var g = new Graph();
    g.insert(new Statement(person, foaf_knows, other_person));
    g.insert(new Statement(other_person, new URIRef(RDF_NS + "type"), foaf_person));
    assert_equal(
        """<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">""" +
            """<rdf:Description rdf:about="">""" +
                """<foaf:knows xmlns:foaf="http://xmlns.com/foaf/0.1/">""" +
                    """<foaf:Person rdf:about="http://example.com/other">""" +
                    """</foaf:Person>""" +
                """</foaf:knows>""" +
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
    Test.add_func("/rdf/writer/test_literal_object", WriterTests.test_literal_object);
    Test.add_func("/rdf/writer/test_resource_object", WriterTests.test_resource_object);
    Test.add_func("/rdf/writer/test_blank_object", WriterTests.test_blank_object);
    Test.add_func("/rdf/writer/test_leaf_resource_object", WriterTests.test_leaf_resource_object);
    Test.add_func("/rdf/writer/test_rdf_type", WriterTests.test_rdf_type);
}

#endif

}
