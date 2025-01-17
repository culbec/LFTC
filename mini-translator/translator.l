%{
#include <stdio.h>
#include <string.h>
#include "translator.h"

#define YY_DECL int yylex()

int line = 1;
%}

%option noyywrap
%option outfile="translator_lex.c"

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

func                    {return FUNC;}
main                    {return MAIN;}
stop                    {return STOP;}
Scan                    {return SCAN;}
Print                   {return PRINT;}
Println                 {return PRINTLN;}
var                     {return VAR;}
int                     {return INT;}
float                   {return FLOAT;}
string                  {return STRING;}
return                  {return RETURN;}
"("                     {return LPAREN;}
")"                     {return RPAREN;}
"{"                     {return LBRACE;}
"}"                     {return RBRACE;}
","                     {return COMMA;}
"+"                     {yylval.value = strdup(yytext); return PLUS;}
"-"                     {yylval.value = strdup(yytext); return MINUS;}
"*"                     {yylval.value = strdup(yytext); return MUL;}
"/"                     {yylval.value = strdup(yytext); return DIV;}
"&"                     {return AMPERSAND;}
"="                     {return ASSIGN;}
":="                    {return DECLARE;}

{ID}                    {yylval.value = strdup(yytext); return ID;}
{CONST}                 {yylval.value = strdup(yytext); return CONST;}
[\n]                    {line++;}
[ \t]+                  ;

%%