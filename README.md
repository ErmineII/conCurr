
 Concurr ![logo](logo.svg)
============================

A curried functional lisp-like language.

This project has moved to [codeberg](https://codeberg.org/Wezl/Concurr), but
you can still place issues here.

Example
----------------------------

```bash
(define [factorial n]
  : < n 2
     [:1]
  : * n $ factorial $ - n 1)

# point free
(define [factorial] $ . (foldl (*) 1) (... 1))

# iterative, ugh
(define [factorial]
  $ loop \next {accum n} # similar to scheme's named let
     [ < n 2 [:accum]
     :: next (* n accum) (- n 1)
     ]
     1) # with accum having an initial value of 1
```

