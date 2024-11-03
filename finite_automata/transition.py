class Transition(object):
    def __init__(self, source: "Transition", destination: "Transition", value: str):
        self.source = source
        self.destination = destination
        self.value = value

    def __str__(self):
        return f"({self.source}, {self.destination}) ---> {self.value}"
