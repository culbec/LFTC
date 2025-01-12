import os

from typing import Optional, Dict, Set, List, Union, Tuple

# NOTE: Considering 'EPSILON' as epsilon


class Rule(object):
    def __init__(self, lhs: str, rhs: List[str], dot_pos: int = 0):
        self.lhs = lhs
        self.rhs = rhs
        self.dot_pos = dot_pos

    @property
    def production(self) -> str:
        """Returns the production rule without the dot."""
        return f"{self.lhs} -> {self.rhs}"

    def advance_dot(self) -> "Rule":
        """Returns a new rule with the dot advanced by one position."""
        return Rule(self.lhs, self.rhs, self.dot_pos + 1)

    def __eq__(self, other: "Rule"):
        return (
            self.lhs == other.lhs
            and self.rhs == other.rhs
            and self.dot_pos == other.dot_pos
        )

    def __hash__(self):
        rhs_hash = sum(hash(x) for x in self.rhs)
        return hash(self.lhs) + rhs_hash + hash(self.dot_pos)

    def __str__(self):
        # Putting the dot in the right place
        rhs = (
            " ".join(self.rhs[: self.dot_pos])
            + "."
            + " ".join(self.rhs[self.dot_pos :])
        )

        return f"{self.lhs} -> {rhs}"

    def __repr__(self):
        return str(self)


class State:
    def __init__(self, number: int, rules: list[Rule] = []):
        self.number = number
        self.rules = rules

    def __eq__(self, other: "State"):
        return self.rules == other.rules

    def __hash__(self):
        return hash(str(self.rules)) + hash(self.number)

    def __str__(self):
        s = f"State {self.number}:\n"
        for rule in self.rules:
            s += f"\t{rule}\n"

        return s

    def __repr__(self):
        return str(self)


class Transition:
    def __init__(self, from_state: int, to_state: int, symbol: str):
        self.from_state = from_state
        self.to_state = to_state
        self.symbol = symbol

    def __str__(self):
        return f"{self.from_state} --{self.symbol}--> {self.to_state}"

    def __repr__(self):
        return str(self)


class Action:
    SHIFT = "S"
    REDUCE = "R"
    ACCEPT = "ACC"
    ERROR = "ERR"

    def __init__(self, action_type: str, value: int):
        self.action_type = action_type
        self.value = value

    def __str__(self):
        return f"{self.action_type} -> {self.value}"

    def __repr__(self):
        return str(self)


class Parser:
    def __init__(self, grammar_file: str = "data/grammar.txt", is_code_file: bool = False):
        # Grammar properties
        self.terminals: Set[str] = set("$")
        self.non_terminals: Set[str] = set()
        self.start_symbol: Optional[str] = None

        # Internal Parser format
        self.states: List[State] = []
        self.transitions: List[Transition] = []
        self.firsts: Dict[str, Set[str]] = {}
        self.follows: Dict[str, Set[str]] = {}
        self.parse_table: Dict[str, Dict[Tuple[int, str], Union[Action, int]]] = {}
        self.debug_file = os.path.join("data", "debug.txt")

        # Initialize the parser
        self.is_code_file = is_code_file
        self.__load_grammar(grammar_file)
        
        # NOTE: FIRST and FOLLOW are not explicitly used by this SLR parser
        # They are computed for completeness and debugging purposes
        self.__first()
        self.__follow()
        
        self.__build_canonical_collection()
        self.parse_table = self.__build_parse_table()
        self.__write_debug_info()

    def __write_debug_info(self):
        """
        Writes debug info to the debug file.
        
        Debug info means the internal parser format.
        """
        with open(self.debug_file, "w") as f:
            f.write("States:\n")
            for state in self.states:
                f.write(f"{state}\n")

            f.write("\nTransitions:\n")
            for transition in self.transitions:
                f.write(f"{transition}\n")
                
            f.write("\nFIRST sets:\n")
            for symbol, first_set in self.firsts.items():
                f.write(f"{symbol}: {first_set}\n")
                
            f.write("\nFOLLOW sets:\n")
            for symbol, follow_set in self.follows.items():
                f.write(f"{symbol}: {follow_set}\n") 

    def __init_augmented_rule(self):
        """
        Initializes the augmented rule S' -> S required for the SLR parser.
        """
        first_rule = self.rules[0]
        augmented_rule = Rule(first_rule.lhs + "'", [first_rule.lhs])
        self.rules.insert(0, augmented_rule)

        self.start_symbol = augmented_rule.lhs
        self.non_terminals.add(augmented_rule.lhs)

        # For the first state, add the augmented rule
        # and all rules of the non-terminals that are preceded by the dot
        initial_state = State(0, self.__closure([augmented_rule]))

        self.states.append(initial_state)

    def __first(self) -> None:
        """Computes FIRST sets for all grammar symbols"""
        self.firsts = {symbol: set() for symbol in self.terminals | self.non_terminals}

        # Add terminals to their own FIRST sets
        for terminal in self.terminals:
            self.firsts[terminal].add(terminal)

        changed = True
        while changed:
            changed = False

            for rule in self.rules:
                # Skip augmented rule
                if rule.lhs == self.rules[0].lhs:
                    continue

                # Store current FIRST set size for comparison
                old_size = len(self.firsts[rule.lhs])

                # Process RHS symbols
                first_of_rhs = set()
                all_can_be_empty = True

                for symbol in rule.rhs:
                    # Add first set of current symbol
                    symbol_first = self.firsts[symbol]
                    first_of_rhs.update(symbol_first - {"EPSILON"})

                    # Check if we can continue to next symbol
                    if "EPSILON" not in symbol_first:
                        all_can_be_empty = False
                        break

                # Add epsilon if all symbols can be empty
                if all_can_be_empty:
                    first_of_rhs.add("EPSILON")

                # Update FIRST set and check for changes
                self.firsts[rule.lhs].update(first_of_rhs)
                if len(self.firsts[rule.lhs]) > old_size:
                    changed = True

    def __follow(self) -> None:
        """Computes FOLLOW sets for all non-terminals"""
        self.follows = {nt: set() for nt in self.non_terminals}

        # Add $ to start symbol's FOLLOW set
        self.follows[self.start_symbol].add("$")

        changed = True
        while changed:
            changed = False

            for rule in self.rules:
                # Skip augmented rule
                if rule.lhs == self.rules[0].lhs:
                    continue

                # Process each symbol in RHS
                for i, symbol in enumerate(rule.rhs):
                    if symbol not in self.non_terminals:
                        continue

                    old_size = len(self.follows[symbol])

                    # Case 1: A → αBβ
                    if i < len(rule.rhs) - 1:
                        # Add FIRST(β) - {ε} to FOLLOW(B)
                        rest = rule.rhs[i + 1]
                        self.follows[symbol].update(self.firsts[rest] - {"EPSILON"})

                    # Case 2: A → αB or A → αBβ where β →* ε
                    if (
                        i == len(rule.rhs) - 1
                        or "EPSILON" in self.firsts[rule.rhs[i + 1]]
                    ):
                        self.follows[symbol].update(self.follows[rule.lhs])

                    # Check if we added anything new
                    if len(self.follows[symbol]) > old_size:
                        changed = True

    def __load_grammar(self, grammar_file: str) -> None:
        """
        Loads the Grammar from the specified file.

        :param str grammar_file: The grammar file to load the rules from.
        :raises FileNotFoundError: If the grammar file is not found.
        """
        if not os.path.exists(grammar_file):
            raise FileNotFoundError(f"File {grammar_file} not found")

        rules: List[Rule] = []

        with open(grammar_file, "r") as f:
            for line in f.readlines():
                if not line:
                    continue
                
                lhs, rhs = [x.strip() for x in line.strip().split("->")]

                # Save lhs as a non-terminal
                self.non_terminals.add(lhs)

                # Transforming the grammar into a context independent form
                # if that is not the case already
                rhs_parts = rhs.split("|")

                for rhs_part in rhs_parts:
                    '''
                        NOTE: We suppose that the grammar is of the form: `NT -> A _space_ a _space B | ...`
                        
                        In this way, we can split the tokens by space and check if the token is a terminal or non-terminal.
                        
                        We could've kept an alphabet of terminals and non-terminals and check if the token is in the alphabet,
                        by computing the longest prefix of the token that is in the alphabet.
                        
                        TODO: maybe change the representation of the grammar to also include an alphabet of terminals and non-terminals
                    '''
                    rhs_part = rhs_part.strip().split()

                    for symbol in rhs_part:
                        if not self.is_code_file:
                            # Saving the symbol as a terminal/non-terminal
                            if symbol.isupper():
                                self.non_terminals.add(symbol)
                            else:
                                self.terminals.add(symbol)
                        else:
                            if symbol.startswith('"') and symbol.endswith('"'):
                                self.terminals.add(symbol[1:-1])
                            else:
                                self.non_terminals.add(symbol)
                                
                            # Stripping all quotes from non-terminals
                            rhs_part = [x.strip('"') for x in rhs_part]

                    # Save the rule
                    rules.append(Rule(lhs, rhs_part))

        self.rules = rules
        self.__init_augmented_rule()

    def __closure(self, rules: List[Rule]) -> List[Rule]:
        """
        Computes the closure of a set of rules.

        :param List[Rule] rules: The rules to compute the closure for.
        :return List[Rule]: The closure of the rules.
        """
        closure = []
        rules_to_process = list(rules)
        seen_rules = set()

        while rules_to_process:
            rule = rules_to_process.pop(0)
            if rule not in seen_rules:
                seen_rules.add(rule)
                closure.append(rule)

                if rule.dot_pos < len(rule.rhs):
                    symbol = rule.rhs[rule.dot_pos]
                    if symbol in self.non_terminals:
                        for prod in self.rules:
                            if prod.lhs == symbol:
                                new_rule = Rule(prod.lhs, prod.rhs, 0)
                                if new_rule not in seen_rules:
                                    rules_to_process.append(new_rule)

        return closure

    def __goto(self, state: State) -> List[State]:
        """
        Computes the GOTO transitions for a given state.
        
        Also updates the transitions list with the new transitions if that is the case.

        :param State state: The state to compute the GOTO transitions for.
        :return list[State]: The list of states that can be reached from the given state.
        """

        new_states = []
        processed_symbols = set()

        for rule in state.rules:
            # Skip rules that can't advance
            if rule.dot_pos >= len(rule.rhs):
                continue

            # Skip already processed symbols
            symbol = rule.rhs[rule.dot_pos]
            if symbol in processed_symbols:
                continue

            processed_symbols.add(symbol)
            next_state_rules = []

            # Find all rules that can advance on this symbol
            for current_rule in state.rules:
                if (
                    current_rule.dot_pos < len(current_rule.rhs)
                    and current_rule.rhs[current_rule.dot_pos] == symbol
                ):
                    next_state_rules.append(current_rule.advance_dot())

            if next_state_rules:
                # Create new state with its closure
                new_state = State(len(self.states))
                new_state.rules = self.__closure(next_state_rules)

                # Find if state already exists
                existing_state = None
                for s in self.states:
                    if s == new_state:
                        existing_state = s
                        break

                # Add the transition
                # NOTE: if the transition already exists, add the link
                # NOTE: if the transition doesn't exist, add the state
                if existing_state is None:
                    self.states.append(new_state)
                    new_states.append(new_state)
                    transition = Transition(state.number, new_state.number, symbol)
                else:
                    transition = Transition(state.number, existing_state.number, symbol)

                self.transitions.append(transition)

        return new_states

    def __build_canonical_collection(self):
        """
        Builds the canonical collection of LR(0) items.
        """
        unprocessed_states = [self.states[0]]

        while unprocessed_states:
            current_state = unprocessed_states.pop(0)
            new_states = self.__goto(current_state)
            unprocessed_states.extend(new_states)

    def __build_parse_table(self):
        """
        Builds the parse table for the grammar by using
        the canonical collection of LR(0) items.
        """
        action, goto = {}, {}

        for state in self.states:
            # Find all SHIFT and GOTO transitions
            for transition in self.transitions:
                if transition.from_state == state.number:
                    symbol = transition.symbol

                    if symbol in self.terminals:
                        # SHIFT if terminal
                        action[(state.number, symbol)] = Action(
                            Action.SHIFT, transition.to_state
                        )
                    else:
                        # GOTO if non-terminal
                        goto[(state.number, symbol)] = transition.to_state

            # Find all REDUCE
            for idx, rule in enumerate(state.rules):
                # '.' is at the end of the rule
                if rule.dot_pos == len(rule.rhs):
                    if rule.lhs == self.rules[0].lhs:
                        # Accept if the rule is S' -> S
                        action[(state.number, "$")] = Action(Action.ACCEPT, 0)
                    else:
                        for terminal in self.terminals:
                            action[(state.number, terminal)] = Action(
                                Action.REDUCE, idx
                            )

        return {"action": action, "goto": goto}

    def __longest_prefix(self, string: str, symbols: Set[str]) -> str:
        """
        Returns the longest prefix of the string that is in the set of symbols.

        :param str string: The string to check.
        :param Set[str] symbols: The set of symbols to check against.
        :return str: The longest prefix of the string that is in the set of symbols.
        """
        # Check if string starts with any symbol
        for symbol in symbols:
            if string.startswith(symbol):
                return symbol

        return ""

    def parse(self, input_str: str) -> Tuple[bool, str | List[str]]:
        """
        Parses the input string using the grammar and the SLR table.

        :param str input_str: The input string to parse.
        :return tuple[bool, str | list]: The status of the parsing and a message of error or the transitions
                                         that led to the acceptance of the input string.
        """
        
        if not input_str:
            return False, "Error: Empty input string"

        print("Parsing the input string...")

        stack = [0]
        symbols = []
        transitions = []

        # Computing the longest prefix of the input string that is in the terminals
        tokens = []
        
        if not self.is_code_file:
            while input_str:
                prefix = self.__longest_prefix(input_str, self.terminals)
                if not prefix:
                    return (
                        False,
                        f"Error: Invalid symbol in the input string: {input_str[0]}",
                    )

                tokens.append(prefix)
                input_str = input_str[len(prefix) :]
        else:
            if not os.path.exists(input_str):
                return False, f"Error: File {input_str} not found"

            with open(input_str, "r") as f:
                for line in f.readlines():
                    line = line.strip()
                    if not line:
                        continue

                    tokens.extend(line.split())

        tokens += ["$"]

        while True:
            state = stack[-1]
            current_token = tokens.pop(0)
            
            # Check if there is an action for the current state and symbol
            if (state, current_token) not in self.parse_table["action"]:
                return (
                    False,
                    f"Error: No action for state {state} and symbol {current_token}",
                )

            # Get the action for the current state and symbol
            action = self.parse_table["action"][(state, current_token)]

            if action.action_type == Action.SHIFT:
                # Shift the current token
                stack.append(action.value)
                symbols.append(current_token)

                transitions.append(f"Shift: {current_token}, goto state {action.value}")

            elif action.action_type == Action.REDUCE:
                # Reduce using the rule
                rule = self.rules[action.value]

                for _ in range(len(rule.rhs)):
                    stack.pop()
                    symbols.pop()

                # If we reduce to S', we should be finished
                if rule.lhs == self.start_symbol:
                    print(f"Tokens: {tokens} | Stack: {stack} | Symbols: {symbols}")
                    if len(tokens) <= 1 and tokens[0] == "$":
                        transitions.append(f"Accept: through token {current_token}")
                        return True, transitions
                    else:
                        return False, "Error: Extra input after reduction to start symbol"

                goto_state = self.parse_table["goto"].get((stack[-1], rule.lhs))

                if goto_state is None:
                    return (
                        False,
                        f"Error: No goto state for state {stack[-1]} and symbol {rule.lhs}",
                    )

                stack.append(goto_state)
                symbols.append(rule.lhs)
                transitions.append(
                    f"Reduce: Using rule {rule.production()}, goto state {goto_state}"
                )

            elif action.action_type == Action.ACCEPT:
                # Accept the input string
                transitions.append("Accept: Input sequence is valid")
                return True, transitions
