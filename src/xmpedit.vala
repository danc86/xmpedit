
namespace XmpEdit {

public static int main (string[] args) {
    //Glib::OptionContext options("PHOTO_FILENAME");
    //Gtk::Main kit(argc, argv, options);
    //if (argc < 2) {
    //    std::cerr << argv[0] << ": no photo filename supplied" << std::endl;
    //    exit(2);
    //}
    Gtk.init(ref args);
    MainWindow main_window = new MainWindow("test.jpg");
    main_window.destroy.connect(Gtk.main_quit);
    main_window.show_all();
    Gtk.main();
    return 0;
}

}
