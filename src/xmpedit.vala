
namespace XmpEdit {

#if TEST

public int main(string[] args) {
    Test.init(ref args);
    RDF.register_tests();
    Test.run();
    return 0;
}

#else

public int main (string[] args) {
    Gtk.init_with_args(ref args, "PHOTO_FILENAME", { }, /* translation_domain */ null);
    if (args.length < 2) {
        stderr.puts("xmpedit: no photo filename supplied\n");
        return 2;
    }
    var path = args[1];
    MainWindow main_window = new MainWindow(path);
    main_window.destroy.connect(Gtk.main_quit);
    main_window.show_all();
    Gtk.main();
    return 0;
}

#endif

}
