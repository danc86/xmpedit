/*
 * http://www.djc.id.au/blog/genx-vala
 * Released into the public domain
 */

#ifndef _GENX_GLIB_H
#define _GENX_GLIB_H

#include <genx.h>

typedef struct genxWriter_rec genxWriter_rec;

genxNamespace genx_writer_declare_namespace(genxWriter w, const char *uri, const char *prefix);
genxElement genx_writer_declare_element(genxWriter w, genxNamespace ns, const char *type);
genxAttribute genx_writer_declare_attribute(genxWriter w, genxNamespace ns, const char *name);
void genx_writer_start_doc_gstring(genxWriter w, GString *gs);
void genx_writer_end_document(genxWriter w);
void genx_writer_comment(genxWriter w, const char *text);
void genx_writer_pi(genxWriter w, const char *target, const char *text);
void genx_writer_start_element_literal(genxWriter w, const char *xmlns, const char *type);
void genx_element_start(genxElement e);
void genx_writer_add_attribute_literal(genxWriter w, const char *xmlns,
        const char *name, const char *value);
void genx_attribute_add(genxAttribute a, const char *value);
void genx_namespace_add(genxNamespace ns, char *prefix);
void genx_writer_end_element(genxWriter w);
void genx_writer_add_text(genxWriter w, const char *start);
void genx_writer_add_character(genxWriter w, int c);

#endif /* inclusion guard */
