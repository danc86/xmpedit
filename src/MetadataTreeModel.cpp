
#include "MetadataTreeModel.h"

MetadataTreeModel::MetadataTreeModel(const std::vector<boost::shared_ptr<PropertyEditor> >& property_editors) {
    set_column_types(columns);

    for (std::vector<boost::shared_ptr<PropertyEditor> >::const_iterator i = property_editors.begin();
    		i != property_editors.end(); ++ i) {
    	Row row(*append());
        row[columns.markup_column] = (*i)->get_list_markup();
    }
}

MetadataTreeModel::~MetadataTreeModel(void) {
}

Glib::RefPtr<MetadataTreeModel> MetadataTreeModel::create(
		const std::vector<boost::shared_ptr<PropertyEditor> >& property_editors) {
    return Glib::RefPtr<MetadataTreeModel>(new MetadataTreeModel(property_editors));
}
