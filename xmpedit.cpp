
#include <gtkmm/main.h>
#include <glibmm/optioncontext.h>

#include "MainWindow.h"

int main(int argc, char *argv[]) {
    try {
        Glib::OptionContext options("PHOTO_FILENAME");
        Gtk::Main kit(argc, argv, options);
        if (argc < 2) {
            std::cerr << argv[0] << ": no photo filename supplied" << std::endl;
            exit(2);
        }
        MainWindow window(argv[1]);
        Gtk::Main::run(window);
        return 0;
    } catch (Glib::OptionError e) {
        std::cerr << argv[0] << ": option error: " << e.what() << std::endl;
        exit(1);
    } catch (Exiv2::Error e) {
        std::cerr << argv[0] << ": exiv2 error: " << e.what() << std::endl;
        exit(3);
    }
}
