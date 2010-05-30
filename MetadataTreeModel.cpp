
#include "MetadataTreeModel.h"
#include <exiv2/convert.hpp>

MetadataTreeModel::MetadataTreeModel(const std::string& path) {
    set_column_types(columns);

    Exiv2::Image::AutoPtr image(Exiv2::ImageFactory::open(path));
    image->readMetadata();
    Exiv2::XmpData data = image->xmpData();

    for (Exiv2::XmpData::const_iterator i = data.begin(); i != data.end(); ++ i) {
        Row row(*append());
        Glib::ustring markup("<b>Unknown property (");
        markup += i->groupName();
        markup += ":";
        markup += i->tagName();
        markup += ")</b>\n";
        markup += i->value().toString(); // XXX escape
        row[columns.markup_column] = markup;
    }
}

MetadataTreeModel::~MetadataTreeModel(void) {
}

Glib::RefPtr<MetadataTreeModel> MetadataTreeModel::create(const std::string& path) {
    return Glib::RefPtr<MetadataTreeModel>(new MetadataTreeModel(path));
}
