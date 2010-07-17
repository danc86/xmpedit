
#ifndef METADATATREEMODEL_H_
#define METADATATREEMODEL_H_

#include <vector>
#include <gtkmm/liststore.h>
#include "PropertyEditor.h"

class MetadataTreeModel : public Gtk::ListStore {

private:
	MetadataTreeModel(const std::vector<boost::shared_ptr<PropertyEditor> >& property_editors);

public:
    virtual ~MetadataTreeModel(void);
    static Glib::RefPtr<MetadataTreeModel> create(const std::vector<boost::shared_ptr<PropertyEditor> >& property_editors);

private:
    struct ModelColumns : public Gtk::TreeModel::ColumnRecord {
        Gtk::TreeModelColumn<Glib::ustring> markup_column; // XXX lame?
        ModelColumns(void) {
            add(markup_column);
        }
    };

public:
    ModelColumns columns;

};

#endif /* METADATATREEMODEL_H_ */
