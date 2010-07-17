
#ifndef PROPERTYEDITOR_H_
#define PROPERTYEDITOR_H_

#include <boost/shared_ptr.hpp>
#include <glibmm/ustring.h>
#include <exiv2/xmp.hpp>

class PropertyEditor {

public:
    virtual ~PropertyEditor(void) {
    }

    virtual Glib::ustring get_list_markup(void) const = 0;

    static boost::shared_ptr<PropertyEditor> create(Exiv2::Xmpdatum& xmp_property);

};

#endif /* PROPERTYEDITOR_H_ */
