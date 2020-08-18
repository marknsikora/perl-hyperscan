#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "hs.h"

typedef hs_database_t* Hyperscan__Database;
typedef hs_scratch_t* Hyperscan__Scratch;

static
int
increment_context(unsigned int id, unsigned long long from, unsigned long long to, unsigned int flags, void *context)
{
    int *i = (int*) context;
    (*i)++;
    return 0;
}

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

void
scan(Hyperscan::Database self, SV *data, unsigned int flags, Hyperscan::Scratch scratch)
    PREINIT:
        STRLEN len;
        char *raw = NULL;
        int count = 0;
    PPCODE:
        if (!SvOK(data) || !SvPOK(data)) {
            croak("data must be a string");
        }
        raw = SvPV(data, len);
        if (hs_scan(self, raw, len, flags, scratch, increment_context, &count) != HS_SUCCESS) {
            croak("scanning failed");
        }

        mXPUSHi(count);

void
DESTROY(Hyperscan::Database self)
    CODE:
        if (hs_free_database(self) != HS_SUCCESS) {
            croak("freeing database failed");
        }

MODULE = Hyperscan  PACKAGE = Hyperscan::Scratch

Hyperscan::Scratch
new(const char *class, Hyperscan::Database db)
    PREINIT:
        hs_scratch_t *scratch = NULL;
    CODE:
        if (hs_alloc_scratch(db, &scratch) != HS_SUCCESS) {
            croak("error allocating scratch");
        }
        RETVAL = scratch;
    OUTPUT: RETVAL

void
DESTROY(Hyperscan::Scratch self)
    CODE:
        if (hs_free_scratch(self) != HS_SUCCESS) {
            croak("freeing scratch failed");
        }
