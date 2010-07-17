
#include <giomm/file.h>
#include <exiv2/convert.hpp>
#include "MainWindow.h"

MainWindow::MainWindow(const std::string& path) :
	image(Exiv2::ImageFactory::open(path)),
	table(/* rows */ 2, /* cols */ 2),
    image_preview(Gdk::Pixbuf::create_from_file(path, 320, 320)),
    model(MetadataTreeModel::create(property_editors)),
    tree_view(model) {

    image->readMetadata();
    Exiv2::XmpData data = image->xmpData();
    for (Exiv2::XmpData::iterator i = data.begin(); i != data.end(); ++ i) {
        property_editors.push_back(PropertyEditor::create(*i));
    }

    {
        Glib::RefPtr<Gio::File> file(Gio::File::create_for_path(path));
        set_title(file->get_basename());
    }
    set_default_size(640, 480);
    property_allow_shrink() = true;

    table.attach(image_preview,
    		1, 2, 0, 1,
    		Gtk::FILL | Gtk::EXPAND, Gtk::FILL,
    		10, 10);

    tree_view_scrolled.add(tree_view);
    tree_view_scrolled.set_policy(Gtk::POLICY_NEVER, Gtk::POLICY_AUTOMATIC);
    table.attach(tree_view_scrolled,
    		0, 1, 0, 2,
    		Gtk::FILL, Gtk::FILL | Gtk::EXPAND,
    		0, 0);

    detail_scrolled.set_policy(Gtk::POLICY_NEVER, Gtk::POLICY_AUTOMATIC);
    table.attach(detail_scrolled,
    		1, 2, 1, 2,
    		Gtk::FILL | Gtk::EXPAND, Gtk::FILL | Gtk::EXPAND,
    		0, 0);

    add(table);
    show_all_children();

}

MainWindow::~MainWindow() {
}
