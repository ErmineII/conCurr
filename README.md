
 conCurr ![logo](logo.svg)
============================

Inspired by lisp, (oca)ml, and logo.

It's currently only a ~~buggy~~ parser. I'm working on a printer.

 Syntax
----------------------------

There are a few types of values:

- `nil`: null or false value. There are no keywords in cnC, so it's
  represented by `()`
- "atoms": like `yes`
- "numbers": like `1`
- "cons" pairs: like in lisp, a pair of 2 values.
  They are called the `l` and `r` in cnC because they are not used
  for making lists like in lisp

Most of cnC's syntax is different ways of making cons (constructed)
pairs. It looks like lisp but with more brackets.

```
| conCurr                     | Lisp dotted pair notation
+---------------------------- +-----------------------------------------
| ()                          | nil OR NIL OR ()
| (function arg1 arg2)        | (((nil . function) . arg1) . arg2)
| (: prefix a b c)            | (((prefix . a) . b) . c)
| (if (exp) [yes] [no])       | ( ( ((nil . if) . (nil . exp)) .
|                             |      (nil . (nil . yes)) ) .
|                             |      (nil . (nil . no)) )
```

As you might see, where in lisp `(1 2)` is equivalent to
`(1 . (2 . nil))`, in cnC `(1 2)` means `((nil . 1) . 2)`.

Brackets ([]) work exactly as parentheses but result in a pair of
`(nil . result)`. For simplicity, conCurr has no special forms like
`quote` or `if`. These can be implemented as functions because in
conCurr, expressions will not be evaluated if there `l`eft side
is `nil` (so nil is like quote in lisp). Control flow can be
functions accepting literal expressions to conditionally evaluate
(like in logo or smalltalk), removing a lot of bloat from the core
language into the standard library. When I actually implement an
interpreter and eventually a compiler, I might also add lazy evaluation.

There is also some syntactic sugar: `(+ 1 (* x 2))` can be condensed to
`(+ 1 $ * x 2)` and `(when (cond) [body])` is the same as
`(when (cond): body)`. Whitespace is insignificant except for as a
separator. Line comments start with `#` and (nestable) block comments
start with `#!` and end with `!#`.

---

> You know it's a good language if `(: ;)` is valid syntax

-- Me

