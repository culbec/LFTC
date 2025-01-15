from typing import List
from transition import Transition

class FA(object):
    def __init__(
        self,
        alphabet: List[str],
        states: List[str],
        initial_state: str,
        final_states: List[str],
        transitions: List[Transition],
    ):
        self.alphabet = alphabet if alphabet else []
        self.states = states if states else []
        self.initial_state = initial_state if initial_state else ""
        self.final_states = final_states if final_states else []
        self.transitions = transitions if transitions else []

    def check_sequence(self, sequence: str, current_state=None) -> bool:
        """
        Verifies if a sequence is accepted by the finite automata

        :param str sequence: The sequence to be checked
        :param current_state: The current state of the finite automata
        :return bool: True if the sequence is accepted, False otherwise
        """
        if not current_state:
            current_state = self.initial_state

        # Base case: empty sequence
        if not sequence:
            return current_state in self.final_states

        for t in self.transitions:
            # Checking if the transition source corresponds with the current state
            # and checking if the transition's value is a prefix of the sequence
            if t.source == current_state and sequence.startswith(t.value):
                next_sequence = sequence[
                    len(t.value) :
                ]  # the next sequence is the remaining part of the current sequence

                # Recursive checking all other transitions
                # It is possible that the FA is non-deterministic,
                # so we need to check all possible transitions
                if self.check_sequence(next_sequence, t.destination):
                    return True

        # Invalid state
        return False

    def longest_prefix(self, sequence: str, current_state=None, prefix="") -> str:
        """
        Returns the longest accepted prefix of the sequence

        :param str sequence: The sequence to check
        :param current_state: The current state of the finite automata
        :param str prefix: The longest accepted prefix of the sequence
        :return str: The longest accepted prefix by the finite automata of the sequence
        """
        if not current_state:
            current_state = self.initial_state

        # Base case: empty sequence
        if not sequence:
            return prefix

        longest_prefix = prefix

        for t in self.transitions:
            if t.source == current_state and sequence.startswith(t.value):
                new_prefix = prefix + t.value
                next_sequence = sequence[len(t.value) :]

                next_prefix = self.longest_prefix(
                    next_sequence, t.destination, new_prefix
                )

                # Checking if we found a longer prefix between the transitions
                if len(next_prefix) > len(longest_prefix):
                    longest_prefix = next_prefix

        return longest_prefix
