import os
import sys
import tokens
import csv

from typing import List, Set, Tuple, Dict, Union
from hashmap import HashMap as HM

HEADER_TS_ID = ["ID", "Position"]
HEADER_TS_CONST = ["CONST", "Position"]
HEADER_FIP = ["KEYWORD_ID", "Position in TS"]
EXCEPTIONS_HEADER = ["TS/FIP", "Line", "Message"]

TS_ID_CSV_PATH = os.path.join(".", "TS_ID.csv")
TS_CONST_CSV_PATH = os.path.join(".", "TS_CONST.csv")
FIP_CSV_PATH = os.path.join(".", "FIP.csv")
EXCEPTIONS_CSV_PATH = os.path.join(".", "EXCEPTIONS.csv")


def write_table_values(table, path: str, table_name: str = "ts_id"):
    """
    Writes table values into a CSV file

    :param table: The table to write
    :param str path: The path to the CSV file
    :param str table_name: The name of the table to write, defaults to "ts_id"
    """
    with open(path, "w") as fout:
        header = ""
        match (table_name):
            case "ts_id":
                header = HEADER_TS_ID
            case "ts_const":
                header = HEADER_TS_CONST
            case _:
                header = HEADER_FIP

        fout.write(f"{','.join(header_item for header_item in header)}\n")

        if table_name == "ts_id" or table_name == "ts_const":
            for key in table.keys:
                index = table.get_(key)
                fout.write(f"{key},{index}\n")
        else:
            for item in table:
                for keyword_id, position_ts in item.items():
                    position_ts = "" if position_ts is None else position_ts
                    fout.write(f"{keyword_id},{position_ts}\n")


def write_exceptions(exceptions: Tuple, path: str):
    """
    Writes all encountered exceptions in the specified CSV file

    :param Tuple exceptions: The exceptions to write
    :param str path: The path to the CSV file
    """
    header = EXCEPTIONS_HEADER

    with open(path, "w") as fout:
        fout.write(f"{','.join(header_item for header_item in header)}\n")

        for exception_tuple in exceptions:
            kind, dict_ex = exception_tuple

            for line_idx, exception_list in dict_ex.items():
                for exception_ in exception_list:
                    fout.write(f"{kind},{line_idx},{str(exception_)}\n")


def get_TS(
    matching_lines: List[str], known_structs: Set[str]
) -> Tuple[HM, HM, Dict[int, List[Exception]]]:
    """
    Returns the table symbol of identifiers and constants,
    along with lexical errors if any.

    :param List[str] matching_lines: Matching attributions/declarations of the code
    :param Set[str] known_structs: The names of the known structs declared
    :return Tuple[HM, HM, Dict[int, List[Exception]]]: TS identifiers, TS const and any lexical errors
    """

    ts_id: HM = HM()
    ts_const: HM = HM()

    curr_id, curr_const = 1, 1
    exceptions = {}

    for idx, line in enumerate(matching_lines):
        line = line.strip().rstrip("stop")
        exceptions[idx] = []

        # NOTE: SARI PESTE LINIE DACA E EXCEPTIE. NU INCLUDE CAUTAREA din FIP in TS DACA LINIA E GRESITA!!!

        # Processing ATTRIBUTIONS
        if tokens.RE_ATTRIB.match(line):
            match_ = tokens.RE_ATTRIB.match(line)
            id_, expressions = match_.group(1).strip(), [
                expr_.strip() for expr_ in match_.group(2).strip().split(",")
            ]

            # IDENTIFIER
            if id_.lower() in tokens.KEYWORDS.keys() and id_ not in ["ID", "CONST"]:
                exceptions[idx].append(
                    Exception(f"Line {idx}: variable `{id_}` is named as a keyword")
                )
            elif not ts_id.get_(id_):
                exceptions[idx].append(
                    Exception(
                        f"Line {idx}: no prior declaration of variable `{id_}` found"
                    )
                )

            # EXPRESSION
            for expr_ in expressions:
                for i, elem in enumerate(expr_.split()):
                    # Should be an identifier/constant
                    if i % 2 == 0:
                        # Verifying if the expression element is a reserved keyword
                        if elem.lower() in tokens.KEYWORDS.keys() and elem not in [
                            "ID",
                            "CONST",
                        ]:
                            exceptions[idx].append(
                                Exception(
                                    f"Line {idx}: variable `{id_}` is named as a keyword"
                                )
                            )
                        # Considering identifiers as expression elements
                        # and verifying if any prior declaration was made before referencing
                        elif tokens.RE_IDENTIFIER.match(elem):
                            if not ts_id.get_(elem):
                                exceptions[idx].append(
                                    Exception(
                                        f"Line {idx}: prior declaration of `{elem}` not found"
                                    )
                                )
                        else:
                            # Finding the type and associated value of the element
                            found_type = ""
                            for type_, re_type in tokens.RE_TYPES.items():
                                if re_type.match(elem):
                                    found_type = type_
                                    break

                            if not found_type:
                                exceptions[idx].append(
                                    Exception(
                                        f"Line {idx}: `{elem}` not in accepted types"
                                    )
                                )
                            else:
                                # Adding the constant in the table of constants if not already added
                                if not ts_const.get_(elem):
                                    ts_const.set_(elem, curr_const)
                                    curr_const += 1
                    else:
                        # Verifying if the operator is in the accepted operators
                        if (
                            not expr_
                            in tokens.BINARY_OPERATORS + tokens.RELATIONAL_OPERATORS
                        ):
                            exceptions[idx].append(
                                Exception(
                                    f"Line {idx}: `{elem}` is not an accepted operator"
                                )
                            )

        # Processing DECLARATIONS
        elif tokens.RE_DECL.match(line):
            match_ = tokens.RE_DECL.match(line)

            variables, expressions = "", []

            if match_.group(1):
                variables, type_, expressions = (
                    match_.group(1).strip().split(","),
                    match_.group(2).strip(),
                    [expr_.strip() for expr_ in match_.group(3).strip().split(",")],
                )

                # Analyzing the types: int, float, string or some known struct if there are any
                if type_ not in ["int", "float", "string"] + list(known_structs):
                    exceptions[idx].append(
                        Exception(f"Line {idx}: type `{type_}` unknown")
                    )
            elif match_.group(4):
                variables, expressions = (
                    match_.group(4).strip().split(","),
                    [expr_.strip() for expr_ in match_.group(5).strip().split(",")],
                )

            # ANALYZING VARIABLES
            for var in variables:
                if var in tokens.KEYWORDS.keys():
                    exceptions[idx].append(
                        Exception(f"Line {idx}: variable `{id_}` is named as a keyword")
                    )
                elif ts_id.get_(var):
                    exceptions[idx].append(
                        Exception(
                            f"Line {idx}: variable `{var}` has already been declared"
                        )
                    )
                else:
                    ts_id.set_(var, curr_id)
                    curr_id += 1

            # Analyzing EXPRESSIONS
            for expr_ in expressions:
                for i, elem in enumerate(expr_.split()):
                    # Should be an identifier/constant
                    if i % 2 == 0:
                        # Verifying if the expression element is a reserved keyword
                        if elem.lower() in tokens.KEYWORDS.keys() and elem not in [
                            "ID",
                            "CONST",
                        ]:
                            exceptions[idx].append(
                                Exception(
                                    f"Line {idx}: variable `{id_}` is named as a keyword"
                                )
                            )
                        # Considering identifiers as expression elements
                        # and verifying if any prior declaration was made before referencing
                        elif tokens.RE_IDENTIFIER.match(elem):
                            if not ts_id.get_(elem):
                                exceptions[idx].append(
                                    Exception(
                                        f"Line {idx}: prior declaration of `{elem}` not found"
                                    )
                                )
                        else:
                            # Finding the type and associated value of the element
                            found_type = ""
                            for type_, re_type in tokens.RE_TYPES.items():
                                if re_type.match(elem):
                                    found_type = type_
                                    break

                            if not found_type:
                                exceptions[idx].append(
                                    Exception(
                                        f"Line {idx}: `{elem}` not in accepted types"
                                    )
                                )
                            else:
                                # Adding the constant in the table of constants if not already added
                                if not ts_const.get_(elem):
                                    ts_const.set_(elem, curr_const)
                                    curr_const += 1
                    else:
                        # Verifying if the operator is in the accepted operators
                        if elem not in list(tokens.BINARY_OPERATORS) + list(
                            tokens.RELATIONAL_OPERATORS
                        ):
                            exceptions[idx].append(
                                Exception(
                                    f"Line {idx}: `{elem}` is not an accepted operator"
                                )
                            )

    return ts_id, ts_const, exceptions


def retrieve_decl_attr_matching_lines(file_content: str) -> List[str]:
    """
    Retrieves the lines containing declarations or attributions

    :param str file_content: The content of the file passed to the lexer
    :return List[str]: The declarations/attributions lines
    """
    decl_attr_lines = []
    for line in file_content.split("\n"):
        line = line.rstrip("stop").strip()
        if tokens.RE_DECL.search(line):
            decl_attr_lines.append(line)
        elif tokens.RE_ATTRIB.search(line):
            decl_attr_lines.append(line)

    return decl_attr_lines


def get_FIP_and_TS(
    file_content: str,
) -> Tuple[
    List[Dict[int, Union[int, None]]],
    HM,
    HM,
    Dict[int, List[Exception]],
    Dict[int, List[Exception]],
]:
    """
    Returns the FIP, TS and any lexical exceptions, if any,
    encountered in the process of retrieving those tables

    :param str file_content: The content of the file passed to the lexer
    :return Tuple[List[Dict[int, Union[int, None]]], HM Dict[int, List[Exception]]]: the FIP and TS tables, along with any exceptions
    """
    fip = []
    exceptions = {}

    # Finding all declared structs in the program
    structs = tokens.RE_STRUCT.findall(file_content)
    known_structs: Set[str] = set()

    for idx, match_ in enumerate(structs):
        exceptions[idx] = []

        struct_name = match_[0].strip()
        fields = [field.strip() for field in match_[1].split("\n")]

        for field in fields:
            field_name, field_type, stop_str = field.split()

            if stop_str != "stop":
                exceptions[idx].append(
                    Exception(
                        f"Struct no. {idx}: the the line field doesn't end with `stop`"
                    )
                )

            if field_type not in tokens.RE_TYPES.keys() or (
                field_type == "struct" and field_name not in known_structs
            ):
                exceptions[idx].append(
                    Exception(f"Struct no. {idx}: field `{field_name}` type unknown")
                )

        if not exceptions[idx]:
            known_structs.add(struct_name)

    ts_id, ts_const, ts_exceptions = get_TS(
        retrieve_decl_attr_matching_lines(file_content), known_structs
    )

    # Jumping to the "func main () {...}" line
    main_line = file_content.find("func main")
    file_content = file_content[main_line:]

    # Parsing line by line
    for idx, line in enumerate(file_content.split("\n")):
        tokens_ = [token.strip() for token in line.split()]

        if not tokens_:
            continue

        exceptions[idx] = []
        # Skipping the IO operations -> momentarily
        if tokens.RE_IO.match(line.strip()):
            instr = line.strip().split()[0]
            fip.append({tokens.KEYWORDS[instr]: None})
            continue

        for token in tokens_:
            if token in ts_id.keys:
                fip.append({tokens.KEYWORDS["ID"]: ts_id.get_(token)})
            elif token in ts_const.keys:
                fip.append({tokens.KEYWORDS["CONST"]: ts_const.get_(token)})
            else:
                # Verifying if the token is a reserved keyword
                if token in tokens.KEYWORDS.keys():
                    fip.append({tokens.KEYWORDS[token]: None})
                else:
                    exceptions[idx].append(
                        Exception(
                            f"Line {idx}: `{token}` is neither a variable, constant or a reserved keyword"
                        )
                    )

    return fip, ts_id, ts_const, exceptions, ts_exceptions


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <path to the code file>")
        sys.exit(1)

    code_abs_path = os.path.abspath(sys.argv[1])
    with open(code_abs_path, "r") as fin:
        content = fin.read()

        # Retrieving the FIP, TS and any exceptions
        fip, ts_id, ts_const, fip_exceptions, ts_exceptions = get_FIP_and_TS(content)
        all_exceptions = (("FIP", fip_exceptions), ("TS", ts_exceptions))

        # Writing table data into CSVs
        write_table_values(ts_id, TS_ID_CSV_PATH, table_name="ts_id")
        write_table_values(ts_const, TS_CONST_CSV_PATH, table_name="ts_const")
        write_table_values(fip, FIP_CSV_PATH, table_name="fip")

        # Writing all encountered exceptions
        write_exceptions(all_exceptions, EXCEPTIONS_CSV_PATH)

    print("Done!")
