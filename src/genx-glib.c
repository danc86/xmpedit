/*
 * http://www.djc.id.au/blog/genx-vala
 * Released into the public domain
 */

#include <glib.h>
#include <genx.h>

G_STATIC_ASSERT(sizeof(char) == sizeof(gchar));

genxNamespace genx_writer_declare_namespace(genxWriter w, const char *uri, const char *prefix) {
    genxStatus status;
    genxNamespace retval = genxDeclareNamespace(w, (constUtf8) uri, (constUtf8) prefix, &status);
    g_return_val_if_fail(status == GENX_SUCCESS, NULL);
    return retval;
}

genxElement genx_writer_declare_element(genxWriter w, genxNamespace ns, const char *type) {
    genxStatus status;
    genxElement retval = genxDeclareElement(w, ns, (constUtf8) type, &status);
    g_return_val_if_fail(status == GENX_SUCCESS, NULL);
    return retval;
}

genxAttribute genx_writer_declare_attribute(genxWriter w, genxNamespace ns, const char *name) {
    genxStatus status;
    genxAttribute retval = genxDeclareAttribute(w, ns, (constUtf8) name, &status);
    g_return_val_if_fail(status == GENX_SUCCESS, NULL);
    return retval;
}

static genxStatus _genx_send_gstring(void *userData, constUtf8 s) {
    g_string_append((GString *)userData, (const gchar *)s);
    return GENX_SUCCESS;
}

static genxStatus _genx_sendBounded_gstring(void *userData, constUtf8 start, constUtf8 end) {
    g_string_append_len((GString *)userData, (const gchar *)start, (gssize) (end - start));
    return GENX_SUCCESS;
}

static genxStatus _genx_flush_gstring(void *userData) {
    return GENX_SUCCESS;
}

static genxSender _genx_sender_gstring = {
    _genx_send_gstring,
    _genx_sendBounded_gstring,
    _genx_flush_gstring
};

void genx_writer_start_doc_gstring(genxWriter w, GString *gs) {
    // XXX bad, we should hold a proper ref to gs here
    genxSetUserData(w, (void *)gs);
    genxStatus status = genxStartDocSender(w, &_genx_sender_gstring);
    g_return_if_fail(status == GENX_SUCCESS);
}

void genx_writer_end_document(genxWriter w) {
    genxStatus status = genxEndDocument(w);
    g_return_if_fail(status == GENX_SUCCESS);
}

void genx_writer_comment(genxWriter w, const char *text) {
    genxStatus status = genxComment(w, (constUtf8) text);
    g_return_if_fail(status == GENX_SUCCESS);
}

void genx_writer_pi(genxWriter w, const char *target, const char *text) {
    genxStatus status = genxPI(w, (constUtf8) target, (constUtf8) text);
    g_return_if_fail(status == GENX_SUCCESS);
}

void genx_writer_start_element_literal(genxWriter w, const char *xmlns, const char *type) {
    genxStatus status = genxStartElementLiteral(w, (constUtf8) xmlns, (constUtf8) type);
    g_return_if_fail(status == GENX_SUCCESS);
}

void genx_element_start(genxElement e) {
    genxStatus status = genxStartElement(e);
    g_return_if_fail(status == GENX_SUCCESS);
}

void genx_writer_add_attribute_literal(genxWriter w, const char *xmlns,
        const char *name, const char *value) {
    genxStatus status = genxAddAttributeLiteral(w,
            (constUtf8) xmlns, (constUtf8) name, (constUtf8) value);
    g_return_if_fail(status == GENX_SUCCESS);
}

void genx_attribute_add(genxAttribute a, const char *value) {
    genxStatus status = genxAddAttribute(a, (constUtf8) value);
    g_return_if_fail(status == GENX_SUCCESS);
}

void genx_namespace_add(genxNamespace ns, char *prefix) {
    genxStatus status = genxAddNamespace(ns, (utf8) prefix);
    g_return_if_fail(status == GENX_SUCCESS);
}

void genx_writer_unset_default_namespace(genxWriter w) {
    genxStatus status = genxUnsetDefaultNamespace(w);
    g_return_if_fail(status == GENX_SUCCESS);
}

void genx_writer_end_element(genxWriter w) {
    genxStatus status = genxEndElement(w);
    g_return_if_fail(status == GENX_SUCCESS);
}

void genx_writer_add_text(genxWriter w, const char *start) {
    genxStatus status = genxAddText(w, (constUtf8) start);
    g_return_if_fail(status == GENX_SUCCESS);
}

void genx_writer_add_character(genxWriter w, int c) {
    genxStatus status = genxAddCharacter(w, c);
    g_return_if_fail(status == GENX_SUCCESS);
}
