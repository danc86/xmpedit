/*
 * xmpedit
 * Copyright 2010 Dan Callaghan <djc@djc.id.au>
 * Released under GPLv2
 */

#include <exiv2/image.hpp>
#include "exiv2-glib.h"

G_DEFINE_TYPE (Exiv2Image, exiv2_image, G_TYPE_OBJECT)

#define GET_PRIVATE(o) \
  (G_TYPE_INSTANCE_GET_PRIVATE ((o), EXIV2_TYPE_IMAGE, Exiv2ImagePrivate))
  
typedef struct {
    Exiv2::Image *image;
} Exiv2ImagePrivate;

static void exiv2_image_get_property(GObject *object, guint property_id,
        GValue *value, GParamSpec *pspec) {
    switch (property_id) {
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
    }
}

static void exiv2_image_set_property(GObject *object, guint property_id,
        const GValue *value, GParamSpec *pspec) {
    switch (property_id) {
        default:
            G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
    }
}

static void exiv2_image_dispose(GObject *object) {
    G_OBJECT_CLASS(exiv2_image_parent_class)->dispose(object);
}

static void exiv2_image_finalize(GObject *object) {
    G_OBJECT_CLASS(exiv2_image_parent_class)->finalize(object);
    // XXX maybe this should be in dispose instead??
    g_return_if_fail(object != NULL);
    Exiv2ImagePrivate *priv = GET_PRIVATE(object);
    g_return_if_fail(priv->image != NULL);
    delete priv->image;
}

static void exiv2_image_class_init(Exiv2ImageClass *klass) {
    GObjectClass *object_class = G_OBJECT_CLASS(klass);

    g_type_class_add_private(klass, sizeof(Exiv2ImagePrivate));

    object_class->get_property = exiv2_image_get_property;
    object_class->set_property = exiv2_image_set_property;
    object_class->dispose = exiv2_image_dispose;
    object_class->finalize = exiv2_image_finalize;
}

static void exiv2_image_init(Exiv2Image *self) {
}

Exiv2Image *exiv2_image_new_from_path(gchar *path) {
    g_return_val_if_fail(path != NULL, NULL);
    Exiv2Image *self = (Exiv2Image *)g_object_new(EXIV2_TYPE_IMAGE, NULL);
    g_return_val_if_fail(self != NULL, NULL);
    Exiv2ImagePrivate *priv = GET_PRIVATE(self);
    try {
        priv->image = Exiv2::ImageFactory::open(path).release();
    } catch (Exiv2::Error e) {
        g_critical("unhandled"); // XXX
    }
    return self;
}

void exiv2_image_read_metadata(Exiv2Image *self) {
    g_return_if_fail(self != NULL);
    Exiv2ImagePrivate *priv = GET_PRIVATE(self);
    g_return_if_fail(priv->image != NULL);
    try {
        priv->image->readMetadata();
    } catch (Exiv2::Error e) {
        g_critical("unhandled"); // XXX
    }
}

void exiv2_image_write_metadata(Exiv2Image *self) {
    g_return_if_fail(self != NULL);
    Exiv2ImagePrivate *priv = GET_PRIVATE(self);
    g_return_if_fail(priv->image != NULL);
    try {
        priv->image->writeMetadata();
    } catch (Exiv2::Error e) {
        g_critical("unhandled"); // XXX
    }
}

const gchar *exiv2_image_get_xmp_packet(Exiv2Image *self) {
    g_return_val_if_fail(self != NULL, NULL);
    Exiv2ImagePrivate *priv = GET_PRIVATE(self);
    g_return_val_if_fail(priv->image != NULL, NULL);
    try {
        const std::string& xmp_packet = priv->image->xmpPacket();
        if (!xmp_packet.empty())
            return xmp_packet.c_str();
    } catch (Exiv2::Error e) {
        g_critical("unhandled"); // XXX
    }
    return NULL;
}

void exiv2_image_set_xmp_packet(Exiv2Image *self, const gchar *xmp_packet) {
    g_return_if_fail(self != NULL);
    Exiv2ImagePrivate *priv = GET_PRIVATE(self);
    g_return_if_fail(priv->image != NULL);
    try {
        priv->image->setXmpPacket(xmp_packet);
    } catch (Exiv2::Error e) {
        g_critical("unhandled"); // XXX
    }
}
