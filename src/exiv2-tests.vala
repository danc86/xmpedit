/*
 * xmpedit
 * Copyright 2010 Dan Callaghan <djc@djc.id.au>
 * Released under GPLv2
 */

#if TEST

namespace Exiv2 {

namespace Tests {

public void test_load_xmp() {
    var image = new Image.from_path("testdata/24-06-06_1449.jpg");
    image.read_metadata();
    assert(Checksum.compute_for_string(ChecksumType.SHA1, image.xmp_packet)
            == "fb357e9a9e9fb5f4481234d2f8f5e59275fc07af");
}

public void register_tests() {
    Test.add_func("/exiv2/test_load_xmp", test_load_xmp);
}

}

}

#endif
