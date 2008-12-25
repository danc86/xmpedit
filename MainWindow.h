
#ifndef MAINWINDOW_H_
#define MAINWINDOW_H_

#include "MetadataTreeModel.h"
#include <gtkmm/treeview.h>
#include <gtkmm/scrolledwindow.h>
#include <gtkmm/window.h>

class MainWindow : public Gtk::Window {

public:
	MainWindow(const std::string& path);
	virtual ~MainWindow();

private:
    Gtk::ScrolledWindow scrolled;
	Glib::RefPtr<MetadataTreeModel> model;
	Gtk::TreeView tree_view;

};

#endif /* MAINWINDOW_H_ */
