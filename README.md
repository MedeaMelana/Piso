[![Build Status](https://secure.travis-ci.org/MedeaMelana/Piso.png?branch=master)](https://travis-ci.org/MedeaMelana/Piso)

# Piso: partial isomorphisms

Piso is a Haskell library for building bidirectional isomorphisms that are total when applied in the forward direction, but partial when applied in the backward direction.

This can be used to express constructor-deconstructor pairs. For example:

```haskell
nil :: Piso t ([a] :- t)
nil = Piso f g
  where
    f        t  = [] :- t
    g ([] :- t) = Just t
    g _         = Nothing

cons :: Piso (a :- [a] :- t) ([a] :- t)
cons = Piso f g
  where
    f (x :- xs  :- t) = (x : xs) :- t
    g ((x : xs) :- t) = Just (x :- xs :- t)
    g _               = Nothing
```

Here `:-` can be read as 'cons', forming a stack of values. For example, `nil`
pushes `[]` onto the stack; or, in the backward direction, tries to remove `[]`
from the stack (failing if it finds any other value). Representing
constructor-destructor pairs as stack manipulators allows them to be composed
more easily.

Module `Data.Piso.Common` contains `Piso`s for some common datatypes.

Modules `Data.Piso.Generic` and `Data.Piso.TH` offer generic ways of deriving `Piso`s for custom datatypes.
