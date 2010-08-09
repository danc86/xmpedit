
namespace XmpEdit {

public class PropertyEditor : Object {

    public string prop { get; construct; }
    public string value { get; construct; }
    
    public PropertyEditor(string prop, string value) {
        Object(prop: prop, value: value);
    }
    
    public string get_list_markup() {
	    return @"<b>Unknown property ($prop)</b>\n$value";
	}
	
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
        var g = new RDF.Graph.from_xml(xmp, File.new_for_path(path).get_uri());
        foreach (var s in g.get_statements())
            stdout.puts(@"$s\n");
        foreach (var tag in exiv_metadata.get_xmp_tags()) {
            properties.add(new PropertyEditor(tag, exiv_metadata.get_xmp_tag_string(tag)));
        }
        updated();
    }

}

}
