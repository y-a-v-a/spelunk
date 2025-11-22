**tau-core**, a spelunking-level language

---

# **tau-core — Core Concepts (v0)**

### **1. Purpose**

* A *minimal*, *deterministic*, *LLM-friendly* implementation language.
* Not for humans to write by hand; only for reading, verifying, and patching.
* Zero ambiguity, brittle and explicit, stable as an IR.

---

# **Syntax & Structure**

### **2. Line-based language**

* Functions and tests are just **sequences of simple lines**.
* No nested blocks. No complex control structures.
* Each line is one atomic, unambiguous action.

### **3. One module per file**

* `mod name` (optional).
* `use module::item` imports.
* `type`, `fn`, `test` decls follow.

---

# **Types**

### **4. Strict, explicit typing everywhere**

* No inference.
* Every variable, parameter, and return value has an explicitly declared type.

### **5. Ownership model (Rust-lite)**

* Values are **Copy** (i32, f32, bool…) or **Move** (most types).
* Move types: assignment or passing moves the value; old binding is invalid.

### **6. Algebraic data types**

* **Sum types** (union):

  ```
  type Result<T,E> = Ok(T) | Err(E)
  ```

* **Product types** (records):

  ```
  type Point = { x:f64, y:f64 }
  ```

---

# **Functions & Tests**

### **7. Functions**

```
fn name(param:Type, ...): ReturnType =
  line
  line
  ...
```

* Function body is just ordered statements.
* Must end in `^expr`.

### **8. Tests**

```
test name =
  line
  line
```

* Same line structure as functions.
* Fail via `assert` or `panic!`.

---

# **Statements (Lines)**

### **9. Declaration line**

```
x:i32 = 1
p:Point = Point.{ x:1.0, y:2.0 }
```

* Creates new binding.
* `!` marks mutability: `x!:i32 = 0`.

### **10. Assignment line**

```
x! = x! + 1
```

* Only valid for mutated bindings.

### **11. Return**

```
^expr
```

* The *only* return form.
* Must appear on all code paths.

### **12. Guard line**

```
cond ? action
```

* If `cond` is true, executes `action` (return / assignment / call / panic).
* No else branch; pure early-exit mechanism.

### **13. Pipe-match**

```
r | Ok(v)  -> action
  | Err(e) -> action
```

* Line-based pattern matching.
* Must be exhaustive.

### **14. Expression line**

```
foo(a, b)
assert(x == 5)
```

* Expression executed for side effects.

### **15. Panic**

```
panic!
```

* Immediate abort.

---

# **Expressions**

### **16. Deterministic expression grammar**

* Fixed precedence:

  * `||`, `&&`, comparisons, `+ -`, `* /`, unary ops.
* No implicit coercions.

### **17. Constructors**

* `Ok.(x)` shorthand for `Ok(x)`
* `Err."msg"` shorthand for `Err("msg")`
* `Type.{ x:a, y:b }` for record construction.

### **18. Function calls**

```
f(a, b, c)
```

### **19. Field access**

```
p.x
```

---

# **Formatting**

### **20. Canonical formatting is part of the spec**

* 2-space indent inside `fn`/`test`.
* Spaces around `=`, `+`, `==`, etc.
* No semicolons.
* No tabs.
* Imports sorted.
* One true layout → predictable for LLMs.

---

# **Semantic Philosophy**

### **21. tau-core encodes *behavior*, not *intent***

* It is the machine-checkable substrate.
* Intent/spec lives outside tau-core (future layer).
* tau-core prioritizes:

  * deterministic parse
  * stable structure
  * simple control flow
  * strict typing
  * predictable transformations

---

If you want, I can now generate:

* a **spec document** (formal prose)
* a **reference implementation outline** (parser, typechecker, IR)
* or a **“tau-core 0.1” example repository layout**

— whichever direction you want to explore next.
