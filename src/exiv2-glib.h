/*
 * xmpedit
 * Copyright 2010 Dan Callaghan <djc@djc.id.au>
 * Released under GPLv2
 */

#ifndef _EXIV2_GLIB
#define _EXIV2_GLIB

#include <glib-object.h>

G_BEGIN_DECLS

#define EXIV2_TYPE_IMAGE exiv2_image_get_type()

#define EXIV2_IMAGE(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST ((obj), EXIV2_TYPE_IMAGE, Exiv2Image))

#define EXIV2_IMAGE_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_CAST ((klass), EXIV2_TYPE_IMAGE, Exiv2ImageClass))

#define EXIV2_IS_IMAGE(obj) \
  (G_TYPE_CHECK_INSTANCE_TYPE ((obj), EXIV2_TYPE_IMAGE))

#define EXIV2_IS_IMAGE_CLASS(klass) \
  (G_TYPE_CHECK_CLASS_TYPE ((klass), EXIV2_TYPE_IMAGE))

#define EXIV2_IMAGE_GET_CLASS(obj) \
  (G_TYPE_INSTANCE_GET_CLASS ((obj), EXIV2_TYPE_IMAGE, Exiv2ImageClass))

typedef struct {
    GObject parent;
} Exiv2Image;

typedef struct {
    GObjectClass parent_class;
} Exiv2ImageClass;

GType exiv2_image_get_type(void);

Exiv2Image *exiv2_image_new_from_path(gchar *path);

void exiv2_image_read_metadata(Exiv2Image *self);
void exiv2_image_write_metadata(Exiv2Image *self);

const gchar *exiv2_image_get_xmp_packet(Exiv2Image *self);
void exiv2_image_set_xmp_packet(Exiv2Image *self, const gchar *xmp_packet);

G_END_DECLS

#endif /* inclusion guard */

