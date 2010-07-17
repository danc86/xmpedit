
#include "PropertyEditor.h"

class UnrecognisedPropertyEditor : public PropertyEditor {

private:
	Exiv2::Xmpdatum& xmp_property;

public:
	UnrecognisedPropertyEditor(Exiv2::Xmpdatum& xmp_property) :
		xmp_property(xmp_property) {
	}

	virtual ~UnrecognisedPropertyEditor(void) {
	}

	virtual Glib::ustring get_list_markup(void) const {
        Glib::ustring markup("<b>Unknown property (");
        markup += xmp_property.groupName();
        markup += ":";
        markup += xmp_property.tagName();
        markup += ")</b>\n";
        markup += xmp_property.value().toString(); // XXX escape
        return markup;
	}
};

boost::shared_ptr<PropertyEditor> PropertyEditor::create(Exiv2::Xmpdatum& xmp_property) {
	return boost::shared_ptr<PropertyEditor>(new UnrecognisedPropertyEditor(xmp_property));
}
