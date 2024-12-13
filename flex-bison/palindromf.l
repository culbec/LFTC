%{
#include "palindromb.h"
%}

%option debug
%option nodefault
%option noyywrap
%option outfile="palindromf.c"

%%

[a-zA-Z0-9] {
    yylval.c = yytext[0];
    printf("DEBUG Flex: Found char '%c'\n", yytext[0]);
    return CHAR;
}

[#] {
    printf("DEBUG Flex: Found middle marker '#'\n");
    return MIDDLE;
}

[ \t\n] {;}

[[:punct:]] {;}

. {;}

%%