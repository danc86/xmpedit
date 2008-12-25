
#include <giomm/file.h>
#include "MainWindow.h"

MainWindow::MainWindow(const std::string& path) :
	model(MetadataTreeModel::create(path)) {

    {
        Glib::RefPtr<Gio::File> file(Gio::File::create_for_path(path));
        set_title(file->get_basename());
    }

	tree_view.set_model(model);
	tree_view.append_column("Predicate", model->columns.pred_column);
	tree_view.append_column("Value", model->columns.value_column);
	add(tree_view);

	show_all_children();

}

MainWindow::~MainWindow() {
}
