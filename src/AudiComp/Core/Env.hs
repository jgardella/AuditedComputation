module AudiComp.Core.Env where

import qualified Data.Map as Map
import Text.PrettyPrint
import Text.PrettyPrint.HughesPJClass

type Env v = Map.Map String v

instance (Pretty k, Pretty v) => Pretty (Map.Map k v) where
  pPrint env =
    braces $ vcat prettyEnv
    where prettyEnv = Map.foldlWithKey (\a k v -> nest 2 (pPrint k <+> text "=>" <+> pPrint v):a) [] env

empty :: Env v
empty = Map.empty

save :: String -> v -> Env v -> Env v
save = Map.insert

load :: String -> Env v -> Maybe v
load = Map.lookup

loadE :: String -> e -> Env v -> Either e v
loadE s e env =
  case Map.lookup s env of
    (Just v) -> Right v
    Nothing -> Left e

keys :: Env v -> [String]
keys = Map.keys
