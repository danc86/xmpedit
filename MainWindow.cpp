
#include "MainWindow.h"

MainWindow::MainWindow(const std::string& path) :
	model(MetadataTreeModel::create(path)) {

	set_title("XMPEdit");
	set_border_width(5);

	tree_view.set_model(model);
	tree_view.append_column("Predicate", model->columns.pred_column);
	tree_view.append_column("Value", model->columns.value_column);
	add(tree_view);

	show_all_children();

}

MainWindow::~MainWindow() {
}
