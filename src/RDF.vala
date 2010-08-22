
namespace RDF {

public abstract class Node : Object {

    public abstract bool equals(Node other);
    
    public abstract string to_string();

}

public abstract class SubjectNode : Node {

}

public class URIRef : SubjectNode {

    public string uri { get; construct; }
    
    public URIRef(string uri) {
        Object(uri: uri);
    }
    
    public override bool equals(Node _other) {
        var other = _other as URIRef;
        if (other != null) {
            return this.uri == other.uri;
        }
        return false;
    }
    
    public override string to_string() {
        return @"<$uri>";
    }
    
}

public class Blank : SubjectNode {

    /** This is for informational purposes only! Not a unique id for equality! */
    public string? id { get; construct; }
    
    public Blank(string? id) {
        Object(id: id);
    }
    
    public override bool equals(Node _other) {
        return this == _other;
    }
    
    public override string to_string() {
        if (id != null)
            return @"_:$id";
        return "Blank@%p".printf(&this);
    }

}

public abstract class Literal : Node {

}

public class PlainLiteral : Literal {

    public string lexical_value { get; construct; }
    public string? lang { get; construct; }
    
    public PlainLiteral(string lexical_value) {
        Object(lexical_value: lexical_value);
    }
    
    public PlainLiteral.with_lang(string lexical_value, string lang) {
        Object(lexical_value: lexical_value, lang: lang);
    }
    
    public override bool equals(Node _other) {
        var other = _other as PlainLiteral;
        if (other != null) {
            return this.lexical_value == other.lexical_value &&
                    this.lang == other.lang;
        }
        return false;
    }
    
    public override string to_string() {
        if (lang != null)
            return @"\"$lexical_value\"@$lang";
        return @"\"$lexical_value\"";
    }
    
}

public class Statement : Object {

    public SubjectNode subject { get; construct; }
    public URIRef predicate { get; construct; }
    public Node object { get; construct; }
    
    public Statement(SubjectNode subject, URIRef predicate, Node object) {
        Object(subject: subject, predicate: predicate, object: object);
    }
    
    public string to_string() {
        return @"$subject $predicate $object .";
    }
    
    public static bool equal(Statement left, Statement right) {
        return left.subject.equals(right.subject) &&
                left.predicate.equals(right.predicate) &&
                left.object.equals(right.object);
    }
    
}

// XXX naive
public class Graph : Object {

    class construct {
        Xml.Parser.init();
    }

    private Gee.List<Statement> statements =
        new Gee.ArrayList<Statement>((EqualFunc) Statement.equal);
    private string? base_uri;
    
    public Graph() {
    }
    
    public Graph.from_xml(string xml, string base_uri) throws ParseError {
        this.base_uri = base_uri;
        Xml.Doc* doc = Xml.Parser.parse_memory(xml, (int) xml.size());
        if (doc == null)
            throw new ParseError.UNPARSEABLE_XML("doc == null");
        try {
            Xml.Node* root = doc->get_root_element();
            if (root == null)
                throw new ParseError.EMPTY_XML("root == null");
            var document_element = find_rdf_document_element(root);
            if (document_element == null)
                throw new ParseError.DOCUMENT_ELEMENT_NOT_FOUND("no <rdf:RDF> element");
            for (Xml.Node* child = document_element->children; child != null; child = child->next) {
                if (child->type != Xml.ElementType.ELEMENT_NODE)
                    continue;
                parse_node_element(child);
            }
        } finally {
            delete doc;
        }
    }
    
    // XXX use explicit stack instead of recursion
    private Xml.Node* find_rdf_document_element(Xml.Node* element) {
        if (element->name == "RDF" || element->ns->href == RDF_NS)
            return element;
        for (Xml.Node* child = element->children; child != null; child = child->next) {
            if (child->type != Xml.ElementType.ELEMENT_NODE)
                continue;
            var found = find_rdf_document_element(child);
            if (found != null)
                return found;
        }
        return null;
    }
    
    // XXX intern URIs and lang tags
    
    private SubjectNode parse_node_element(Xml.Node* element) throws ParseError {
        // determine resource URI
        SubjectNode subject;
        var subject_uri = element->get_ns_prop("about", RDF_NS);
        if (subject_uri != null)
            subject = new URIRef(resolve_uri(subject_uri, base_uri));
        else
            subject = new Blank(null);
        
        // is it a typed element?
        if (!(element->name == "Description" && element->ns->href == RDF_NS)) {
            statements.add(new Statement(subject,
                    new URIRef(RDF_NS + "type"),
                    new URIRef(element->ns->href + element->name)));
        }
    
        // handle attributes
        // skip rdf:about, xml:lang, rdf:parseType
        for (Xml.Attr* attr = element->properties; attr != null; attr = attr->next) {
            if (attr->atype != 0 ||
                    (attr->name == "about" && attr->ns->href == RDF_NS) ||
                    (attr->name == "lang" && attr->ns->href == XML_NS) ||
                    (attr->name == "parseType" && attr->ns->href == RDF_NS))
                continue;
            parse_property_attribute(subject, attr);
        }
        
        // handle child elements
        for (Xml.Node* child = element->children; child != null; child = child->next) {
            if (child->type != Xml.ElementType.ELEMENT_NODE)
                continue;
            parse_property_element(subject, child);
        }
        
        return subject;
    }
    
    private void parse_property_attribute(SubjectNode subject, Xml.Attr* attr) {
        var predicate = new URIRef(attr->ns->href + attr->name);
        Node object;
        if (attr->name == "type" && attr->ns->href == RDF_NS) {
            object = new URIRef(attr->children->content);
        } else {
            var lang = attr->parent->get_lang();
            if (lang != null)
                object = new PlainLiteral.with_lang(attr->children->content, lang);
            else
                object = new PlainLiteral(attr->children->content);
        }
        statements.add(new Statement(subject, predicate, object));
    }
    
    private void parse_property_element(SubjectNode subject, Xml.Node* element) throws ParseError {
        var predicate = new URIRef(element->ns->href + element->name);
        
        // is the object a URI ref? (rdf:resource)
        var object_uri = element->get_ns_prop("resource", RDF_NS);
        if (object_uri != null) {
            var object = new URIRef(object_uri);
            statements.add(new Statement(subject, predicate, object));
            return;
        }
        
        // is it a literal? (no children)
        if (element->child_element_count() == 0) {
            PlainLiteral object;
            var lang = element->get_lang();
            if (lang != null)
                object = new PlainLiteral.with_lang(element->get_content(), lang);
            else
                object = new PlainLiteral(element->get_content());
            statements.add(new Statement(subject, predicate, object));
            return;
        }
        
        // need to recurse
        for (Xml.Node* child = element->children; child != null; child = child->next) {
            if (child->type != Xml.ElementType.ELEMENT_NODE)
                continue;
            var object = parse_node_element(child);
            statements.add(new Statement(subject, predicate, object));            
            break; // ignore any other child elements, not legal anyway
        }
    }
    
    public void insert(Statement statement) {
        if (!has_matching_statement(statement.subject, statement.predicate, statement.object))
            statements.add(statement);
    }
    
    public Gee.List<Statement> get_statements() {
        return statements.read_only_view;
    }
    
    public Gee.List<Statement> find_matching_statements(
            SubjectNode? subject, URIRef? predicate, Node? object) {
        // XXX naive
        var result = new Gee.ArrayList<Statement>((EqualFunc) Statement.equal);
        foreach (var s in statements) {
            if ((subject == null || s.subject.equals(subject)) &&
                    (predicate == null || s.predicate.equals(predicate)) &&
                    (object == null || s.object.equals(object)))
                result.add(s);
        }
        return result;
    }
        
    public bool has_matching_statement(
            SubjectNode? subject, URIRef? predicate, Node? object) {
        // XXX naive
        foreach (var s in statements) {
            if ((subject == null || s.subject.equals(subject)) &&
                    (predicate == null || s.predicate.equals(predicate)) &&
                    (object == null || s.object.equals(object)))
                return true;
        }
        return false;
    }
    
    public void remove_matching_statements(
            SubjectNode? subject, URIRef? predicate, Node? object) {
        var it = statements.iterator();
        while (it.has_next()) {
            it.next();
            var s = it.get();
            if ((subject == null || s.subject.equals(subject)) &&
                    (predicate == null || s.predicate.equals(predicate)) &&
                    (object == null || s.object.equals(object)))
                it.remove();
        }
    }
    
    public Gee.List<Node> find_objects(SubjectNode subject, URIRef predicate) {
        // XXX naive
        var result = new Gee.ArrayList<Node>();
        foreach (var s in statements) {
            if ((subject == null || s.subject.equals(subject)) &&
                    (predicate == null || s.predicate.equals(predicate)))
                result.add(s.object);
        }
        return result;
    }
    
    public Node? find_object(SubjectNode subject, URIRef predicate) {
        foreach (var s in statements) {
            if ((subject == null || s.subject.equals(subject)) &&
                    (predicate == null || s.predicate.equals(predicate)))
                return s.object;
        }
        return null;
    }
    
}

private const string RDF_NS = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
private const string XML_NS = "http://www.w3.org/XML/1998/namespace";

private string resolve_uri(string uri, string base_uri) {
    return new Soup.URI.with_base(new Soup.URI(base_uri), uri).to_string(false);
}

errordomain ParseError {
    UNPARSEABLE_XML,
    EMPTY_XML,
    DOCUMENT_ELEMENT_NOT_FOUND,
    ILLEGAL_RDFXML
}

#if TEST

public void test_property_attributes() {
    var g = new Graph.from_xml("""
            <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
                <rdf:Description rdf:about=""
                    xml:lang="en"
                    xmlns:Iptc4xmpCore="http://iptc.org/std/Iptc4xmpCore/1.0/xmlns/"
                    Iptc4xmpCore:Location="UQ St Lucia">
                </rdf:Description>
            </rdf:RDF>
            """, "http://example.com/");
    assert(g.get_statements().size == 1);
    assert(g.get_statements().contains(new Statement(
            new URIRef("http://example.com/"),
            new URIRef("http://iptc.org/std/Iptc4xmpCore/1.0/xmlns/Location"),
            new PlainLiteral.with_lang("UQ St Lucia", "en"))));
}

public void test_property_attributes_rdf_type() {
    var g = new Graph.from_xml("""
            <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
                <rdf:Description rdf:about=""
                    rdf:type="http://example.com/Class">
                </rdf:Description>
            </rdf:RDF>
            """, "http://example.com/");
    assert(g.get_statements().size == 1);
    assert(g.get_statements().contains(new Statement(
            new URIRef("http://example.com/"),
            new URIRef("http://www.w3.org/1999/02/22-rdf-syntax-ns#type"),
            new URIRef("http://example.com/Class"))));
}

public void test_property_elements() {
    var g = new Graph.from_xml("""
            <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
                <rdf:Description rdf:about="" xmlns:dc="http://purl.org/dc/elements/1.1/">
                    <dc:description xml:lang="en">Some stuff.</dc:description>
                </rdf:Description>
            </rdf:RDF>
            """, "http://example.com/");
    assert(g.get_statements().size == 1);
    assert(g.get_statements().contains(new Statement(
            new URIRef("http://example.com/"),
            new URIRef("http://purl.org/dc/elements/1.1/description"),
            new PlainLiteral.with_lang("Some stuff.", "en"))));
}

public void test_property_elements_inherit_lang() {
    var g = new Graph.from_xml("""
            <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
                <rdf:Description rdf:about=""
                    xmlns:dc="http://purl.org/dc/elements/1.1/"
                    xml:lang="en">
                    <dc:description>Some stuff.</dc:description>
                </rdf:Description>
            </rdf:RDF>
            """, "http://example.com/");
    assert(g.get_statements().size == 1);
    assert(g.get_statements().contains(new Statement(
            new URIRef("http://example.com/"),
            new URIRef("http://purl.org/dc/elements/1.1/description"),
            new PlainLiteral.with_lang("Some stuff.", "en"))));
}

public void test_unicode() {
    var g = new Graph.from_xml("""
            <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
                <rdf:Description rdf:about=""
                    xmlns:dc="http://purl.org/dc/elements/1.1/"
                    xml:lang="ru"
                    dc:title="ночь">
                    <dc:description>день</dc:description>
                </rdf:Description>
            </rdf:RDF>""", "http://example.com/");
    assert(g.get_statements().size == 2);
    assert(g.get_statements().contains(new Statement(
            new URIRef("http://example.com/"),
            new URIRef("http://purl.org/dc/elements/1.1/title"),
            new PlainLiteral.with_lang("\xd0\xbd\xd0\xbe\xd1\x87\xd1\x8c", "ru"))));
    assert(g.get_statements().contains(new Statement(
            new URIRef("http://example.com/"),
            new URIRef("http://purl.org/dc/elements/1.1/description"),
            new PlainLiteral.with_lang("\xd0\xb4\xd0\xb5\xd0\xbd\xd1\x8c", "ru"))));
}

public void test_find_rdf_root() {
    var g = new Graph.from_xml("""
            <ex:other xmlns:ex="http://some.other.crap/">
                <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
                    <rdf:Description rdf:about=""
                        xmlns:dc="http://purl.org/dc/elements/1.1/"
                        xml:lang="en">
                        <dc:description>Some stuff.</dc:description>
                    </rdf:Description>
                </rdf:RDF>
            </ex:other>
            """, "http://example.com/");
    assert(g.get_statements().size == 1);
    assert(g.get_statements().contains(new Statement(
            new URIRef("http://example.com/"),
            new URIRef("http://purl.org/dc/elements/1.1/description"),
            new PlainLiteral.with_lang("Some stuff.", "en"))));
}

public void test_nested_property_elements() {
    var g = new Graph.from_xml("""
            <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
                <rdf:Description rdf:about=""
                    xmlns:foaf="http://xmlns.com/foaf/0.1/">
                    <foaf:knows>
                        <rdf:Description rdf:about="http://example.com/buddy">
                            <foaf:name>My Buddy</foaf:name>
                        </rdf:Description>
                    </foaf:knows>
                </rdf:Description>
            </rdf:RDF>
            """, "http://example.com/");
    assert(g.get_statements().size == 2);
    assert(g.get_statements().contains(new Statement(
            new URIRef("http://example.com/"),
            new URIRef("http://xmlns.com/foaf/0.1/knows"),
            new URIRef("http://example.com/buddy"))));
    assert(g.get_statements().contains(new Statement(
            new URIRef("http://example.com/buddy"),
            new URIRef("http://xmlns.com/foaf/0.1/name"),
            new PlainLiteral("My Buddy"))));
}

public void test_blank() {
    var g = new Graph.from_xml("""
            <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
                <rdf:Description rdf:about=""
                    xmlns:foaf="http://xmlns.com/foaf/0.1/">
                    <foaf:knows>
                        <rdf:Description>
                            <foaf:name>My Buddy</foaf:name>
                        </rdf:Description>
                    </foaf:knows>
                </rdf:Description>
            </rdf:RDF>
            """, "http://example.com/");
    assert(g.get_statements().size == 2);
    var statements = g.find_matching_statements(
            new URIRef("http://example.com/"),
            new URIRef("http://xmlns.com/foaf/0.1/knows"),
            null);
    assert(statements.size == 1);
    Blank blank;
    {
        Gee.Iterator<Statement> it = statements.iterator();
        it.next();
        blank = (Blank) it.get().object;
    }
    assert(g.find_matching_statements(
            blank,
            new URIRef("http://xmlns.com/foaf/0.1/name"),
            new PlainLiteral("My Buddy")).size == 1);
}

public void test_typed_node_element() {
    var g = new Graph.from_xml("""
            <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
                <foaf:Person rdf:about=""
                    xmlns:foaf="http://xmlns.com/foaf/0.1/">
                    <foaf:name>Person</foaf:name>
                </foaf:Person>
            </rdf:RDF>
            """, "http://example.com/");
    assert(g.get_statements().size == 2);
    assert(g.find_matching_statements(
            new URIRef("http://example.com/"),
            new URIRef("http://www.w3.org/1999/02/22-rdf-syntax-ns#type"),
            new URIRef("http://xmlns.com/foaf/0.1/Person")).size == 1);
    assert(g.find_matching_statements(
            new URIRef("http://example.com/"),
            new URIRef("http://xmlns.com/foaf/0.1/name"),
            new PlainLiteral("Person")).size == 1);
}

public void register_tests() {
    Test.add_func("/xmpedit/rdf/test_property_attributes", test_property_attributes);
    Test.add_func("/xmpedit/rdf/test_property_attributes_rdf_type", test_property_attributes_rdf_type);
    Test.add_func("/xmpedit/rdf/test_property_elements", test_property_elements);
    Test.add_func("/xmpedit/rdf/test_property_elements_inherit_lang", test_property_elements_inherit_lang);
    Test.add_func("/xmpedit/rdf/test_unicode", test_unicode);
    Test.add_func("/xmpedit/rdf/test_find_rdf_root", test_find_rdf_root);
    Test.add_func("/xmpedit/rdf/test_nested_property_elements", test_nested_property_elements);
    Test.add_func("/xmpedit/rdf/test_blank", test_blank);
    Test.add_func("/xmpedit/rdf/test_typed_node_element", test_typed_node_element);
}

#endif

}
