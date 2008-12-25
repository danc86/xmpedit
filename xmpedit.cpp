
#include <gtkmm/main.h>
#include <glibmm/optioncontext.h>

#include "MainWindow.h"

int main(int argc, char *argv[]) {
    Glib::OptionContext options("PHOTO_FILENAME");
    try {
        Gtk::Main kit(argc, argv, options);
    } catch (Glib::OptionError e) {
        std::cerr << argv[0] << ": option error: " << e.what() << std::endl;
        exit(1);
    }

    if (argc < 2) {
        std::cerr << argv[0] << ": no photo filename supplied" << std::endl;
        exit(2);
    }

    try {
        MainWindow window(argv[1]);
        Gtk::Main::run(window);
    } catch (Exiv2::Error e) {
        std::cerr << argv[0] << ": exiv2 error: " << e.what() << std::endl;
        exit(3);
    }
    return 0;
}
