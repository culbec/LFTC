%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
extern int yylex(void);
typedef struct yy_buffer_state *YY_BUFFER_STATE;
extern YY_BUFFER_STATE yy_scan_string(const char *str);
extern void yy_delete_buffer(YY_BUFFER_STATE buffer);

#define MAX_LENGTH 1024

void yyerror(const char *s);
char first_half[MAX_LENGTH];
char second_half[MAX_LENGTH];
int len_first_half = 0;
int len_second_half = 0;

int middle_found = 0;

int is_palindrome() {
    if (len_first_half != len_second_half) {
        return 0;
    }

    for (int i = 0; i < len_first_half; i++) {
        if (first_half[i] != second_half[len_first_half - i - 1]) {
            return 0;
        }
    }

    return 1;
}

%}

%require "3.7.2"
%language "C"
%defines "palindromb.h"
%output "palindromb.c"

%union {
    char c;
}

%token <c> CHAR
%token MIDDLE

%%

input: sentence { 
    if (!middle_found) {
        printf("Error: No middle marker (#) found\n");
    } else {
        printf("First half: %s\n", first_half);
        printf("Second half: %s\n", second_half);

        if (is_palindrome()) {
            printf("The sentence is a palindrome.\n");
        } else {
            printf("The sentence is not a palindrome.\n");
        }
    }
}
;

sentence: 
    | sentence CHAR {
        if (middle_found) {
            second_half[len_second_half++] = $2;
        } else {
            first_half[len_first_half++] = $2;
        }
        printf("Added char: %c\n", $2);
    }
    | sentence MIDDLE {
        middle_found = 1;
        printf("Middle marker found\n");
    }
;

%%

void yyerror(const char* s) {
    fprintf(stderr, "Syntax error: %s\n", s);
    exit(EXIT_FAILURE);
}

int main() {
    char input[1024];
    len_first_half = 0;
    len_second_half = 0;
    middle_found = 0;
    memset(first_half, 0, MAX_LENGTH);
    memset(second_half, 0, MAX_LENGTH);

    printf("Enter a sentence: ");
    if (fgets(input, sizeof(input), stdin) == NULL) {
        fprintf(stderr, "Error reading input\n");
        return 1;
    }

    size_t len = strlen(input);
    if (len > 0 && input[len - 1] == '\n') {
        input[len - 1] = '\0';
    }

    YY_BUFFER_STATE buffer = yy_scan_string(input);
    int result = yyparse();
    yy_delete_buffer(buffer);

    return result;
}