import os
import sys

from lexical_analyzer.hashmap import HashMap as HM
from lexical_analyzer.tokens import KEYWORDS, SEPARATORS
from scanner import Scanner

HEADER_TS_ID = ["ID", "Position"]
HEADER_TS_CONST = ["CONST", "Position"]
HEADER_FIP = ["KEYWORD_ID", "KEYWORD", "Position in TS"]
EXCEPTIONS_HEADER = ["Line", "Message"]

TS_ID_CSV_PATH = os.path.join(".", "lexical_analyzer", "results", "TS_ID.csv")
TS_CONST_CSV_PATH = os.path.join(".", "lexical_analyzer", "results", "TS_CONST.csv")
FIP_CSV_PATH = os.path.join(".", "lexical_analyzer", "results", "FIP.csv")
EXCEPTIONS_CSV_PATH = os.path.join(".", "lexical_analyzer", "results", "EXCEPTIONS.csv")

ACCEPTED_TYPES = ["INT", "FLOAT", "STRING", "STRUCT"]


def scan_code(code: str):
    scanner = Scanner()

    symbol_tables = {"ID": HM(), "CONST": HM()}
    fip = []
    exceptions = []

    ts_id_pos, ts_const_pos = 1, 1

    for idx, line in enumerate(code.splitlines()):
        # Skip empty lines
        if not line.strip():
            continue

        # Tokenize the line
        tokens = scanner.tokenize(line)
        line_num = idx + 1

        # Exception if line not ends with separator
        if not any(line.endswith(x) for x in SEPARATORS):
            exceptions.append((line_num, "Missing separator at the end of the line!"))

        for token in tokens:
            # Keyword
            if token["type"] in ["RESERVED", "OPERATOR", "SEPARATOR"]:
                fip.append((KEYWORDS[token["value"]], token["value"], 0))
            # Identifier
            elif token["type"] == "ID":
                if not symbol_tables["ID"].get_(token["value"]):
                    symbol_tables["ID"].set_(token["value"], ts_id_pos)
                    ts_id_pos += 1
                fip.append(("ID", symbol_tables["ID"].get_(token["value"])))
            # Constant
            elif token["type"] != "unknown":
                if not symbol_tables["CONST"].get_(token["value"]):
                    symbol_tables["CONST"].set_(token["value"], ts_const_pos)
                    ts_const_pos += 1
                fip.append(("CONST", symbol_tables["CONST"].get_(token["value"])))
            # Unknown token
            else:
                exceptions.append((line_num, f"Unknown token: {token['value']}"))

    return symbol_tables, fip, exceptions


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <path_to_the_code_file>")
        sys.exit(1)

    code_abs_path = os.path.abspath(sys.argv[1])
    content = ""
    with open(code_abs_path, "r") as fin:
        content = fin.read()

    if not content:
        print("The file is empty!")
        sys.exit(2)

    symbol_tables, fip, exceptions = scan_code(content)

    with open(TS_ID_CSV_PATH, "w") as fout:
        fout.write(",".join(HEADER_TS_ID) + "\n")
        for key in symbol_tables["ID"].keys:
            fout.write(f"{key},{symbol_tables['ID'].get_(key)}\n")

    with open(TS_CONST_CSV_PATH, "w") as fout:
        fout.write(",".join(HEADER_TS_CONST) + "\n")
        for key in symbol_tables["CONST"].keys:
            fout.write(f"{key},{symbol_tables['CONST'].get_(key)}\n")

    with open(FIP_CSV_PATH, "w") as fout:
        fout.write(",".join(HEADER_FIP) + "\n")
        for entry in fip:
            fout.write(",".join(map(str, entry)) + "\n")

    with open(EXCEPTIONS_CSV_PATH, "w") as fout:
        fout.write(",".join(EXCEPTIONS_HEADER) + "\n")
        for exception in exceptions:
            fout.write(",".join(map(str, exception)) + "\n")

    print("Done!")
