import re

from typing import Dict, Set

RE_IDENTIFIER: re.Pattern = re.compile(r"\b[a-zA-Z]+[a-zA-Z0-9_]*\b")
RE_STRUCT: re.Pattern = re.compile(
    r"type\s+([a-zA-Z]+[a-zA-Z0-9_]*)\s+struct\s*\{\s*((?:[a-zA-Z]+[a-zA-Z0-9_]*\s+(?:[\w_]+)\s+stop\s*)+)\}\s*"
)


RE_TYPES: Dict[str, re.Pattern] = {
    "int": re.compile(r"\b(0|[+|-]?[1-9][0-9]*)\b"),
    "float": re.compile(r"\b[+|-]?([0-9]|[1-9][0-9])*\.[0-9]+\b"),
    "string": re.compile(r"\b\".*\"\b"),
}

RE_ATTRIB: re.Pattern = re.compile(rf"^\s+({RE_IDENTIFIER.pattern})\s+\s+=\s+(.*)\s+$")
RE_DECL: re.Pattern = re.compile(
    rf"^var\s+({RE_IDENTIFIER.pattern}(?:\s*,\s*{RE_IDENTIFIER.pattern})*)\s+(int|float|string|{RE_IDENTIFIER.pattern})\s+=\s+(.*)|({RE_IDENTIFIER.pattern}(?:\s*,\s*{RE_IDENTIFIER.pattern})*)\s+:=\s+(.*)$"
)
RE_IO: re.Pattern = re.compile(r"(fmt.Scan \( &.+ \)|fmt.Print(ln)? \( .* \)).*stop")

RELATIONAL_OPERATORS: Set[str] = {"==", "!=", "<", ">", "<=", ">="}
BINARY_OPERATORS: Set[str] = {"+", "-", "*", "/", "%"}

KEYWORDS: Dict[str, int] = {
    "ID": 0,
    "CONST": 1,
    "{": 2,
    "}": 3,
    "(": 4,
    ")": 5,
    ",": 6,
    "stop": 7,
    "int": 8,
    "float": 9,
    "string": 10,
    "struct": 11,
    "+": 12,
    "-": 13,
    "*": 14,
    "/": 15,
    "%": 16,
    "=": 17,
    "==": 18,
    "!=": 19,
    "<": 20,
    ">": 21,
    "<=": 22,
    ">=": 23,
    "if": 24,
    "else": 25,
    "for": 26,
    "var": 27,
    ":=": 28,
    "func": 29,
    "main": 30,
    "fmt.Scan": 31,
    "fmt.Print": 32,
    "fmt.Println": 33,
}
