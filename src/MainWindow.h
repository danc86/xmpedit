
#ifndef MAINWINDOW_H_
#define MAINWINDOW_H_

#include <vector>
#include <exiv2/image.hpp>
#include "PropertyEditor.h"
#include "MetadataTreeModel.h"
#include "MetadataTreeView.h"
#include <gtkmm/treeview.h>
#include <gtkmm/scrolledwindow.h>
#include <gtkmm/table.h>
#include <gtkmm/alignment.h>
#include <gtkmm/window.h>

class MainWindow : public Gtk::Window {

public:
    MainWindow(const std::string& path);
    virtual ~MainWindow();

private:
    Exiv2::Image::AutoPtr image;
    std::vector<boost::shared_ptr<PropertyEditor> > property_editors;
    Gtk::Table table;
    Gtk::Image image_preview;
    Gtk::ScrolledWindow tree_view_scrolled;
    Glib::RefPtr<MetadataTreeModel> model;
    MetadataTreeView tree_view;
    Gtk::ScrolledWindow detail_scrolled;

};

#endif /* MAINWINDOW_H_ */
