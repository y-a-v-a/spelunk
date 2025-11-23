**tau-core** — spelunking-level language (v0)

Built for tools and LLMs first: minimal surface, deterministic structure, explicit control flow, and canonical formatting.

> Keep in mind that this programming language should be simple, predictable, and very friendly as a reasoning/IR layer, compact, deterministic, strongly typed, not necessarily human readable (spelunking good enough for humans), LLM-friendly, token efficient, canonical formatted language.

---

## 0. Design snapshot

* line-based, no nested blocks
* strictly typed, no inference or coercions
* move semantics by default (Rust-lite copy/move split, no borrows yet)
* explicit returns only (`^expr`)
* minimal control constructs (guards, pipe-match)
* canonical formatting is part of the spec

---

## 1. File / module structure

Each file (one module):

```tau
mod math        // optional, at most one per file

use other::foo  // zero or more imports

type ...        // type declarations
fn ...          // function declarations
test ...        // test declarations
```

Formatter ordering: `mod` (if present), all `use` (sorted), then `type`/`fn`/`test` in source order.

### Modules and imports

* At most one `mod` declaration per file; multiple `mod` declarations are a compile-time error.
* `use` imports resolve names into the current file’s namespace.
* Shadowing:
  * Local bindings (variables, parameters) shadow imported names.
  * Later `use` statements do not shadow earlier ones; duplicate imports of the same item are allowed but redundant.
  * Importing two items with the same final name (e.g., `foo::A` and `bar::A`) is a compile error in v0 (no renames).
* Any `use` that cannot be resolved is a compile-time error.

Static checks (semantic, not grammar):

* Only one `mod` per file.
* `use` targets must resolve; otherwise compile error.
* Importing two items with the same final name is an error (no renames in v0); duplicate identical imports are allowed but redundant.

---

## 2. Lexical rules

### 2.1 Identifiers

* Terms (vars, functions, modules): `[a-z_][a-zA-Z0-9_]*` and mutable form `name!`.
* Types: `[A-Z][a-zA-Z0-9_]*`.
* No keyword reuse.

### 2.2 Keywords

`mod use type fn test true false`

### 2.3 Literals

* Integers: `0`, `42` (no suffixes)
* Floats: `0.0`, `3.14` (no exponents)
* Strings: `"hello"` (double-quoted, escaped)
* Booleans: `true`, `false`

### 2.4 Comments

* Line comments start with `#` and run to end of line.
* Block comments are delimited by `###` ... `###` and do not nest in v0.

---

## 3. Types & ownership

### 3.1 Built-ins

`i32 i64 f32 f64 bool str` (`str` is immutable UTF-8 slice).

### 3.1.1 Numeric types & semantics

**Integers**

* Types: `i32`, `i64` (signed, fixed-width, two’s complement).
* Operations: `+`, `-`, `*`, `/`.
* Arithmetic is exact within range. If the exact result does not fit, the operation panics at runtime (overflow panic).
* Division: `a / b` with `b == 0` panics at runtime.
* No implicit conversions: `i32` and `i64` are distinct; mixing them is a type error (v0 has no built-in casts).
* Bitwise/shift ops are not defined in v0.

**Floating point**

* Types: `f32`, `f64` (IEEE-754).
* Operations: `+`, `-`, `*`, `/` follow IEEE-754.
  * Division by zero yields `+∞` / `-∞` (no panic).
  * Invalid ops (e.g., `0.0 / 0.0`) yield `NaN`.
* Comparisons `== != < <= > >=` follow IEEE-754:
  * Any comparison involving `NaN` (except `!=`) is false.
  * `NaN == NaN` is false; `NaN != NaN` is true.
* No implicit int↔float coercions in v0 (`1 + 1.0` is a type error).

### 3.2 Algebraic types

Sum types:

```tau
type Result<T,E> = Ok(T) | Err(E)
```

Product types:

```tau
type Point = { x:f64, y:f64 }
```

Generics: `TypeId<T, U, ...>`.

### 3.3 Ownership model

* **Copy**: `i32`, `i64`, `f32`, `f64`, `bool`.
* **Move**: everything else (`str`, user types).
* Passing a Move value moves it; assigning from a Move binding moves it and invalidates the source. No borrows in v0.

### 3.4 Mutability

* `name!` marks a binding as rebindable.
* Records are immutable; there is no field-assignment syntax. To change contents, construct a new record and rebind the variable.

### 3.5 Ownership and moves

* Moves are shallow and by binding.
* Field access on Move-typed fields is disallowed in v0; only Copy fields can be read via `p.x`.
* Pattern bindings move non-Copy payloads into the new variable; `_` on a Move value moves-and-drops.
* Moving a record or variant moves the whole value; there is no partial move.

Ownership rules are enforced by static analysis (type/ownership checker), not syntax. Key errors:

* use-after-move (including post-match scrutinee use)
* field access on Move-typed fields
* implicit partial moves are rejected; reconstruct instead of reusing moved parts
* `_` on a Move value drops it; later use is illegal
* variable shadowing follows spec rules (locals shadow imports, no duplicate locals in the same scope); violations are static errors

### 3.6 Strings

* Strings are immutable UTF-8 slices (`str`).
* Length/indexing are defined on bytes, not codepoints. (v0 has no slicing/indexing ops; this affects future extensions.)
* String literals must be well-formed UTF-8; malformed literals are compile errors.
* Escapes (only):
  * `\"` double quote
  * `\\` backslash
  * `\n` newline
  * `\t` tab
* No other escapes exist in v0 (no `\u{...}`); other backslash sequences are compile errors.

---

## 4. Top-level declarations

* `mod name`
* `use path::to::Item`
* `type` sum or product
* `fn` function declaration
* `test` test declaration (no params, returns `()`)

---

## 5. Functions, tests, lines

### 5.1 Function

```tau
fn name(param1:Type1, param2:Type2): ReturnType =
  line1
  line2
  ...
```

* No implicit return. Every path must end in `^expr` (or `panic!`).
* Return coverage is enforced at compile time; guards and matches must be exhaustive enough to guarantee termination with `^expr` or `panic!`.

### 5.2 Test

```tau
test name =
  line1
  line2
```

Conceptually `fn __test_name(): ()`.

### 5.3 Line forms (statements)

1) Declaration: `x:i32 = 1`, `p:Point = Point.{ x:1.0, y:2.0 }`, mutable `count!:i32 = 0`.

2) Assignment: `count! = count! + 1` (only for mutable bindings).

3) Return: `^expr` (only return form).

4) Guard: `cond ? action` where action is `^expr`, assignment, expression, or `panic!`; executes only if `cond` is true.

### 5.4 Guard semantics

* A guard line has the form `cond ? action`.
* `cond` is evaluated first and must be `bool`.
* If `cond == true`: execute `action`. If `cond == false`: do nothing and continue to the next line.
* `action` may be: `^expr`, `panic!`, an assignment line (`x! = ...`), or an expression line (`foo(a)`).
* Only `^expr` and `panic!` terminate the function; assignment and expression actions fall through normally. There is no implicit return after a guard action.

5) Pipe-match:

```tau
r | Ok(v)  -> action
  | Err(e) -> action
```

Scrutinee evaluated once; arms must be exhaustive; first matching arm wins.

6) Expression line: `foo(a, b)`, `assert(x == 5)` (value discarded).

7) Panic line: `panic!` aborts.

### 5.5 Match semantics

* `expr` is evaluated exactly once; if it is Move-typed, the value is moved into the match.
* Arms are tested top-to-bottom; first matching arm wins.
* After an arm executes, control continues with the next line unless the action returns or panics.
* Patterns must be exhaustive over the scrutinee type.
* Pattern bindings introduce new variables local to that arm; duplicate variable names within a single pattern are forbidden.
* `_` drops the matched value (moves-and-drops for Move types, copies-and-drops for Copy types).
* After the match, the scrutinee binding is invalid for Move types.

Static checks (semantic, not grammar):

* Guard conditions must be `bool`.
* Matches must be exhaustive over the scrutinee type.
* Pattern variable names may not repeat within a single pattern.
* Functions/tests must have total return coverage (every path ends in `^expr` or `panic!`).

---

## 6. Expressions

* Literals, bindings (`x`, `count!`), constructors:
  * `Ok.(x)` → `Ok(x)`
  * `Err."msg"` → `Err("msg")`
  * `Type.{ x:a, y:b }` record ctor
* Calls: `f(a, b, c)` (args left-to-right).
* Field access: `p.x`.
* Operators (left-assoc, low→high): `||`, `&&`, `== != < <= > >=`, `+ -`, `* /`. Unary `+ - !`.

---

## 7. Built-in operations

`panic!`

* Type: bottom type (typechecks anywhere a value is expected).
* Behavior: immediately aborts the current function/test. No message in v0.
* Any “returned” value from `panic!` is unreachable.

`assert`

```
assert(cond: bool)
```

* If `cond == true`: no effect.
* If `cond == false`: behaves exactly like `panic!`.
* Any value from a failing `assert` is unreachable.

---

## 8. Canonical formatting

* 2-space indent inside `fn`/`test`.
* Spaces around binary ops and `=` in decl/assign; no space around `:` in `name:Type`.
* Space after `,` in lists.
* Imports sorted.
* No semicolons, no tabs, no trailing whitespace.

### Formatting & canonical source form

Tau-core adopts a normative formatter; formatted output is the canonical source form.

Rules:

* 2-space indentation for statements inside `fn` / `test`.
* One blank line between top-level declarations.
* One space around binary operators and around `=`.
* No trailing spaces, no tabs.
* `use` statements are sorted lexicographically.

Parsing is whitespace-insensitive except for `NEWLINE`:

* Whitespace outside tokens has no semantic meaning.
* Indentation is not significant, but normalized by the formatter.

This means:

* Well-formed tau-core source must be formatter-compliant.
* The parser is permissive (looser whitespace and unsorted `use` are accepted); the formatter defines the canonical representation.
* Tooling SHOULD provide a `--check-format` mode that fails when input is not in canonical form (including unsorted imports), keeping the grammar robust while CI enforces determinism.

---

## 9. Example

```tau
mod math

type Result<T,E> = Ok(T) | Err(E)

fn add(a:i32, b:i32): i32 =
  c:i32 = a + b
  ^c

fn safe_div(a:i32, b:i32): Result<i32,str> =
  b == 0 ? ^Err."div-by-zero"
  q:i32 = a / b
  ^Ok.(q)

test add_basic =
  x:i32 = add(2, 3)
  assert(x == 5)

test div_zero =
  r:Result<i32,str> = safe_div(1, 0)
  r | Ok(_)  -> panic!
    | Err(e) -> assert(e == "div-by-zero")
```

---

## 10. Semantic philosophy

Tau-core encodes behavior, not intent. Priorities:

* deterministic parse and formatting
* stable, flat structure
* explicit control flow
* strict typing and ownership
* predictable transformations for tools and LLMs
