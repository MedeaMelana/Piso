{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE TemplateHaskell #-}

module Data.Piso.TH (derivePisos) where

import Data.Piso
import Language.Haskell.TH
import Control.Applicative
import Control.Monad


-- | Derive partial isomorphisms for a given datatype. The resulting
-- expression is a tuple with one isomorphism element for each constructor in
-- the datatype.
-- 
-- For example:
-- 
-- > nothing :: Piso t (Maybe a :- t)
-- > just    :: Piso (a :- t) (Maybe a :- t)
-- > (nothing, just) = $(derivePisos ''Maybe)
-- 
-- Deriving isomorphisms this way requires @-XNoMonoPatBinds@.
derivePisos :: Name -> Q Exp
derivePisos name = do
  info <- reify name
  routers <-
    case info of
      TyConI (DataD _ _ _ _ cons _)   ->
        mapM (derivePiso (length cons /= 1)) cons
      TyConI (NewtypeD _ _ _ _ con _) ->
        (:[]) <$> derivePiso False con
      _ ->
        fail $ show name ++ " is not a datatype."
  return (TupE routers)


derivePiso :: Bool -> Con -> Q Exp
derivePiso matchWildcard con =
  case con of
    NormalC name tys -> go name (map snd tys)
    RecC name tys -> go name (map (\(_,_,ty) -> ty) tys)
    _ -> fail $ "Unsupported constructor " ++ show (conName con)
  where
    go name tys = do
      piso <- [| Piso |]
      pisoCon <- deriveConstructor name tys
      pisoDes <- deriveDestructor matchWildcard name tys
      return $ piso `AppE` pisoCon `AppE` pisoDes


deriveConstructor :: Name -> [Type] -> Q Exp
deriveConstructor name tys = do
  -- Introduce some names
  t          <- newName "t"
  fieldNames <- replicateM (length tys) (newName "a")

  -- Figure out the names of some constructors
  ConE cons  <- [| (:-) |]

  let pat = foldr (\f fs -> ConP cons [VarP f, fs]) (VarP t) fieldNames
  let applyCon = foldl (\f x -> f `AppE` VarE x) (ConE name) fieldNames
  let body = ConE cons `AppE` applyCon `AppE` VarE t

  return $ LamE [pat] body


deriveDestructor :: Bool -> Name -> [Type] -> Q Exp
deriveDestructor matchWildcard name tys = do
  -- Introduce some names
  x          <- newName "x"
  r          <- newName "r"
  fieldNames <- replicateM (length tys) (newName "a")

  -- Figure out the names of some constructors
  ConE just  <- [| Just |]
  ConE cons  <- [| (:-) |]
  nothing    <- [| Nothing |]

  let conPat   = ConP name (map VarP fieldNames)
  let okBody   = ConE just `AppE`
                  foldr
                    (\h t -> ConE cons `AppE` VarE h `AppE` t)
                    (VarE r)
                    fieldNames
  let okCase   = Match (ConP cons [conPat, VarP r]) (NormalB okBody) []
  let failCase = Match WildP (NormalB nothing) []
  let allCases =
        if matchWildcard
              then [okCase, failCase]
              else [okCase]

  return $ LamE [VarP x] (CaseE (VarE x) allCases)


-- Retrieve the name of a constructor.
conName :: Con -> Name
conName con =
  case con of
    NormalC name _  -> name
    RecC name _     -> name
    InfixC _ name _ -> name
    ForallC _ _ con' -> conName con'