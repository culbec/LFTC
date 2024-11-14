import os
from finite_automata import FA, Transition
from lexical_analyzer.tokens import *
import time

# Paths to the finite automata files
FA_PATHS = [
    os.path.join(".", "lexical_analyzer", "fas", "fa_stop_INT.txt"),
    os.path.join(".", "lexical_analyzer", "fas", "fa_stop_FLOAT.txt"),
    os.path.join(".", "lexical_analyzer", "fas", "fa_stop_ID.txt"),
]


class Scanner(object):
    def __init__(self):
        self.__fas: dict[str, FA] = {}

        self.__initialize()

    def __initialize(self):
        """
        Initializes the Finite Automatas by reading the
        contents from each FA file
        """
        for fa_path in FA_PATHS:
            if not os.path.exists(fa_path):
                raise RuntimeError(f"Invalid finite automata path! By: {fa_path}")

            alphabet = []
            states = []
            initial_state = ""
            final_states = []
            transitions = []

            with open(fa_path, "r") as fin:
                alphabet = [x.strip() for x in fin.readline().strip().split(",")]
                states = [x.strip() for x in fin.readline().strip().split(",")]
                initial_state = fin.readline().strip()
                final_states = [x.strip() for x in fin.readline().strip().split(",")]

                for line in fin:
                    source, destination, value = line.strip().split(",")
                    transitions.append(Transition(source, destination, value))

            fa = FA(alphabet, states, initial_state, final_states, transitions)
            fa_kind = fa_path.split("fa_stop_")[1].split(".txt")[0].strip()
            self.__fas[fa_kind] = fa

    def _is_escaped_quote(self, line: str, index: int) -> bool:
        """
        Returns whether the quote at the specified index is escaped or not

        :param str line: The line to check
        :param int index: The index to check
        :return bool: Whether the quote is escaped or not
        """
        return False if index == 0 else line[index - 1] == "\\"

    def _get_string_token(self, line: str, index: int) -> tuple[str, int]:
        """
        Returns the string token from the specified line and index

        :param str line: The line to extract the token from
        :param int index: The index to start from
        :return tuple[str, int]: The string token and the new index
        """
        token = ""

        # Keeping track of how many quotes we have encountered so far
        quotes = 0

        while index < len(line) and quotes < 2:
            if line[index] == '"' and self._is_escaped_quote(line, index):
                quotes += 1
            token += line[index]
            index += 1

        return token, index

    def tokenize(self, line: str) -> list[dict[str, str]]:
        """
        Tokenizes the specified line

        :param str line: The line to tokenize
        :return list[dict[str, str]]: The tokens
        """
        buffer, idx = line.lstrip(), 0
        tokens = []

        while buffer:
            curr_token = ""
            token_type = "unknown"
            idx = 0

            # Check if the token is a reserved word
            for reserved in RESERVED:
                if buffer.startswith(reserved) and len(reserved) > len(curr_token):
                    curr_token, token_type = reserved, "RESERVED"

            # Check if the token is an operator
            for operator in OPERATORS:
                if buffer.startswith(operator) and len(operator) > len(curr_token):
                    curr_token, token_type = operator, "OPERATOR"

            # Check if the token is a separator
            for separator in SEPARATORS:
                if buffer.startswith(separator) and len(separator) > len(curr_token):
                    curr_token, token_type = separator, "SEPARATOR"

            # Checking if the token is a string
            if buffer.startswith('"'):
                curr_token, idx = self._get_string_token(buffer, idx)

                # Check if the string token ends with a quote
                if curr_token.endswith('"'):
                    token_type = "STRING"
                else:
                    token_type = "unknown"

            # Scanning the token with the Finite Automatas
            if not curr_token:
                while idx < len(buffer) and buffer[idx] not in SEPARATORS:
                    curr_token += buffer[idx]
                    idx += 1

                curr_token = curr_token.strip()
                token_type = self._scan(curr_token)

            # Updating the buffer and the index
            buffer = buffer[len(curr_token) :].lstrip()

            tokens.append({"value": curr_token, "type": token_type})
            curr_token = ""

        return tokens

    def _scan(self, token: str) -> str:
        """
        Scans a token and returns its kind

        :param str token: The token to scan
        :return str: The kind of the token
        """
        for fa_kind, fa in self.__fas.items():
            if fa.check_sequence(token):
                return fa_kind

        return "unknown"
