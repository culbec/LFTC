#ifndef LEXER_H
#define LEXER_H

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include "hashtable.h"

typedef struct
{
    uint32_t line;
    char *message;
} Exception;

typedef struct
{
    int keyword_id;
    const char *keyword;
    int ts_pos;
} FIP_Entry;

typedef struct
{
    int id;
    const char *name;
} TS_Entry;

typedef struct
{
    ht *TS_ID;
    ht *TS_CONST;
    FIP_Entry *FIP;
    Exception *exceptions;
} Analyzer;

extern Analyzer *analyzer;
extern bool hasErrors;
extern bool lastTokenWasSeparator;
extern int ts_id;
extern int ts_const;
extern int ts_pos;
extern int fip_pos;
extern int exceptions_pos;
extern uint32_t currLine;

void add_TS_ID(Analyzer *analyzer, const char *name, int *ts_id);

void add_TS_CONST(Analyzer *analyzer, const char *name, int *ts_const);

void add_FIP_Entry(Analyzer *analyzer, int keyword_id, const char *keyword, int *ts_pos);

void add_Exception(Analyzer *analyzer, uint32_t line, char *message);

void write_TS_ID(Analyzer *analyzer);

void write_TS_CONST(Analyzer *analyzer);

void write_FIP(Analyzer *analyzer);

void write_Exceptions(Analyzer *analyzer);

void init(Analyzer *analyzer);

void destroy(Analyzer *analyzer);

#endif // LEXER_H