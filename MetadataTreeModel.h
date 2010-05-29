
#ifndef METADATATREEMODEL_H_
#define METADATATREEMODEL_H_

#include <string>
#include <gtkmm/liststore.h>
#include <exiv2/image.hpp>

class MetadataTreeModel : public Gtk::ListStore {

public:
    MetadataTreeModel(const std::string& path);
    virtual ~MetadataTreeModel(void);
    static Glib::RefPtr<MetadataTreeModel> create(const std::string& path);

private:
    struct ModelColumns : public Gtk::TreeModel::ColumnRecord {
        Gtk::TreeModelColumn<Glib::ustring> pred_column;
        Gtk::TreeModelColumn<Glib::ustring> value_column;
        ModelColumns(void) {
            add(pred_column);
            add(value_column);
        }
    };

public:
    ModelColumns columns;

};

#endif /* METADATATREEMODEL_H_ */
