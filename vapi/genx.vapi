[CCode (cheader_filename = "genx.h")]
namespace Genx {

    [CCode (cname = "genxStatus", cprefix = "GENX_")]
    public enum Status {
        SUCCESS,
        BAD_UTF8,
        NON_XML_CHARACTER,
        BAD_NAME,
        ALLOC_FAILED,
        BAD_NAMESPACE_NAME,
        INTERNAL_ERROR,
        DUPLICATE_PREFIX,
        SEQUENCE_ERROR,
        NO_START_TAG,
        IO_ERROR,
        MISSING_VALUE,
        MALFORMED_COMMENT,
        XML_PI_TARGET,
        MALFORMED_PI,
        DUPLICATE_ATTRIBUTE,
        ATTRIBUTE_IN_DEFAULT_NAMESPACE,
        DUPLICATE_NAMESPACE,
        BAD_DEFAULT_DECLARATION
    }
    
    [Compact]
    [CCode (cname = "struct genxWriter_rec", free_function = "genxDispose")]
    public class Writer {
    
        [CCode (has_target = 0)]
        public delegate void* AllocCallback(void* user_data, int bytes);
        [CCode (has_target = 0)]
        public delegate void DeallocCallback(void* user_data, void* data);
        
        [CCode (cname = "_genx_default_alloc")]
        private static void* default_alloc(void* user_data, int bytes) {
            return GLib.malloc(bytes);
        }
        [CCode (cname = "_genx_default_dealloc")]
        private static void default_dealloc(void* user_data, void* data) {
            GLib.free(data);
        }
        
        [CCode (cname = "genxNew")]
        public Writer(
                AllocCallback alloc = default_alloc,
                DeallocCallback dealloc = default_dealloc,
                void* user_data = null);
        
        [CCode (cname = "genxDeclareNamespace")]
        public unowned Namespace declare_namespace(string uri, string prefix, out Status status);
        
        [CCode (cname = "genxDeclareElement")]
        public unowned Element declare_element(Namespace ns, string type, out Status status);
        
        [CCode (cname = "genxDeclareAttribute")]
        public unowned Attribute declare_attribute(Namespace ns, string name, out Status status);
        
        [CCode (cname = "_genx_start_doc_gstring")]
        public Status start_doc(GLib.StringBuilder output);
        
        [CCode (cname = "genxEndDocument")]
        public Status end_doc();
        
        [CCode (cname = "genxComment")]
        public Status comment(string text);
        
        [CCode (cname = "genxPI")]
        public Status pi(string target, string text);
        
        [CCode (cname = "genxStartElementLiteral")]
        public Status start_element_literal(string xmlns, string type);
        
        [CCode (cname = "genxAddAttributeLiteral")]
        public Status add_attribute_literal(string xmlns, string name, string value);
        
        [CCode (cname = "genxUnsetDefaultNamespace")]
        public Status unset_default_namespace();
        
        [CCode (cname = "genxEndElement")]
        public Status end_element();
        
        [CCode (cname = "genxAddText")]
        public Status add_text(string text);
        
        [CCode (cname = "genxAddCharacter")]
        public Status add_character(int character);
    
    }
    
    [Compact]
    [CCode (cname = "struct genxNamespace_rec", free_function = "NAMESPACE_HAS_NO_PUBLIC_FREE")]
    public class Namespace {
    
        [CCode (cname = "genxAddNamespace")]
        public Status add(string? prefix = null);
    
    }
    
    [Compact]
    [CCode (cname = "struct genxElement_rec", free_function = "ELEMENT_HAS_NO_PUBLIC_FREE")]
    public class Element {
    
        [CCode (cname = "genxStartElement")]
        public Status start();
    
    }
        
    [Compact]
    [CCode (cname = "struct genxAttribute_rec", free_function = "ATTRIBUTE_HAS_NO_PUBLIC_FREE")]
    public class Attribute {
    
        [CCode (cname = "genxAddAttribute")]
        public Status add(string value);
    
    }

}
