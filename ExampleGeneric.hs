{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE DeriveGeneric #-}

module Example where

import Data.Piso
import Data.Piso.Generic

import GHC.Generics


data Person = Person
  { name     :: String
  , gender   :: Gender
  , age      :: Int
  , location :: Coords
  } deriving (Eq, Show, Generic)

data Gender = Male | Female
  deriving (Eq, Show, Generic)

data Coords = Coords { lat :: Float, lng :: Float }
  deriving (Eq, Show, Generic)


person :: Piso (String :- Gender :- Int :- Coords :- t) (Person :- t)
male   :: Piso t (Gender :- t)
female :: Piso t (Gender :- t)
coords :: Piso (Float :- Float :- t) (Coords :- t)

(person, male, female, coords) =
    (person', male', female', coords')
  where
    PisoList (I person')            = mkPisoList
    PisoList (I male' :& I female') = mkPisoList
    PisoList (I coords')            = mkPisoList


false, true :: Piso t (Bool :- t)
(false, true) = (false', true')
  where
    PisoList (I false' :& I true') = mkPisoList

nil  :: Piso              t  ([a] :- t)
cons :: Piso (a :- [a] :- t) ([a] :- t)
(nil, cons) = (nil', cons')
  where
    PisoList (I nil' :& I cons') = mkPisoList
