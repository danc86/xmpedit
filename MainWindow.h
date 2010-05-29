
#ifndef MAINWINDOW_H_
#define MAINWINDOW_H_

#include "MetadataTreeModel.h"
#include <gtkmm/treeview.h>
#include <gtkmm/scrolledwindow.h>
#include <gtkmm/box.h>
#include <gtkmm/window.h>

class MainWindow : public Gtk::Window {

public:
	MainWindow(const std::string& path);
	virtual ~MainWindow();

private:
	Gtk::VBox vbox;
	Gtk::Image image_preview;
    Gtk::ScrolledWindow scrolled;
	Glib::RefPtr<MetadataTreeModel> model;
	Gtk::TreeView tree_view;

};

#endif /* MAINWINDOW_H_ */
