module Syntax
  ( Term(..)
  , Type(..)
  , Row(..)
  , Context(..)
  , EffectMap(..)
  , contextLookup
  , effectMapLookup ) where

import Test.QuickCheck
  ( Arbitrary
  , arbitrary
  , frequency
  , shrink )

-- Data types

-- Metavariable for variable names: x
-- Metavariable for effect names: z

data Term a b -- Metavariable: e
  = EUnit
  | EVar a
  | EAbs a (Type b) (Term a b)
  | EApp (Term a b) (Term a b)
  | EProvide b [b] (Term a b) (Term a b)
  deriving (Eq, Show)

data Type a -- Metavariable: t
  = TUnit
  | TArrow (Type a) (Type a) (Maybe (Row a))
  deriving (Eq, Show)

data Row a -- Metavariable: r
  = REmpty
  | RSingleton a
  | RUnion (Row a) (Row a)
  | RDifference (Row a) (Row a)
  deriving (Eq, Show)

data Context a b -- Metavariable: c
  = CEmpty
  | CExtend (Context a b) a (Type b) (Row b)
  deriving (Eq, Show)

data EffectMap a b -- Metavariable: em
  = EMEmpty
  | EMExtend (EffectMap a b) b a (Type b) (Row b)
  deriving (Eq, Show)

-- Arbitrary instances

instance (Arbitrary a, Arbitrary b) => Arbitrary (Term a b) where
  arbitrary = frequency
    [ (5, pure EUnit)
    , (5, EVar <$> arbitrary)
    , (4, EAbs <$> arbitrary <*> arbitrary <*> arbitrary)
    , (2, EApp <$> arbitrary <*> arbitrary)
    , (2, EProvide <$> arbitrary <*> arbitrary <*> arbitrary <*> arbitrary) ]
  shrink EUnit = []
  shrink (EVar _) = []
  shrink (EAbs x e1 e2) =
    [EAbs x' e1' e2' | (x', e1', e2') <- shrink (x, e1, e2)]
  shrink (EApp e1 e2) = [EApp e1' e2' | (e1', e2') <- shrink (e1, e2)]
  shrink (EProvide z zs e1 e2) =
    [EProvide z' zs' e1' e2' | (z', zs', e1', e2') <- shrink (z, zs, e1, e2)]

instance Arbitrary a => Arbitrary (Type a) where
  arbitrary = frequency
    [ (8, pure TUnit)
    , (3, TArrow <$> arbitrary <*> arbitrary <*> (Just <$> arbitrary)) ]
  shrink TUnit = []
  shrink (TArrow t1 t2 r) =
    [TArrow t1' t2' r' | (t1', t2', r') <- shrink (t1, t2, r)]

instance Arbitrary a => Arbitrary (Row a) where
  arbitrary = frequency
    [ (5, pure REmpty)
    , (5, RSingleton <$> arbitrary)
    , (3, RUnion <$> arbitrary <*> arbitrary)
    , (3, RDifference <$> arbitrary <*> arbitrary) ]
  shrink REmpty = []
  shrink (RSingleton _) = []
  shrink (RUnion r1 r2) =
    [r1, r2] ++ [RUnion r1' r2' | (r1', r2') <- shrink (r1, r2)]
  shrink (RDifference r1 r2) =
    [r1] ++ [RDifference r1' r2' | (r1', r2') <- shrink (r1, r2)]

instance (Arbitrary a, Arbitrary b) => Arbitrary (Context a b) where
  arbitrary = frequency
    [ (1, pure CEmpty)
    , (3, CExtend <$> arbitrary <*> arbitrary <*> arbitrary <*> arbitrary) ]
  shrink CEmpty = []
  shrink (CExtend c x t r) =
    [CExtend c' x' t' r' | (c', x', t', r') <- shrink (c, x, t, r)]

instance (Arbitrary a, Arbitrary b) => Arbitrary (EffectMap a b) where
  arbitrary = frequency
    [ (1, pure EMEmpty)
    , (3, EMExtend
        <$> arbitrary
        <*> arbitrary
        <*> arbitrary
        <*> arbitrary
        <*> arbitrary) ]
  shrink EMEmpty = []
  shrink (EMExtend c z x t r) =
    [EMExtend c' z' x' t' r' | (c', z', x', t', r') <- shrink (c, z, x, t, r)]

-- Helper functions

contextLookup :: Eq a => Context a b -> a -> Maybe (Type b, Row b)
contextLookup CEmpty _ = Nothing
contextLookup (CExtend c x1 t r) x2 =
  if x1 == x2
  then Just (t, r)
  else contextLookup c x2

effectMapLookup :: Eq b => EffectMap a b -> b -> Maybe (a, Type b, Row b)
effectMapLookup EMEmpty _ = Nothing
effectMapLookup (EMExtend em z1 x t r) z2 =
  if z1 == z2
  then Just (x, t, r)
  else effectMapLookup em z2
