// TODO use vala-gen-introspect

[CCode (cheader_filename = "exiv2-glib.h")]
namespace Exiv2 {

    [CCode (ref_function = "g_object_ref", unref_function = "g_object_unref")]
    public class Image {
    
        public Image.from_path(string path);
        
        public string? xmp_packet { get; set; }
        
        public void read_metadata();
        public void write_metadata();
    
    }
    
}
