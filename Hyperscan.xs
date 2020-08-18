#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "hs.h"

#include "const-c.inc"

typedef hs_database_t* Hyperscan__Database;
typedef hs_scratch_t* Hyperscan__Scratch;
typedef hs_stream_t* Hyperscan__Stream;

static
int
push_matches_to_stack(unsigned int id, unsigned long long from, unsigned long long to, unsigned int flags, void *context)
{
    dTHXR;
    dSP;
    mXPUSHi(id);
    PUTBACK;
    return 0;
}

MODULE = Hyperscan  PACKAGE = Hyperscan

INCLUDE: const-xs.inc

MODULE = Hyperscan  PACKAGE = Hyperscan::Database
PROTOTYPES: ENABLED

size_t
size(Hyperscan::Database self)
    PREINIT:
        size_t database_size;
    CODE:
        if (hs_database_size(self, &database_size) != HS_SUCCESS) {
            croak("failed to get database size");
        }
        RETVAL = database_size;
    OUTPUT: RETVAL

Hyperscan::Database
compile(const char *class, const char *expression, unsigned int flags, unsigned int mode)
    PREINIT:
        hs_database_t *db = NULL;
        hs_compile_error_t *compile_err = NULL;
        SV *msg = NULL;
    CODE:
        if (hs_compile(expression, flags, mode, NULL, &db, &compile_err) != HS_SUCCESS) {
            msg = sv_2mortal(newSVpv(compile_err->message, 0));
            hs_free_compile_error(compile_err);
            croak_sv(msg);
        }
        RETVAL = db;
    OUTPUT: RETVAL

Hyperscan::Database
compile_multi(const char *class, SV *expressions, SV *flags, SV *ids, unsigned int mode)
    PREINIT:
        int i;
        unsigned int elements;
        hs_database_t *db = NULL;
        hs_compile_error_t *compile_err = NULL;
        SV *msg = NULL;
        AV *expr_arr = NULL, *flag_arr = NULL, *id_arr = NULL;
        const char **expression_values = NULL;
        unsigned int *flag_values = NULL;
        unsigned int *id_values;
        SV **tmp = NULL;
        hs_error_t err;
    CODE:
        if (!SvROK(expressions) || SvTYPE(SvRV(expressions)) != SVt_PVAV) {
            croak("expressions must be an array ref");
        }
        if (!SvROK(flags) || SvTYPE(SvRV(flags)) != SVt_PVAV) {
            croak("flags must be an array ref");
        }
        if (!SvROK(ids) || SvTYPE(SvRV(ids)) != SVt_PVAV) {
            croak("ids must be an array ref");
        }
        expr_arr = (AV*)SvRV(expressions);
        elements = av_top_index(expr_arr) + 1;
        if (elements == -1) {
            croak("expressions must not be empty");
        }

        flag_arr = (AV*)SvRV(flags);
        if (elements != av_top_index(flag_arr) + 1) {
            croak("flags must have same number of elements as expressions");
        }

        id_arr = (AV*)SvRV(ids);
        if (elements != av_top_index(id_arr) + 1) {
            croak("ids must have same number of elements as expressions");
        }

        expression_values = malloc((elements+1) * sizeof(char*));
        for (i = 0; i < elements; i++) {
            tmp = av_fetch(expr_arr, i, 0);
            if (!SvOK(*tmp) || !SvPOK(*tmp)) {
                free(expression_values);
                croak("expressions must be an array of strings");
            }
            expression_values[i] = SvPV_nolen(*tmp);
        }
        expression_values[elements] = NULL;

        flag_values = malloc(elements * sizeof(char*));
        for (i = 0; i < elements; i++) {
            tmp = av_fetch(flag_arr, i, 0);
            if (!SvOK(*tmp) || !SvIOK(*tmp)) {
                free(expression_values);
                free(flag_values);
                croak("flags must be an array of ints");
            }
            flag_values[i] = SvIV(*tmp);
        }

        id_values = malloc(elements * sizeof(char*));
        for (i = 0; i < elements; i++) {
            tmp = av_fetch(id_arr, i, 0);
            if (!SvOK(*tmp) || !SvIOK(*tmp)) {
                free(expression_values);
                free(flag_values);
                free(id_values);
                croak("ids must be an array of ints");
            }
            id_values[i] = SvIV(*tmp);
        }

        err = hs_compile_multi(expression_values, flag_values, id_values, elements, mode, NULL, &db, &compile_err);
        free(expression_values);
        free(flag_values);
        free(id_values);

        if (err != HS_SUCCESS) {
            msg = sv_2mortal(newSVpv(compile_err->message, 0));
            hs_free_compile_error(compile_err);
            croak_sv(msg);
        }

        RETVAL = db;
    OUTPUT: RETVAL

Hyperscan::Database
compile_lit(const char *class, SV *expression, unsigned flags, unsigned mode)
    PREINIT:
        STRLEN len;
        char *raw = NULL;
        hs_database_t *db = NULL;
        hs_compile_error_t *compile_err = NULL;
        SV *msg = NULL;
    CODE:
        if (!SvOK(expression) || !SvPOK(expression)) {
            croak("expression must be a string");
        }
        raw = SvPV(expression, len);
        if (hs_compile_lit(raw, flags, len, mode, NULL, &db, &compile_err) != HS_SUCCESS) {
            msg = sv_2mortal(newSVpv(compile_err->message, 0));
            hs_free_compile_error(compile_err);
            croak_sv(msg);
        }
        RETVAL = db;
    OUTPUT: RETVAL

Hyperscan::Stream
open_stream(Hyperscan::Database self, unsigned int flags)
    PREINIT:
        hs_stream_t *stream = NULL;
    CODE:
        if (hs_open_stream(self, flags, &stream) != HS_SUCCESS) {
            croak("error opening stream");
        }
        RETVAL = stream;
    OUTPUT: RETVAL

void
scan(Hyperscan::Database self, SV *data, unsigned int flags, Hyperscan::Scratch scratch)
    PREINIT:
        STRLEN len;
        char *raw = NULL;
        hs_error_t err;
    PPCODE:
        if (!SvOK(data) || !SvPOK(data)) {
            croak("data must be a string");
        }
        raw = SvPV(data, len);
        PUTBACK;
        err = hs_scan(self, raw, len, flags, scratch, push_matches_to_stack, NULL);
        SPAGAIN;
        if (err != HS_SUCCESS) {
            croak("scanning failed");
        }

Hyperscan::Scratch
alloc_scratch(Hyperscan::Database self)
    PREINIT:
        hs_scratch_t *scratch = NULL;
    CODE:
        if (hs_alloc_scratch(self, &scratch) != HS_SUCCESS) {
            croak("error allocating scratch");
        }
        RETVAL = scratch;
    OUTPUT: RETVAL

void
DESTROY(Hyperscan::Database self)
    CODE:
        if (hs_free_database(self) != HS_SUCCESS) {
            croak("freeing database failed");
        }

MODULE = Hyperscan  PACKAGE = Hyperscan::Scratch

void
DESTROY(Hyperscan::Scratch self)
    CODE:
        if (hs_free_scratch(self) != HS_SUCCESS) {
            croak("freeing scratch failed");
        }

MODULE = Hyperscan  PACKAGE = Hyperscan::Stream

void
close(Hyperscan::Stream self, Hyperscan::Scratch scratch)
    PREINIT:
        hs_error_t err;
    PPCODE:
        PUTBACK;
        err = hs_close_stream(self, scratch, push_matches_to_stack, NULL);
        SPAGAIN;
        if (err != HS_SUCCESS) {
            croak("scanning failed");
        }

void
reset(Hyperscan::Stream self)
    CODE:
        if (hs_reset_stream(self, 0, NULL, NULL, NULL) != HS_SUCCESS) {
            croak("error reseting stream");
        }

void
DESTROY(Hyperscan::Stream self)
    CODE:
        if (hs_close_stream(self, NULL, NULL, NULL) != HS_SUCCESS) {
            croak("error closing stream");
        }
