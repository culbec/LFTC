class HashMap(object):
    def __init__(self, size: int = 10):
        self.size = size
        self.keys = []
        self.map = [None] * size

    def _hash(self, key: str) -> int:
        return sum([ord(char) for char in key]) % self.size

    def _resize(self) -> None:
        self.size *= 2

        # Rebuiding the map according to the new size
        new_map = [None] * self.size
        for value in self.map:
            if value:
                new_map[self._hash(str(value))] = value
        self.map = new_map

    def _solve_collision(self, key: str, value: any) -> None:
        # Verifying if all the indexes are filled
        if all(self.map):
            self._resize()

        index = self._hash(key)
        # Solving collisions by linear probing
        while self.map[index]:
            index = (index + 1) % self.size

        self.keys.append(key)
        self.map[index] = value

    def set_(self, key: str, value: any) -> None:
        self._solve_collision(key, value)

    def get_(self, key: str, default: any = None) -> any:
        index = self._hash(key)

        return self.map[index] if self.map[index] else default

    def __str__(self) -> str:
        return f"{str(self.keys)}: {str(self.map)}"
