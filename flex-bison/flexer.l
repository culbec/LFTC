%{
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include "flexer.h"
#include "bisoner.h"

extern Analyzer *analyzer;
extern bool hasErrors;
extern bool lastTokenWasSeparator;
extern int ts_id;
extern int ts_const;
extern int fip_pos;
extern int exceptions_pos;
extern uint32_t currLine;

void add_TS_ID(Analyzer *analyzer, const char *name, int *ts_id)
{
    int* value = (int*)ht_get(analyzer->TS_ID, name);

    if (value == NULL) {
        TS_Entry *entry = (TS_Entry*)malloc(sizeof(TS_Entry));

        entry->id = *ts_id;
        entry->name = strdup(name);

        ht_set(analyzer->TS_ID, name, entry);
        (*ts_id)++;  // Increment the global counter
    }
}

void add_TS_CONST(Analyzer *analyzer, const char* name, int *ts_const)
{
    int* value = (int*)ht_get(analyzer->TS_CONST, name);

    if (value == NULL) {
        TS_Entry *entry = (TS_Entry*)malloc(sizeof(TS_Entry));

        entry->id = *ts_const;
        entry->name = strdup(name);

        ht_set(analyzer->TS_CONST, name, entry);
        (*ts_const)++;  // Increment the global counter
    }
}

void add_FIP_Entry(Analyzer *analyzer, int keyword_id, const char* keyword, int *ts_pos)
{
    FIP_Entry entry;
    entry.keyword_id = keyword_id;
    entry.keyword = keyword;
    entry.ts_pos = *ts_pos;

    analyzer->FIP[fip_pos++] = entry;
}

void add_Exception(Analyzer *analyzer, uint32_t line, char *message)
{
    Exception ex;
    ex.line = line;
    ex.message = strdup(message);

    analyzer->exceptions[exceptions_pos++] = ex;
}

void write_TS_ID(Analyzer *analyzer) {
    FILE *f = fopen("TS_ID.csv", "w");

    fprintf(f, "ID,Position\n");

    hti iterator = ht_iterator(analyzer->TS_ID);

    while (ht_next(&iterator)) {
        fprintf(f, "%s,%d\n", iterator.key, *(uint32_t*) iterator.value);
    }
    
    fclose(f);
}

void write_TS_CONST(Analyzer *analyzer) {
    FILE *f = fopen("TS_CONST.csv", "w");

    fprintf(f, "CONST,Position\n");

    hti iterator = ht_iterator(analyzer->TS_CONST);

    while (ht_next(&iterator)) {
        fprintf(f, "%s,%d\n", iterator.key, *(uint32_t*) iterator.value);
    }
    
    fclose(f);
}

void write_FIP(Analyzer *analyzer) {
    FILE *f = fopen("FIP.csv", "w");

    fprintf(f, "Keyword ID,Keyword,TS Position\n");

    for (int i = 0; i < fip_pos; i++) {
        fprintf(f, "%d,%s,%d\n", analyzer->FIP[i].keyword_id, analyzer->FIP[i].keyword, analyzer->FIP[i].ts_pos);
    }
    
    fclose(f);
}

void write_Exceptions(Analyzer *analyzer) {
    FILE *f = fopen("exceptions.csv", "w");

    fprintf(f, "Line,Message\n");

    for (int i = 0; i < exceptions_pos; i++) {
        fprintf(f, "%d,%s\n", analyzer->exceptions[i].line, analyzer->exceptions[i].message);
    }
    
    fclose(f);
}

void init(Analyzer *analyzer) {
    analyzer->TS_ID = ht_create();
    analyzer->TS_CONST = ht_create();
    analyzer->FIP = (FIP_Entry*) malloc(1024 * sizeof(FIP_Entry));
    analyzer->exceptions = (Exception*) malloc(1024 * sizeof(Exception));
}

void destroy(Analyzer *analyzer) {
    ht_destroy(analyzer->TS_ID);
    ht_destroy(analyzer->TS_CONST);

    // freeing exceptions
    for (int i = 0; i < exceptions_pos; i++) {
        free(analyzer->exceptions[i].message);
    }

    free(analyzer->FIP);
    free(analyzer->exceptions);
}
%}

%option debug
%option nodefault
%option noyywrap
%option outfile="flexer.c"

DECIMAL_DIGIT               [0-9]
DECIMAL_DIGITS      {DECIMAL_DIGIT}"_"?{DECIMAL_DIGIT}*
DECIMAL_EXPONENT    [eE]("+"|"-")?{DECIMAL_DIGITS}
DECIMAL_LIT         0|[1-9]("_"?{DECIMAL_DIGITS}*)?
DECIMAL_FLOAT_LIT   {DECIMAL_DIGITS}"."{DECIMAL_DIGITS}?{DECIMAL_EXPONENT}?|{DECIMAL_DIGITS}{DECIMAL_EXPONENT}|"."{DECIMAL_DIGITS}{DECIMAL_EXPONENT}?

BINARY_DIGIT        [01]
BINARY_DIGITS       {BINARY_DIGIT}"_"?{BINARY_DIGIT}*
BINARY_LIT          0[bB]"_"?{BINARY_DIGITS}

HEX_DIGIT           [0-9a-fA-F]
HEX_DIGITS          {HEX_DIGIT}"_"?{HEX_DIGIT}*
HEX_MANTISSA        "_"?{HEX_DIGITS}"."{HEX_DIGITS}?|"_"?{HEX_DIGITS}
HEX_EXPONENT        [pP]("+"|"-")?{DECIMAL_DIGITS}
HEX_LIT             0[xX]"_"?{HEX_DIGITS}
HEX_FLOAT_LIT       0[xX]{HEX_MANTISSA}{HEX_EXPONENT}

OCTAL_DIGIT         [0-7]
OCTAL_DIGITS        {OCTAL_DIGIT}"_"?{OCTAL_DIGIT}*
OCTAL_LIT           0"_"?{OCTAL_DIGITS}

LETTER              [a-zA-Z_]

ID                  {LETTER}({LETTER}|{DECIMAL_DIGIT})* 
INT                 {DECIMAL_LIT}|{BINARY_LIT}|{OCTAL_LIT}|{HEX_LIT}
FLOAT               {DECIMAL_FLOAT_LIT}|{HEX_FLOAT_LIT}
STRING              \"({LETTER}|{DECIMAL_DIGIT}|" ")*\"
CONST               {INT}|{FLOAT}|{STRING}
%%

"int" {
    lastTokenWasSeparator = false;
    int keyword_id = 3;
    const char* keyword = "int";

    add_FIP_Entry(analyzer, keyword_id, keyword, &ts_pos);
    return INT;
}

"float" {
    lastTokenWasSeparator = false;
    int keyword_id = 4;
    const char* keyword = "float";

    add_FIP_Entry(analyzer, keyword_id, keyword, &ts_pos);
    return FLOAT;
}

"string" {
    lastTokenWasSeparator = false;
    int keyword_id = 5;
    const char* keyword = "string";

    add_FIP_Entry(analyzer, keyword_id, keyword, &ts_pos);
    return STRING;
}

"struct" {
    lastTokenWasSeparator = false;
    int keyword_id = 6;
    const char* keyword = "struct";

    add_FIP_Entry(analyzer, keyword_id, keyword, &ts_pos);
    return STRUCT;
}

"if" {
    lastTokenWasSeparator = false;
    int keyword_id = 7;
    const char* keyword = "if";

    add_FIP_Entry(analyzer, keyword_id, keyword, &ts_pos);
    return IF;
}

"else" {
    lastTokenWasSeparator = false;
    int keyword_id = 8;
    const char* keyword = "else";

    add_FIP_Entry(analyzer, keyword_id, keyword, &ts_pos);
    return ELSE;
}

"for" {
    lastTokenWasSeparator = false;
    int keyword_id = 9;
    const char* keyword = "for";

    add_FIP_Entry(analyzer, keyword_id, keyword, &ts_pos);
    return FOR;
}

"var" {
    lastTokenWasSeparator = false;
    int keyword_id = 10;
    const char* keyword = "var";

    add_FIP_Entry(analyzer, keyword_id, keyword, &ts_pos);
    return VAR;
}

"func" {
    lastTokenWasSeparator = false;
    int keyword_id = 11;
    const char* keyword = "func";

    add_FIP_Entry(analyzer, keyword_id, keyword, &ts_pos);
    return FUNC;
}

"main" {
    lastTokenWasSeparator = false;
    int keyword_id = 12;
    const char* keyword = "main";
    
    add_FIP_Entry(analyzer, keyword_id, keyword, &ts_pos);
    return MAIN;
}

"fmt.Scan" {
    lastTokenWasSeparator = false;
    int keyword_id = 13;
    const char* keyword = "fmt.Scan";

    add_FIP_Entry(analyzer, keyword_id, keyword, &ts_pos);
    return SCAN;
}

"fmt.Print" {
    lastTokenWasSeparator = false;
    int keyword_id = 14;
    const char* keyword = "fmt.Print";

    add_FIP_Entry(analyzer, keyword_id, keyword, &ts_pos);
    return PRINT;
}

"fmt.Println" {
    lastTokenWasSeparator = false;
    int keyword_id = 15;
    const char* keyword = "fmt.Println";

    add_FIP_Entry(analyzer, keyword_id, keyword, &ts_pos);
    return PRINTLN;
}

"cattimp" {
    lastTokenWasSeparator = false;
    int keyword_id = 16;
    const char* keyword = "cattimp";

    add_FIP_Entry(analyzer, keyword_id, keyword, &ts_pos);
    return CATTIMP;
}

"==" {
    lastTokenWasSeparator = false;
    int keyword_id = 17;
    const char* keyword = "==";

    add_FIP_Entry(analyzer, keyword_id, keyword, &ts_pos);
    return EQ;
}

"!=" {
    lastTokenWasSeparator = false;
    int keyword_id = 18;
    const char* keyword = "!=";

    add_FIP_Entry(analyzer, keyword_id, keyword, &ts_pos);
    return NEQ;
}

"<" {
    lastTokenWasSeparator = false;
    int keyword_id = 19;
    const char* keyword = "<";

    add_FIP_Entry(analyzer, keyword_id, keyword, &ts_pos);
    return LT;
}

"<=" {
    lastTokenWasSeparator = false;
    int keyword_id = 20;
    const char* keyword = "<=";

    add_FIP_Entry(analyzer, keyword_id, keyword, &ts_pos);
    return LTE;
}

">" {
    lastTokenWasSeparator = false;
    int keyword_id = 21;
    const char* keyword = ">";

    add_FIP_Entry(analyzer, keyword_id, keyword, &ts_pos);    
    return GT;
}

">=" {
    lastTokenWasSeparator = false;
    int keyword_id = 22;
    const char* keyword = ">=";

    add_FIP_Entry(analyzer, keyword_id, keyword, &ts_pos);
    return GTE;
}

"=" {
    lastTokenWasSeparator = false;
    int keyword_id = 23;
    const char* keyword = "=";

    add_FIP_Entry(analyzer, keyword_id, keyword, &ts_pos);
    return ASSIGN;
}

":=" {
    lastTokenWasSeparator = false;
    int keyword_id = 24;
    const char* keyword = ":=";

    add_FIP_Entry(analyzer, keyword_id, keyword, &ts_pos);
    return DECLARE;
}

"+" {
    lastTokenWasSeparator = false;
    int keyword_id = 25;
    const char* keyword = "+";

    add_FIP_Entry(analyzer, keyword_id, keyword, &ts_pos);
    return PLUS;
}

"-" {
    lastTokenWasSeparator = false;
    int keyword_id = 26;
    const char* keyword = "-";

    add_FIP_Entry(analyzer, keyword_id, keyword, &ts_pos);
    return MINUS;
}

"*" {
    lastTokenWasSeparator = false;
    int keyword_id = 27;
    const char* keyword = "*";

    add_FIP_Entry(analyzer, keyword_id, keyword, &ts_pos);
    return MUL;
}

"/" {
    lastTokenWasSeparator = false;
    int keyword_id = 28;
    const char* keyword = "/";

    add_FIP_Entry(analyzer, keyword_id, keyword, &ts_pos);
    return DIV;
}

"%" {
    lastTokenWasSeparator = false;
    int keyword_id = 29;
    const char* keyword = "%";

    add_FIP_Entry(analyzer, keyword_id, keyword, &ts_pos);
    return MOD;
}

"(" {
    lastTokenWasSeparator = false;
    int keyword_id = 30;
    const char* keyword = "(";

    add_FIP_Entry(analyzer, keyword_id, keyword, &ts_pos);
    return LPAREN;
}

")" {
    lastTokenWasSeparator = false;
    int keyword_id = 31;
    const char* keyword = ")";

    add_FIP_Entry(analyzer, keyword_id, keyword, &ts_pos);
    return RPAREN;
}

"{" {
    lastTokenWasSeparator = true;
    int keyword_id = 32;
    const char* keyword = "{";

    add_FIP_Entry(analyzer, keyword_id, keyword, &ts_pos);    
    return LBRACE;
}

"}" {
    lastTokenWasSeparator = true;
    int keyword_id = 33;
    const char* keyword = "}";

    add_FIP_Entry(analyzer, keyword_id, keyword, &ts_pos);
    return RBRACE;
}

"[" {
    lastTokenWasSeparator = false;
    int keyword_id = 34;
    const char* keyword = "[";

    add_FIP_Entry(analyzer, keyword_id, keyword, &ts_pos);
    return LBRACKET;
}

"]" {
    lastTokenWasSeparator = false;
    int keyword_id = 35;
    const char* keyword = "]";

    add_FIP_Entry(analyzer, keyword_id, keyword, &ts_pos);
    return RBRACKET;
}

"," {
    lastTokenWasSeparator = false;
    int keyword_id = 36;
    const char* keyword = ",";

    add_FIP_Entry(analyzer, keyword_id, keyword, &ts_pos);
    return COMMA;
}

"stop" {
    lastTokenWasSeparator = true;
    int keyword_id = 37;
    const char* keyword = "stop";

    add_FIP_Entry(analyzer, keyword_id, keyword, &ts_pos);
    return STOP;
}

"executa" {
    lastTokenWasSeparator = true;
    int keyword_id = 38;
    const char* keyword = "executa";

    add_FIP_Entry(analyzer, keyword_id, keyword, &ts_pos);
    return EXECUTA;
}

"sfcattimp" {
    lastTokenWasSeparator = true;
    int keyword_id = 39;
    const char* keyword = "sfcattimp";

    add_FIP_Entry(analyzer, keyword_id, keyword, &ts_pos);
    return SFCATTIMP;
}

"&" {
    lastTokenWasSeparator = false;
    int keyword_id = 40;
    const char* keyword = "&";

    add_FIP_Entry(analyzer, keyword_id, keyword, &ts_pos);
    return AMPERSAND;
}

"elif" {
    lastTokenWasSeparator = false;
    int keyword_id = 41;
    const char* keyword = "elif";

    add_FIP_Entry(analyzer, keyword_id, keyword, &ts_pos);
    return ELIF;
}

{ID} {
    add_TS_ID(analyzer, yytext, &ts_id);

    const char* keyword = strdup(yytext);
    add_FIP_Entry(analyzer, 0, keyword, &ts_id);
    return ID;
}

{CONST} {
    add_TS_CONST(analyzer, yytext, &ts_const);

    const char* keyword = strdup(yytext);
    add_FIP_Entry(analyzer, 1, keyword, &ts_const);
    return CONST;
}

[\n]+ {
    if (!lastTokenWasSeparator) {
        char* ex = (char*) malloc(128 * sizeof(char));
        sprintf(ex, "Line did not end with a separator!");
        add_Exception(analyzer, currLine, ex);
        hasErrors = 1;
    }
    lastTokenWasSeparator = false;
    currLine++;
}

[ \t\r]+ ;

. {
    lastTokenWasSeparator = false;

    char* ex = (char*) malloc(128 * sizeof(char));
    sprintf(ex, "Unknown token %s", yytext);
    add_Exception(analyzer, currLine, ex);
    hasErrors = 1;
}

%%