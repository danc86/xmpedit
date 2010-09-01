
#include <glib.h>
#include <genx.h>

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

genxStatus _genx_start_doc_gstring(genxWriter w, GString *gs) {
    // XXX bad, we should hold a proper ref to gs here
    genxSetUserData(w, (void *)gs);
    genxStartDocSender(w, &_genx_sender_gstring);
}
