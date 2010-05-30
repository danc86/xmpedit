
#include "MetadataTreeView.h"

MetadataTreeView::MetadataTreeView(Glib::RefPtr<MetadataTreeModel> model) :
	column("Image properties") {
	set_model(model);
	column.pack_start(cell_renderer, true);
	column.add_attribute(cell_renderer.property_markup(), model->columns.markup_column);
	append_column(column);
}

MetadataTreeView::~MetadataTreeView(void) {
}
