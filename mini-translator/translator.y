%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>
#include <ctype.h>

extern int yylex();
extern int yyparse();
extern FILE* yyin;
extern int line;

void yyerror();

FILE* fout;
const char* filename;

#define MAX_SIZE 1024

char data[MAX_SIZE][MAX_SIZE] = {0}, variables[MAX_SIZE][MAX_SIZE] = {0}, 
    expressions[MAX_SIZE][MAX_SIZE][MAX_SIZE] = {0}, source_code[MAX_SIZE][MAX_SIZE] = {0}, imports[MAX_SIZE][MAX_SIZE] = {0};

int len_data = 0, len_variables = 0, 
    len_expressions = 0, len_source_code = 0, len_imports = 0;
int n = 0;

bool found(char col[][MAX_SIZE], int n, const char *variable);
void parse_expression(int len_expression);

void print_imports();
void print_data_segment();
void print_code_segment();

%}

%union {
    char *value;
}

%require "3.7.2"
%language "C"
%defines "translator.h"
%output "translator.c"

%token FUNC MAIN STOP VAR RETURN

%token LPAREN RPAREN LBRACE RBRACE COMMA

%token SCAN PRINT PRINTLN

%token INT FLOAT STRING
%token PLUS MINUS MUL DIV AMPERSAND
%token ASSIGN DECLARE

%token ID CONST

%%

program: FUNC MAIN LPAREN RPAREN LBRACE statements RBRACE
    ;

statements: statement 
    | statements statement
    ;

statement: decl | attr | io
    ;

op: PLUS | MINUS | MUL | DIV
    ;

expr: term 
    | term op expr {
        char tmp[MAX_SIZE];
        strcpy(tmp, $<value>1);
        strcat(tmp, " ");
        strcat(tmp, $<value>2);
        strcat(tmp, " ");
        strcat(tmp, $<value>3);
        $<value>$ = strdup(tmp);
    }
    ;

term: ID | CONST
    ;


type: INT 
    ;

decl: VAR ID type ASSIGN expr STOP {
        // add variable to data segment
        char tmp[100] = {0};
        strcpy(tmp, "");
        strcpy(tmp, $<value>2);

        // put the variable in the expression before
        // adding it into the data segment
        strcpy(expressions[len_expressions][0], tmp);

        if (!found(variables, len_variables, tmp)) {
            strcpy(data[len_data++], strcat(tmp, " times 4 db 0"));
            strcpy(data[len_variables++], tmp);
        }

        // parse expression
        char tmp_expr[MAX_SIZE] = {0};
        int len_expression = 1;

        strcpy(tmp_expr, "");
        strcpy(tmp_expr, $<value>5);
        char *token = strtok(tmp_expr, " ");

        while (token != NULL) {
            strcpy(expressions[len_expressions][len_expression++], token);
            token = strtok(NULL, " ");
        }

        len_expressions++;
        parse_expression(len_expression);
    }
    | VAR ID type STOP {
        // add variable to data segment
        char tmp[100];
        strcpy(tmp, "");
        strcat(tmp, $<value>2);
        if (!found(variables, len_variables, tmp)) {
            strcpy(data[len_data++], strcat(tmp, " times 4 db 0"));
            strcpy(data[len_variables++], tmp);
        }
    }

attr: ID ASSIGN expr STOP {
    char tmp[MAX_SIZE];
    int len_expression = 1;
    strcpy(tmp, "");
    strcpy(tmp, $<value>1);

    strcpy(expressions[len_expressions][0], tmp);

    strcpy(tmp, "");
    strcpy(tmp, $<value>3);
    char *token = strtok(tmp, " ");

    while (token != NULL) {
        strcpy(expressions[len_expressions][len_expression++], token);
        token = strtok(NULL, " ");
    }

    len_expressions++;
    parse_expression(len_expression);
}
    ;

io: SCAN LPAREN AMPERSAND ID RPAREN STOP {
    // adding 'scanf' to imports if not already added
    if (!found(imports, len_imports, "scanf")) {
        strcpy(imports[len_imports++], "scanf");
    }

    // adding 'format' message in the data segment if not already added
    if (!found(variables, len_variables, "format")) {
        strcpy(data[len_data++], "format db \"%d\", 0");
        strcpy(variables[len_variables++], "format");
    }

    // rewriting the source code
    for (int i = n; i >= 0; i--) {
        strcpy(source_code[len_source_code++], variables[i]);
    }

    strcpy(source_code[len_source_code], "push dword ");
    strcat(source_code[len_source_code], $<value>4);
    strcat(source_code[len_source_code], "\n\tpush dword format");
    strcat(source_code[len_source_code], "\n\tcall [scanf]");
    strcat(source_code[len_source_code++], "\n\tadd esp, 4 * 2\n");
}
    | PRINT LPAREN ID RPAREN STOP {
        // adding 'printf' to imports if not already added
        if (!found(imports, len_imports, "printf")) {
            strcpy(imports[len_imports++], "printf");
        }

        // adding the format if not already added
        if (!found(variables, len_variables, "format")) {
            strcpy(data[len_data++], "format db \"%d\", 0");
            strcpy(variables[len_variables++], "format");
        }

        strcpy(source_code[len_source_code], "push dword [");
        strcat(source_code[len_source_code], $<value>3);
        strcat(source_code[len_source_code], "]");
        strcat(source_code[len_source_code], "\n\tpush dword format");
        strcat(source_code[len_source_code], "\n\tcall [printf]");
        strcat(source_code[len_source_code++], "\n\tadd esp, 4 * 2\n");
    }
    | PRINTLN LPAREN ID RPAREN STOP {
        // adding 'printf' to imports if not already added
        if (!found(imports, len_imports, "printf")) {
            strcpy(imports[len_imports++], "printf");
        }

        // adding the format if not already added
        if (!found(variables, len_variables, "format_newline")) {
            strcpy(data[len_data++], "format_newline db \"%d\", 13, 10, 0");
            strcpy(variables[len_variables++], "format_newline");
        }

        strcpy(source_code[len_source_code], "push dword [");
        strcat(source_code[len_source_code], $<value>3);
        strcat(source_code[len_source_code], "]");
        strcat(source_code[len_source_code], "\n\tpush dword format_newline");
        strcat(source_code[len_source_code], "\n\tcall [printf]");
        strcat(source_code[len_source_code++], "\n\tadd esp, 4 * 2\n");
    }
    ;

%%

void yyerror() {
    extern char *yytext;
    fprintf(stdout, "Error on line %d: %s\n", line, yytext);
    exit(EXIT_FAILURE);
}

void parse_expression(int len_expression) {
    if (len_expression < 3) {
        // Handle simple assignment
        strcpy(source_code[len_source_code], "mov dword [");
        strcat(source_code[len_source_code], expressions[len_expressions - 1][0]);
        strcat(source_code[len_source_code], "], ");
        strcat(source_code[len_source_code++], expressions[len_expressions - 1][1]);
        return;
    }

    bool found_first_operand = false;

    // tracking processed tokens
    // processed means that it was implied in another operation already
    // we do not have arithmetic () so only the order of operations is important
    
    // the processed tokens are important only when talking about add and sub
    // because the first pass will take care of mul and div and mark those tokens
    // the second pass adds the remaining tokens, but we need to be careful not to add the already processed tokens 
    char processed[MAX_SIZE] = {0};

    // first pass: process mul and div
    for (int i = 2; i < len_expression; i += 2) {
        if (strcmp(expressions[len_expressions - 1][i], "*") == 0 || strcmp(expressions[len_expressions - 1][i], "/") == 0) {
            if (!found_first_operand) {
                if (isdigit(expressions[len_expressions - 1][i - 1][0])) {
                    strcpy(source_code[len_source_code], "mov EAX, ");
                    strcat(source_code[len_source_code++], expressions[len_expressions - 1][i - 1]);
                } else {
                    strcpy(source_code[len_source_code], "mov EAX, [");
                    strcat(source_code[len_source_code], expressions[len_expressions - 1][i - 1]);
                    strcat(source_code[len_source_code++], "]");
                }

                found_first_operand = true;
                processed[i - 1] = 1;
            }

            if (strcmp(expressions[len_expressions - 1][i], "*") == 0) {
                strcpy(source_code[len_source_code++], "xor EDX, EDX");
                
                if (isdigit(expressions[len_expressions - 1][i + 1][0])) {
                    strcpy(source_code[len_source_code], "mov EBX, ");
                    strcat(source_code[len_source_code++], expressions[len_expressions - 1][i + 1]);
                    strcpy(source_code[len_source_code++], "mul EBX");
                } else {
                    strcpy(source_code[len_source_code], "mul dword [");
                    strcat(source_code[len_source_code], expressions[len_expressions - 1][i + 1]);
                    strcat(source_code[len_source_code++], "]");
                }
            }
            else {
                strcpy(source_code[len_source_code++], "xor EDX, EDX");
                if (isdigit(expressions[len_expressions - 1][i + 1][0])) {
                    strcpy(source_code[len_source_code], "mov EBX, ");
                    strcat(source_code[len_source_code++], expressions[len_expressions - 1][i + 1]);
                    strcpy(source_code[len_source_code++], "div EBX");
                } else {
                    strcpy(source_code[len_source_code], "div dword [");
                    strcat(source_code[len_source_code], expressions[len_expressions - 1][i + 1]);
                    strcat(source_code[len_source_code++], "]");
                }
            }
            processed[i - 1] = processed[i + 1] = 1;
        }
    }

    // second pass: process add and sub
    // now we need to be careful so that we do not add operands implied in mul or div
    for (int i = 2; i < len_expression; i += 2) {
        if (strcmp(expressions[len_expressions - 1][i], "+") == 0 || strcmp(expressions[len_expressions - 1][i], "-") == 0) {
            
            // Load first operand if it's the first operation
            if (!found_first_operand) {
                if (isdigit(expressions[len_expressions - 1][i-1][0])) {
                    strcpy(source_code[len_source_code], "mov EAX, ");
                    strcat(source_code[len_source_code++], expressions[len_expressions - 1][i-1]);
                } else {
                    strcpy(source_code[len_source_code], "mov EAX, [");
                    strcat(source_code[len_source_code], expressions[len_expressions - 1][i-1]);
                    strcat(source_code[len_source_code++], "]");
                }
                found_first_operand = true;
                processed[i - 1] = 1;
            }

            // Addition
            if (strcmp(expressions[len_expressions - 1][i], "+") == 0) {
                if (!processed[i - 1]) {
                    if (isdigit(expressions[len_expressions - 1][i-1][0])) {
                        strcpy(source_code[len_source_code], "add EAX, ");
                        strcat(source_code[len_source_code++], expressions[len_expressions - 1][i-1]);
                    } else {
                        strcpy(source_code[len_source_code], "add EAX, [");
                        strcat(source_code[len_source_code], expressions[len_expressions - 1][i-1]);
                        strcat(source_code[len_source_code++], "]");
                    }
                }

                if (!processed[i + 1]) {
                    if (isdigit(expressions[len_expressions - 1][i+1][0])) {
                        strcpy(source_code[len_source_code], "add EAX, ");
                        strcat(source_code[len_source_code++], expressions[len_expressions - 1][i+1]);
                    } else {
                        strcpy(source_code[len_source_code], "add EAX, [");
                        strcat(source_code[len_source_code], expressions[len_expressions - 1][i+1]);
                        strcat(source_code[len_source_code++], "]");
                    }
                }
            }
            // Subtraction
            else {
                if (!processed[i - 1]) {
                    if (isdigit(expressions[len_expressions - 1][i-1][0])) {
                        strcpy(source_code[len_source_code], "sub EAX, ");
                        strcat(source_code[len_source_code++], expressions[len_expressions - 1][i-1]);
                    } else {
                        strcpy(source_code[len_source_code], "sub EAX, [");
                        strcat(source_code[len_source_code], expressions[len_expressions - 1][i-1]);
                        strcat(source_code[len_source_code++], "]");
                    }
                }
                
                if (!processed[i + 1]) {
                    if (isdigit(expressions[len_expressions - 1][i+1][0])) {
                        strcpy(source_code[len_source_code], "sub EAX, ");
                        strcat(source_code[len_source_code++], expressions[len_expressions - 1][i+1]);
                    } else {
                        strcpy(source_code[len_source_code], "sub EAX, [");
                        strcat(source_code[len_source_code], expressions[len_expressions - 1][i+1]);
                        strcat(source_code[len_source_code++], "]");
                    }
                }
            }
        }
    }

    // Store final result
    strcpy(source_code[len_source_code], "mov [");
    strcat(source_code[len_source_code], expressions[len_expressions - 1][0]);
    strcat(source_code[len_source_code++], "], EAX\n");
}



bool found(char col[][MAX_SIZE], int n, const char *variable) {
    char tmp[MAX_SIZE];
    strcpy(tmp, variable);

    for (int i = 0; i < n; i++) {
        if (strcmp(col[i], tmp) == 0) {
            return true;
        }
    }

    return false;
}

void print_imports() {
    for (int i = 0; i < len_imports; i++) {
        fprintf(fout, "extern %s\nimport %s msvcrt.dll\n\n", imports[i], imports[i]);
    }
}

void print_data_segment() {
    for (int i = 0; i < len_data; i++) {
        fprintf(fout, "\t%s\n", data[i]);
    }
}


void print_code_segment() {
    for (int i = 0; i < len_source_code; i++) {
        fprintf(fout, "\t%s\n", source_code[i]);
    }
}

int main(int argc, char ** argv) {
    FILE *f = NULL;
    if (argc > 1) {
        f = fopen(argv[1], "r");
    }

    if (!f) {
        perror("Could not open file! Input from stdin\n");
        yyin = stdin;
    } else {
        yyin = f;
    }

    strcpy(imports[len_imports++], "exit");

    while(!feof(yyin)) {
        yyparse();
    }

    printf("Parsed successfully\n");

    fout = fopen("output.asm", "w+");
    fprintf(fout, "bits 32\nglobal start\n\n");

    print_imports();

    fprintf(fout, "segment data use32 class=data\n");
    print_data_segment();

    fprintf(fout, "segment code use32 class=code\nstart:\n");
    strcpy(source_code[len_source_code++], "push dword 0");
    strcpy(source_code[len_source_code++], "call [exit]");
    print_code_segment();
    
    return 0;
}