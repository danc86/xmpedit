
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

}
