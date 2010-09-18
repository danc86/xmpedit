/*
 * xmpedit
 * Copyright 2010 Dan Callaghan <djc@djc.id.au>
 * Released under GPLv2
 */

#include <iostream>
#include <exiv2/image.hpp>

/** Simplest possible utility to extract raw XMP packet from a file. */
int main(int argc, char *argv[]) {
    if (argc != 2)
        return 1;
    const std::string path(argv[1]);
    std::auto_ptr<Exiv2::Image> image(Exiv2::ImageFactory::open(path));
    image->readMetadata();
    std::cout << image->xmpPacket();
    return 0;
}
