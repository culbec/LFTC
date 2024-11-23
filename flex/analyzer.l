%{
#include <algorithm>
#include <iterator>
#include <iostream>
#include <fstream>
#include <cstdint>
#include <unordered_map>
#include <vector>
#include <string>

int main(int argc, char* argv[]);

struct Exception
{
    uint32_t line;
    std::string message;
};

struct FIP_Entry
{
    uint32_t keyword_id;
    std::string keyword;
    int ts_pos;
};

struct TS_Entry
{
    uint32_t id;
    std::string name;
};

struct Analyzer
{
    std::unordered_map<std::string, uint32_t> TS_ID = std::unordered_map<std::string, uint32_t>();
    std::unordered_map<std::string, uint32_t> TS_CONST = std::unordered_map<std::string, uint32_t>();
    std::vector<FIP_Entry> FIP = std::vector<FIP_Entry>();
    std::vector<Exception> exceptions = std::vector<Exception>();
};

Analyzer *analyzer;
uint32_t currLine = 1;
uint32_t ts_id = 1;
uint32_t ts_const = 1;

bool lastTokenWasSeparator = false;

void add_TS_ID(std::string name)
{
    if (analyzer->TS_ID.find(name) == analyzer->TS_ID.end())
    {
        analyzer->TS_ID[name] = ts_id++;
    }
}

void add_TS_CONST(std::string name)
{
    if (analyzer->TS_CONST.find(name) == analyzer->TS_CONST.end())
    {
        analyzer->TS_CONST[name] = ts_const++;
    }
}

void add_FIP_Entry(uint32_t keyword_id, std::string keyword, int ts_pos)
{
    FIP_Entry entry;
    entry.keyword_id = keyword_id;
    entry.keyword = keyword;
    entry.ts_pos = ts_pos;
    analyzer->FIP.push_back(entry);
}

void add_Exception(uint32_t line, std::string message)
{
    Exception exception;
    exception.line = line;
    exception.message = message;
    analyzer->exceptions.push_back(exception);
}

void write_TS_ID() {
    std::ofstream fout("TS_ID.csv");

    fout << "ID,Position\n";

    std::for_each(
        analyzer->TS_ID.begin(), analyzer->TS_ID.end(),
        [&fout](std::pair<std::string, uint32_t> p) {
            fout << p.first << "," << p.second << "\n";
        });
    
    fout.close();
}

void write_TS_CONST() {
    std::ofstream fout("TS_CONST.csv");

    fout << "CONST,Position\n";

    std::for_each(
        analyzer->TS_CONST.begin(), analyzer->TS_CONST.end(),
        [&fout](std::pair<std::string, uint32_t> p) {
            fout << p.first << "," << p.second << "\n";
        });
    
    fout.close();
}

void write_FIP() {
    std::ofstream fout("FIP.csv");

    fout << "KEYWORD_ID,KEYWORD,Position in TS\n";

    for(const auto& entry: analyzer->FIP) {
        fout << entry.keyword_id << "," << entry.keyword << "," << entry.ts_pos << "\n";
    }

    fout.close();
}

void write_Exceptions() {
    std::ofstream fout("Exceptions.csv");

    fout << "Line,Message\n";

    for(const auto& ex: analyzer->exceptions) {
        fout << ex.line << "," << ex.message << "\n";
    }

    fout.close();
}


%}

%option c++
%option noyywrap

DIGIT               [0-9]
DECIMAL_DIGITS      {DIGIT}"_"?{DIGIT}*
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
ID                  {LETTER}({LETTER}|{DIGIT})* 
INT                 {DECIMAL_LIT}|{BINARY_LIT}|{OCTAL_LIT}|{HEX_LIT}
FLOAT               {DECIMAL_FLOAT_LIT}|{HEX_FLOAT_LIT}
STRING              \"({LETTER}|{DIGIT}|" ")*\"
CONST               {INT}|{FLOAT}|{STRING}
RESERVED            int|float|string|struct|if|else|for|var|func|main|fmt\.Scan|fmt\.Print|fmt\.Println|cattimp
OPERATOR            ==|!=|<|<=|>|>=|=|:=|\+|\-|\*|\/|\%
SEPARATOR           \(|\)|\{|\}|\[|\]|,|stop|executa|sfcattimp
%%

{RESERVED} {
    lastTokenWasSeparator = false;
    int keyword_id = 3;

    std::string name = std::string(yytext);
    if (name == "int")
    {
        keyword_id = 3;
    }
    else if (name == "float")
    {
        keyword_id = 4;
    }
    else if (name == "string")
    {
        keyword_id = 5;
    }
    else if (name == "struct")
    {
        keyword_id = 6;
    }
    else if (name == "if")
    {
        keyword_id = 7;
    }
    else if (name == "else")
    {
        keyword_id = 8;
    }
    else if (name == "for")
    {
        keyword_id = 9;
    }
    else if (name == "var")
    {
        keyword_id = 10;
    }
    else if (name == "func")
    {
        keyword_id = 11;
    }
    else if (name == "main")
    {
        keyword_id = 12;
    }
    else if (name == "fmt.Scan")
    {
        keyword_id = 13;
    }
    else if (name == "fmt.Print")
    {
        keyword_id = 14;
    }
    else if (name == "fmt.Println")
    {
        keyword_id = 15;
    } 
    else if (name == "cattimp") {
        keyword_id = 16;
    }

    add_FIP_Entry(keyword_id, name, -1);
}

{OPERATOR} {
    lastTokenWasSeparator = false;
    int keyword_id = 17;

    std::string name = std::string(yytext);

    if (name == "==")
    {
        keyword_id = 17;
    }
    else if (name == "!=")
    {
        keyword_id = 18;
    }
    else if (name == "<")
    {
        keyword_id = 19;
    }
    else if (name == "<=")
    {
        keyword_id = 20;
    }
    else if (name == ">")
    {
        keyword_id = 21;
    }
    else if (name == ">=")
    {
        keyword_id = 22;
    }
    else if (name == "=")
    {
        keyword_id = 23;
    }
    else if (name == ":=")
    {
        keyword_id = 24;
    }
    else if (name == "+")
    {
        keyword_id = 25;
    }
    else if (name == "-")
    {
        keyword_id = 26;
    }
    else if (name == "*")
    {
        keyword_id = 27;
    }
    else if (name == "/")
    {
        keyword_id = 28;
    }
    else if (name == "%")
    {
        keyword_id = 29;
    }

    add_FIP_Entry(keyword_id, name, 0);
}

{SEPARATOR} {
    lastTokenWasSeparator = true;
    int keyword_id = 30;

    std::string name = std::string(yytext);

    if (name == "(")
    {
        keyword_id = 30;
    }
    else if (name == ")")
    {
        keyword_id = 31;
    }
    else if (name == "{")
    {
        keyword_id = 32;
    }
    else if (name == "}")
    {
        keyword_id = 33;
    }
    else if (name == "[")
    {
        keyword_id = 34;
    }
    else if (name == "]")
    {
        keyword_id = 35;
    }
    else if (name == " ")
    {
        keyword_id = 36;
    }
    else if (name == ",")
    {
        keyword_id = 37;
    }
    else if (name == "stop")
    {
        keyword_id = 38;
    }
    else if (name == "executa") {
        keyword_id = 39;
    }
    else if (name == "sfcattimp") {
        keyword_id = 40;
    }

    add_FIP_Entry(keyword_id, name, -1);
}

{ID} {
    std::string name = std::string(yytext);
    add_TS_ID(name);
    add_FIP_Entry(0, name, ts_id-1);
}

{CONST} {
    std::string name = std::string(yytext);
    add_TS_CONST(name);
    add_FIP_Entry(1, name, ts_const-1);
}

[\n]+ {
    if (!lastTokenWasSeparator) {
        add_Exception(currLine, "Line did not end with a separator!");
    }
    lastTokenWasSeparator = false;
    currLine++;
}

[ \t\r]+ ;

. {
    lastTokenWasSeparator = false;
    add_Exception(currLine, "Unknown token" + std::string(yytext));
}

%%
int main(int argc, char* argv[])
{
    std::ifstream input;
    if (argc > 1) {
        input.open(argv[1]);
        if (!input) {
            std::cerr << "Could not open " << argv[1] << std::endl;
            return 1;
        }
    }

    analyzer = new Analyzer();
    
    yyFlexLexer lexer(&input);
    while(lexer.yylex() != 0);
    
    write_TS_ID();
    write_TS_CONST();
    write_FIP();
    write_Exceptions();
    delete analyzer;
    return 0;
}