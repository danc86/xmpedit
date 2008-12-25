
#include <gtkmm/main.h>

#include "MainWindow.h"

int main(int argc, char *argv[]) {
    Gtk::Main kit(argc, argv);
    MainWindow window("/home/dan/Photos/indro3.jpg");
    Gtk::Main::run(window);
    return 0;
}
