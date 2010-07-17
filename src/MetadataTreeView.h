
#ifndef METADATATREEVIEW_H_
#define METADATATREEVIEW_H_

#include <gtkmm/treeview.h>
#include <gtkmm/cellrenderertext.h>
#include "MetadataTreeModel.h"

class MetadataTreeView : public Gtk::TreeView {

public:
	MetadataTreeView(Glib::RefPtr<MetadataTreeModel> model);
    virtual ~MetadataTreeView(void);

private:
    Gtk::CellRendererText cell_renderer;
    Gtk::TreeView::Column column;

};

#endif /* METADATATREEVIEW_H_ */
