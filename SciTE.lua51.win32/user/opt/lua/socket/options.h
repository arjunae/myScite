#ifndef LSEC_OPTIONS_H
#define LSEC_OPTIONS_H

/*--------------------------------------------------------------------------
 * LuaSec 0.8
 *
 * Copyright (C) 2006-2019 Bruno Silvestre
 *
 *--------------------------------------------------------------------------*/

#include <openssl/ssl.h>

/* If you need to generate these options again, see options.lua */

/* 
  OpenSSL version: Unknown
*/

struct ssl_option_s {
  const char *name;
  unsigned long code;
};
typedef struct ssl_option_s ssl_option_t;

static ssl_option_t ssl_options[] = {
  {NULL, 0L}
};

#endif

