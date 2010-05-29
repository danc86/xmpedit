
#include "MetadataTreeModel.h"
#include <exiv2/convert.hpp>

MetadataTreeModel::MetadataTreeModel(const std::string& path) {
    set_column_types(columns);

    Exiv2::Image::AutoPtr image(Exiv2::ImageFactory::open(path));
    image->readMetadata();
    Exiv2::XmpData data = image->xmpData();

    for (Exiv2::XmpData::const_iterator i = data.begin(); i != data.end(); ++ i) {
        Row row(*append());
        Glib::ustring pred(i->groupName());
        pred += ":";
        pred += i->tagName();
        row[columns.pred_column] = pred;
        Glib::ustring value(i->value().toString());
        value += " [";
        value += i->typeName();
        value += "]";
        row[columns.value_column] = value;
    }
}

MetadataTreeModel::~MetadataTreeModel(void) {
}

Glib::RefPtr<MetadataTreeModel> MetadataTreeModel::create(const std::string& path) {
    return Glib::RefPtr<MetadataTreeModel>(new MetadataTreeModel(path));
}
