RESERVED: list[str] = [
    "int",
    "float",
    "string",
    "struct",
    "if",
    "else",
    "for",
    "var",
    "func",
    "main",
    "fmt.Scan",
    "fmt.Print",
    "fmt.Println",
]
OPERATORS: list[str] = [
    "==",
    "!=",
    "<",
    ">",
    "<=",
    ">=",
    "=",
    ":=",
    "+",
    "-",
    "*",
    "/",
    "%",
]
SEPARATORS: list[str] = ["{", "}", "(", ")", ",", " ", "[", "]", "stop"]

all_ = RESERVED + OPERATORS + SEPARATORS

KEYWORDS: dict[str, int] = {key: i + 2 for i, key in enumerate(all_)}
KEYWORDS["ID"] = 0
KEYWORDS["CONST"] = 1


# KEYWORDS: Dict[str, int] = {
#     "ID": 0,
#     "CONST": 1,
#     "{": 2,
#     "}": 3,
#     "(": 4,
#     ")": 5,
#     ",": 6,
#     "stop": 7,
#     "int": 8,
#     "float": 9,
#     "string": 10,
#     "struct": 11,
#     "+": 12,
#     "-": 13,
#     "*": 14,
#     "/": 15,
#     "%": 16,
#     "=": 17,
#     "==": 18,
#     "!=": 19,
#     "<": 20,
#     ">": 21,
#     "<=": 22,
#     ">=": 23,
#     "if": 24,
#     "else": 25,
#     "for": 26,
#     "var": 27,
#     ":=": 28,
#     "func": 29,
#     "main": 30,
#     "fmt.Scan": 31,
#     "fmt.Print": 32,
#     "fmt.Println": 33,
# }
