
#include <giomm/file.h>
#include "MainWindow.h"

MainWindow::MainWindow(const std::string& path) :
    image_preview(Gdk::Pixbuf::create_from_file(path, 320, 320)),
    model(MetadataTreeModel::create(path)) {

    {
        Glib::RefPtr<Gio::File> file(Gio::File::create_for_path(path));
        set_title(file->get_basename());
    }

    add(vbox);

    vbox.pack_start(image_preview, Gtk::PACK_SHRINK, 10);

    tree_view.set_model(model);
    tree_view.append_column("Predicate", model->columns.pred_column);
    tree_view.append_column("Value", model->columns.value_column);
    scrolled.add(tree_view);
    scrolled.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_AUTOMATIC);
    vbox.pack_start(scrolled, Gtk::PACK_EXPAND_WIDGET);

    show_all_children();

}

MainWindow::~MainWindow() {
}
