%{
#include <stdio.h>
#include "flexer.h"
#include "hashtable.h"

extern int yylex();
extern FILE* yyin;

void yyerror(const char *s);
%}

%require "3.7.2"
%language "C"
%defines "bisoner.h"
%output "bisoner.c"

%token INT FLOAT STRING STRUCT
%token IF ELSE ELIF FOR VAR FUNC MAIN SCAN PRINT PRINTLN CATTIMP
%token EQ NEQ LT LTE GT GTE ASSIGN DECLARE
%token PLUS MINUS MUL DIV MOD AMPERSAND
%token LPAREN RPAREN LBRACE RBRACE LBRACKET RBRACKET COMMA STOP EXECUTA SFCATTIMP
%token ID CONST

%%

program: FUNC MAIN LPAREN RPAREN LBRACE statements RBRACE
    ;

statements: statement 
    | statements statement
    ;

statement: decl 
    | attr 
    | io 
    | cond 
    | rep 
    | cattimp
    ;

expr: term expr_rest
    ;

expr_rest: /* empty */
    | op term expr_rest
    ;

term: ID | CONST
    ;

optional_vars: /* empty */ 
    | COMMA ID
    ;
optional_expr: /* empty */ 
    | COMMA expr
    ;
type: INT | FLOAT | STRING | STRUCT
    ;
decl: VAR ID optional_vars type ASSIGN expr optional_expr STOP 
    | ID optional_vars DECLARE expr optional_expr STOP
    ;

attr: ID ASSIGN expr STOP
    ;
op: binaryOp 
    | relOp
    ;
binaryOp: PLUS | MINUS | MOD | MUL | DIV
    ;
relOp: LT | GT | LTE | GTE | EQ | NEQ
    ;

io: SCAN LPAREN AMPERSAND ID RPAREN STOP 
    | PRINT LPAREN expr optional_expr RPAREN STOP 
    | PRINTLN LPAREN expr optional_expr RPAREN STOP
    ;

condStatement: ID relOp ID 
    | ID relOp CONST 
    | CONST relOp ID 
    | CONST relOp CONST
    ;
optional_elif: /* empty */
    | ELIF LPAREN condStatement RPAREN LBRACE statements RBRACE optional_elif
    ;
optional_else: /* empty */
    | ELSE LBRACE statements RBRACE
    ;
cond: IF LPAREN condStatement RPAREN LBRACE statements RBRACE optional_elif optional_else
    ;

rep: FOR LPAREN condStatement RPAREN LBRACE statements RBRACE

cattimp: CATTIMP LPAREN condStatement RPAREN EXECUTA statements SFCATTIMP
    ;

%%

void yyerror(const char* s) {
    fprintf(stderr, "Syntax error on line %s\n", s);
    exit(EXIT_FAILURE);
}

int main(int argc, char** argv) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <input_file>\n", argv[0]);
        return 1;
    }

    FILE *fp = fopen(argv[1], "r");
    if (!fp) {
        fprintf(stderr, "Cannot open file %s\n", argv[1]);
        return 1;
    }

    analyzer = malloc(sizeof(Analyzer));
    if (!analyzer) {
        fprintf(stderr, "Memory allocation failed\n");
        fclose(fp);
        return 1;
    }

    init(analyzer);
    yyin = fp;
    
    printf("Starting parse...\n");
    int result = yyparse();

    write_TS_ID(analyzer);
    write_TS_CONST(analyzer);
    write_FIP(analyzer);
    write_Exceptions(analyzer);
    
    if (result == 0 && !hasErrors) {
        printf("Parse completed successfully\n");
    } else {
        fprintf(stderr, "Parsing failed\n");
    }

    fclose(fp);
    destroy(analyzer);
    free(analyzer);
    return result;
}