
#include "MetadataTreeView.h"

MetadataTreeView::MetadataTreeView(Glib::RefPtr<MetadataTreeModel> model) :
	column("Image properties") {
	set_model(model);
	cell_renderer.property_ellipsize() = Pango::ELLIPSIZE_END;
	column.set_sizing(Gtk::TREE_VIEW_COLUMN_FIXED);
	column.set_fixed_width(300);
	column.pack_start(cell_renderer, true);
	column.add_attribute(cell_renderer.property_markup(), model->columns.markup_column);
	append_column(column);
}

MetadataTreeView::~MetadataTreeView(void) {
}
