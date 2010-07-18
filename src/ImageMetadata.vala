
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

    private GExiv2.Metadata exiv_metadata;
    public string path { get; construct; }
    public Gee.List<PropertyEditor> properties { get; construct; }
    
    public signal void updated();
    
    public ImageMetadata(string path) {
        Object(path: path);
    }
    
    construct {
        properties = new Gee.LinkedList<PropertyEditor>();
        exiv_metadata = new GExiv2.Metadata();
    }
    
    // ugh, for exceptions
    public void load() throws GLib.Error {
        exiv_metadata.open_path(path);
        foreach (var tag in exiv_metadata.get_xmp_tags()) {
            properties.add(new PropertyEditor(tag, exiv_metadata.get_xmp_tag_string(tag)));
        }
        updated();
    }

}

}
