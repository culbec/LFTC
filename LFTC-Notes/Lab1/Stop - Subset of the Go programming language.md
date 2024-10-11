# Intro

_**Stop**_ is a version of the _**Go**_ programming language that makes the user use **_round-brackets_** for expressions and the word _**stop**_ for indicating the end of the line.

The specification of the _**Go**_ language can be found [here](https://go.dev/ref/spec).

# Language Specification

I chose [EBNF](https://en.wikipedia.org/wiki/Extended_Backus%E2%80%93Naur_form) to specify my _**Stop**_, although the _**Go**_ language uses [WSN](https://en.wikipedia.org/wiki/Wirth_syntax_notation) for specification.

1. **ID** = Letter {Letter | "\_" | Digit} .
	1. **Letter** = "a" | "b" | ... | "z" | "A" | "B" | ... | "Z" .
	2. **Digit** = "0" | "1" | ... "9" .
	3. **NonZeroDigit** = "1" | "2" | ... | "9" .
	4. **Character** = "all ASCII characters" .
2. **CONST** = "strings and numbers of R" .
3. **Type** = Integer | Float | String | Struct .
	1. **Integer** = \[Sign\] UnsignedInteger .
		1. **Sign** = "+" | "-" .
		2. **UnsignedInteger** = NonZeroDigit {Digit} .
	2. **Float** = Digit "." Digit {Digit} .
	3. **String** = " " " Character {Character} " " " .
	4. **Struct** =  "struct" "{" {ID Type "stop"} "}" .
4. **Program** = "func main ()" "{" InstrList "}" .
	1. **InstrList** = Instr {InstrList} "stop" .
	2. **Instr** = Decl | Attr |  IO | Cond | Rep .
		1. **Attr** = ID "=" Expr "stop" .
			1. **Expr** = ID | CONST | ID Op ID | ID Op Const | CONST Op ID | ID Op Expr .
				1. **Op** = BinaryOp | RelOp .
					1. **BinaryOp** = "+" | "-" | "%" | "\*" | "/" .
					2. **RelOp** = "<" | ">" | "<=" | ">=" .
		2. **Decl** = "var" ID {"," ID} Type "=" Expr {"," Expr} | ID {"," ID}" ":=" Expr {"," Expr} "stop" . 
		3. **IO** = "fmt.Scan(&" ID ") stop" | "fmt.Print(" Expr {"," Expr} ") stop" | "fmt.Println(" Expr {"," Expr} ") stop" .
		4. **Cond** = "if (" LogicStatement ") {" InstrList "}" {"elif (" LogicStatement ") {" InstrList "}"} {"else {" InstrList "}"} .
			1. **LogicStatement** = ID RelOp ID | ID RelOp CONST | CONST RelOp ID | CONST RelOp CONST .
		5. **Rep** = "for (" LogicStatement ") {" {InstrList} "}" .

# Correct 3 mini-programs in Stop
### First program

Perimeter and area of a circle with a given radius.

```
func main () {
	var float r = 2.0 stop
	var float PI = 3.14 stop

	p := 2 * PI * r stop
	a := PI * r * r stop
	fmt.Println(p) stop
	fmt.Println(a) stop
}
```

### Second program

GCD of two natural numbers.

```
func main () {
	var a, b int = 8, 12 stop

	if (a < b) {
		a = b stop
	}

	for (b != 0) {
		r := a % b stop
		a = b stop
		b = r stop
	}

	fmt.Println(a) stop
}
```

### Third program

Sum of n number read from stdin.

```
func main () {
	var n int = 5 stop
	sum := 0 stop

	fmt.Scan(&n) stop

	for (n > 0) {
		var num int stop

		fmt.Scan(&num) stop
		sum = sum + num stop
		n = n - 1 stop
	}

	fmt.Println(sum) stop
}
```

# Errors in Stop / Go

### 2 Errors in Stop + Go

```
func main () {
	var a, b int, float stop // we can't declare types for all variables inline

	sum = a + b stop // undeclared variable

	fmt.Println(sum) stop
}
```

### 2 Errors in Stop, not in Go

```
func main () {
	var a,b int = 3, 3 // forgot 'stop', in Go there is no endline char

	c := &a stop // Stop doesn't support pointers
}
```
