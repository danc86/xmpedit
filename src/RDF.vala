
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
        Parser(this, base_uri).parse(xml);
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

#if TEST

public void register_tests() {
    register_parser_tests();
}

#endif

}
