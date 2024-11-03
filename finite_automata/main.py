import sys

from finite_automata import FA
from transition import Transition
from typing import Dict, Union, List
from collections.abc import Callable


def from_file(file_path: str) -> FA:
    """
    Reads a finite automata from a file

    :param str file_path: The file path of the file containing the finite automata
    :return FA: The finite automata read from file
    """
    alphabet = []
    states = []
    initial_state = ""
    final_states = []
    transitions = []

    with open(file_path, "r") as fin:
        alphabet = [x.strip() for x in fin.readline().strip().split(",")]
        states = [x.strip() for x in fin.readline().strip().split(",")]
        initial_state = fin.readline().strip()
        final_states = [x.strip() for x in fin.readline().strip().split(",")]

        for line in fin:
            source, destination, value = line.strip().split(",")
            transitions.append(Transition(source, destination, value))

    return FA(alphabet, states, initial_state, final_states, transitions)


def from_cli() -> FA:
    """
    Reads a finite automata from the command line

    :return FA: The finite automata read from the command line
    """
    alphabet = input("Enter the alphabet: ").strip().split(",")
    for i in range(len(alphabet)):
        alphabet[i] = alphabet[i].strip()

    states = input("Enter the states: ").strip().split(",")
    for i in range(len(states)):
        states[i] = states[i].strip()

    initial_state = input("Enter the initial state: ").strip()

    final_states = input("Enter the final states: ").strip().split(",")
    for i in range(len(final_states)):
        final_states[i] = final_states[i].strip()

    transitions = []
    print("Enter the transitions (source, destination, value):")
    while True:
        try:
            source, destination, value = input().strip().split(",")
            transitions.append(Transition(source, destination, value))
        except ValueError:
            break

    return FA(alphabet, states, initial_state, final_states, transitions)


def print_alphabet(fa: FA):
    """
    Prints the alphabet of the finite automata

    :param FA fa: The finite automata
    """
    print("Alphabet:", ", ".join(fa.alphabet).strip())


def print_states(fa: FA):
    """
    Prints the states of the finite automata

    :param FA fa: The finite automata
    """
    print("States:", ", ".join(fa.states).strip())


def print_final_states(fa: FA):
    """
    Prints the final states of the finite automata

    :param FA fa: The finite automata
    """
    print("Final States:", ", ".join(fa.final_states).strip())


def print_transitions(fa: FA):
    """
    Prints the transitions of the finite automata

    :param FA fa: The finite automata
    """
    print("Transitions:")
    for t in fa.transitions:
        print(t)


def check_sequence(fa: FA):
    """
    Checks if a sequence is accepted by the finite automata

    :param FA fa: The finite automata
    """
    sequence = input("Enter the sequence to check: ").strip()

    if fa.check_sequence(sequence):
        print("The sequence is accepted.")
    else:
        print("The sequence is not accepted.")


def longest_prefix(fa: FA):
    """
    Prints the longest accepted prefix of a sequence by the finite automata

    :param FA fa: The finite automata
    """
    sequence = input("Enter the sequence to check: ").strip()

    print("The longest accepted prefix is:", fa.longest_prefix(sequence))


COMMANDS: Dict[str, Callable[[Union[FA, None]], None]] = {
    "alphabet": print_alphabet,
    "states": print_states,
    "final_states": print_final_states,
    "transitions": print_transitions,
    "check_sequence": check_sequence,
    "longest_prefix": longest_prefix,
    "exit": lambda _: (print("Exiting..."), sys.exit(0)),
}


def print_help():
    """
    Prints the available commands
    """
    print("Available commands:")
    print(" ".join(COMMANDS.keys()))


if __name__ == "__main__":
    if len(sys.argv) == 2:
        fa = from_file(sys.argv[1])
    else:
        fa = from_cli()

    while True:
        print_help()
        command = input("Enter a command: ").strip()
        method = COMMANDS.get(command)

        if not method:
            print("Invalid command: ", command, "\n")
            continue

        method(fa)
        print()
