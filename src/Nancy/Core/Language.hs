module Nancy.Core.Language where

import Text.PrettyPrint
import Text.PrettyPrint.HughesPJClass

data Type
  = IntType
  | BoolType
  | LamType Type Type
  | BangType Type Witness
  deriving (Eq, Show)

instance Pretty Type where
  pPrint IntType = text "int"
  pPrint BoolType = text "bool"
  pPrint (LamType argType returnType) = parens(pPrint argType <> text "->" <> pPrint returnType)
  pPrint (BangType bodyType witness) = pPrint bodyType <+> brackets(pPrint witness)

mapType :: (Witness -> Witness) -> (Type -> Type) -> Type -> Type
mapType _ typeFunc (LamType argType returnType) =
  LamType (typeFunc argType) (typeFunc returnType)
mapType witFunc typeFunc (BangType bangType bangWit) =
  BangType (typeFunc bangType) (witFunc bangWit)
mapType _ _ otherType = otherType

newtype Program = Program Expr
  deriving (Eq, Show)

data Expr
  = Var String
  | Number Int
  | Boolean Bool
  | Brack Expr
  | Lam String Type Expr
  | App Expr Expr
  | Plus Expr Expr
  | Eq Expr Expr
  | Ite Expr Expr Expr
  | AVar String
  | Bang Expr Trail
  | ALet String Type Expr Expr
  | Inspect (TrailBranches Expr)
  deriving (Eq, Show)

mapExpr :: (Expr -> Expr) -> Expr -> Expr
mapExpr f (Brack brackExpr) = f brackExpr
mapExpr f (Lam var varType bodyExpr) =
  Lam var varType (f bodyExpr)
mapExpr f (App lamExpr argExpr) =
  App (f lamExpr) (f argExpr)
mapExpr f (Plus leftExpr rightExpr) =
  Plus (f leftExpr) (f rightExpr)
mapExpr f (Eq leftExpr rightExpr) =
  Eq (f leftExpr) (f rightExpr)
mapExpr f (Ite condExpr trueExpr falseExpr) =
  Ite (f condExpr) (f trueExpr) (f falseExpr)
mapExpr f (Bang bangExpr bangTrail) =
  Bang (f bangExpr) bangTrail
mapExpr f (ALet var varType argExpr bodyExpr) =
  ALet var varType (f argExpr) (f bodyExpr)
mapExpr f (Inspect branches) =
  Inspect $ fmap f branches
mapExpr _ otherExpr = otherExpr

data Value
  = IntVal Int
  | BoolVal Bool
  | LamVal String Type Expr
  | VarVal String
  | AVarVal String
  | BangVal Value Trail
  deriving (Eq, Show)

instance Pretty Value where
  pPrint (IntVal i) = int i
  pPrint (BoolVal b) = text $ show b
  pPrint (LamVal arg typ body) = parens(text arg <> colon <> pPrint typ <+> text "->" <+> text (show body))
  pPrint (VarVal x) = text x
  pPrint (AVarVal u) = text "<" <> text u <> text ">"
  pPrint (BangVal value trail) = text "!" <> brackets(pPrint trail) <+> pPrint value

data Witness
  = VarWit String
  | IntWit Int
  | BoolWit Bool
  | LamWit String Type Witness
  | AppWit Witness Witness
  | PlusWit Witness Witness
  | EqWit Witness Witness
  | IteWit Witness Witness Witness
  | AVarWit String
  | BangWit Witness
  | ALetWit String Type Witness Witness
  | TiWit (TrailBranches Witness)
  deriving (Eq, Show)

instance Pretty Witness where
  pPrint (VarWit var) =
    text "varwit" <> parens(text var)
  pPrint (IntWit intVal) =
    text "intwit" <> parens(text (show intVal))
  pPrint (BoolWit boolVal) =
    text "boolwit" <> parens(text (show boolVal))
  pPrint (LamWit arg argType bodyWit) =
    text "lamwit" <> parens(text arg <> colon <> pPrint argType <> comma <+> pPrint bodyWit)
  pPrint (AppWit lamWit argWit) =
    text "appwit" <> parens(pPrint lamWit <> comma <> pPrint argWit)
  pPrint (PlusWit leftWit rightWit) =
    text "pluswit" <> parens(pPrint leftWit <> comma <+> pPrint rightWit)
  pPrint (EqWit leftWit rightWit) =
    text "eqwit" <> parens(pPrint leftWit <> comma <+> pPrint rightWit)
  pPrint (IteWit condWit trueWit falseWit) =
    text "itewit" <> parens(pPrint condWit <> comma <+> pPrint trueWit <> comma <+> pPrint falseWit)
  pPrint (AVarWit avar) =
    text "avarwit" <> parens(text avar)
  pPrint (BangWit bangWit) =
    text "bangwit" <> parens(pPrint bangWit)
  pPrint (ALetWit arg argType argWit bodyWit) =
    text "aletwit" <> parens(text arg <> colon <> pPrint argType <> comma
      <+> pPrint argWit <> comma <+> pPrint bodyWit)
  pPrint (TiWit branches) =
    text "tiwit" <> parens(pPrint branches)

mapWitness :: (Type -> Type) -> (Witness -> Witness) -> Witness -> Witness
mapWitness typeFunc witFunc (LamWit var varType lamWit) =
  LamWit var (typeFunc varType) (witFunc lamWit)
mapWitness _ witFunc (AppWit lamWit argWit) =
  AppWit (witFunc lamWit) (witFunc argWit)
mapWitness _ witFunc (PlusWit leftWit rightWit) =
  PlusWit (witFunc leftWit) (witFunc rightWit)
mapWitness _ witFunc (EqWit leftWit rightWit) =
  EqWit (witFunc leftWit) (witFunc rightWit)
mapWitness _ witFunc (IteWit condWit trueWit falseWit) =
  IteWit (witFunc condWit) (witFunc trueWit) (witFunc falseWit)
mapWitness _ witFunc (BangWit bangWit) =
  BangWit $ witFunc bangWit
mapWitness typeFunc witFunc (ALetWit var varType argWit bodyWit) =
  ALetWit var (typeFunc varType) (witFunc argWit) (witFunc bodyWit)
mapWitness typeFunc witFunc (TiWit branchWits) =
  TiWit $ fmap (mapWitness typeFunc witFunc) branchWits
mapWitness _ _ otherWitness = otherWitness

data TrailBranches a = TrailBranches {
  r :: a,
  t :: a,
  ba :: a,
  bb :: a,
  ti :: a,
  lam :: a,
  app :: a,
  plus :: a,
  eq :: a,
  ite :: a,
  alet :: a,
  trpl :: a
} deriving (Eq, Show)

instance Functor TrailBranches where
  fmap f TrailBranches {..} =
    TrailBranches{
      r=f r,
      t=f t,
      ba=f ba,
      bb=f bb,
      ti=f ti,
      lam=f lam,
      app=f app,
      plus=f plus,
      eq=f eq,
      ite=f ite,
      alet=f alet,
      trpl=f trpl
    }

instance (Pretty a) => Pretty (TrailBranches a) where
  pPrint TrailBranches {..} =
    pPrint r <> comma
    <+> pPrint t <> comma
    <+> pPrint ba <> comma
    <+> pPrint bb <> comma
    <+> pPrint ti <> comma
    <+> pPrint lam <> comma
    <+> pPrint app <> comma
    <+> pPrint plus <> comma
    <+> pPrint eq <> comma
    <+> pPrint ite <> comma
    <+> pPrint alet <> comma
    <+> pPrint trpl

mapTrailBranchesM :: (Monad m) => (a -> m b) -> TrailBranches a -> m (TrailBranches b)
mapTrailBranchesM f TrailBranches{..} = do
  rResult <- f r
  tResult <- f t
  baResult <- f ba
  bbResult <- f bb
  tiResult <- f ti
  lamResult <- f lam
  appResult <- f app
  plusResult <- f plus
  eqResult <- f eq
  iteResult <- f ite
  aletResult <- f alet
  trplResult <- f trpl
  return TrailBranches {
    r = rResult,
    t = tResult,
    ba = baResult,
    bb = bbResult,
    ti = tiResult,
    lam = lamResult,
    app = appResult,
    plus = plusResult,
    eq = eqResult,
    ite = iteResult,
    alet = aletResult,
    trpl = trplResult
  }

unzipTrailBranches :: TrailBranches (a, b) -> (TrailBranches a, TrailBranches b)
unzipTrailBranches branches = (fst <$> branches, snd <$> branches)

trailBranchesToList :: TrailBranches a -> [a]
trailBranchesToList TrailBranches {..} =
  [r, t, ba, bb, ti, lam, app, plus, eq, ite, alet, trpl]

trailBranchesFromList :: [a] -> Maybe (TrailBranches a)
trailBranchesFromList [r, t, ba, bb, ti, lam, app, plus, eq, ite, alet, trpl] =
  Just TrailBranches {..}
trailBranchesFromList _ = Nothing

trailBranchArity :: TrailBranches Integer
trailBranchArity = TrailBranches {
  r = 0,
  t = 2,
  ba = 0,
  bb = 0,
  ti = 0,
  lam = 1,
  app = 2,
  plus = 2,
  eq = 2,
  ite = 3,
  alet = 2,
  trpl = 12
}

data Trail
    = RTrail Witness
    | TTrail Trail Trail
    | BaTrail String Type Witness Witness
    | BbTrail String Type Witness Witness
    | TiTrail Trail (TrailBranches Witness)
    | LamTrail String Type Trail
    | AppTrail Trail Trail
    | PlusTrail Trail Trail
    | EqTrail Trail Trail
    | IteTrail Trail Trail Trail
    | ALetTrail String Type Trail Trail
    | TrplTrail (TrailBranches Trail)
    deriving (Eq, Show)

instance Pretty Trail where
  pPrint (RTrail wit) = text "r" <> parens(pPrint wit)
  pPrint (TTrail trail1 trail2) = pPrint trail1 <> semi $$ pPrint trail2
  pPrint (BaTrail arg argType argWit bodyWit) =
    text "ba" <> parens(
    text arg <> colon <> pPrint argType <> comma <+> pPrint argWit <> comma
    <+> pPrint bodyWit)
  pPrint (BbTrail arg argType argWit bodyWit) =
    text "bb" <> parens(
    text arg <> colon <> pPrint argType <> comma <+> pPrint argWit <> comma
    <+> pPrint bodyWit)
  pPrint (TiTrail _ branches) =
    text "ti" <> parens(pPrint branches)
  pPrint (LamTrail arg argType bodyTrail) =
    text "lam" <> parens(
    text arg <> colon <> pPrint argType <> comma <+> pPrint bodyTrail)
  pPrint (AppTrail lamTrail argTrail) =
    text "app" <> parens(
    pPrint lamTrail <> comma
    <+> pPrint argTrail)
  pPrint (PlusTrail leftTrail rightTrail) =
    text "plus" <> parens(pPrint leftTrail <> comma <+> pPrint rightTrail)
  pPrint (EqTrail leftTrail rightTrail) =
    text "eq" <> parens(pPrint leftTrail <> comma <+> pPrint rightTrail)
  pPrint (IteTrail condTrail thenTrail elseTrail) =
    text "ite" <> parens(pPrint condTrail <> comma <+> pPrint thenTrail <> comma <+> pPrint elseTrail)
  pPrint (ALetTrail arg argType argTrail bodyTrail) =
    text "alet" <> parens(
    text arg <> colon <> pPrint argType <> comma <+> pPrint argTrail <> comma
    <+> pPrint bodyTrail)
  pPrint (TrplTrail branches) =
    text "trpl" <> parens(pPrint branches)

mapTrail :: (Witness -> Witness) -> (Trail -> Trail) -> (Type -> Type) -> Trail -> Trail
mapTrail witFunc _ _ (RTrail rWit) =
  RTrail $ witFunc rWit
mapTrail _ trailFunc _ (TTrail trail1 trail2) =
  TTrail (trailFunc trail1) (trailFunc trail2)
mapTrail witFunc _ typeFunc (BaTrail var varType argWit bodyWit) =
  BaTrail var (typeFunc varType) (witFunc argWit) (witFunc bodyWit)
mapTrail witFunc _ typeFunc (BbTrail var varType argWit bodyWit) =
  BbTrail var (typeFunc varType) (witFunc argWit) (witFunc bodyWit)
mapTrail witFunc trailFunc _ (TiTrail trail branchWits) =
  TiTrail (trailFunc trail) (fmap witFunc branchWits)
mapTrail _ trailFunc typeFunc (LamTrail var varType lamTrail) =
  LamTrail var (typeFunc varType) (trailFunc lamTrail)
mapTrail _ trailFunc _ (AppTrail lamTrail argTrail) =
  AppTrail (trailFunc lamTrail) (trailFunc argTrail)
mapTrail _ trailFunc _ (PlusTrail leftTrail rightTrail) =
  PlusTrail (trailFunc leftTrail) (trailFunc rightTrail)
mapTrail _ trailFunc _ (EqTrail leftTrail rightTrail) =
  EqTrail (trailFunc leftTrail) (trailFunc rightTrail)
mapTrail _ trailFunc _ (IteTrail condTrail thenTrail elseTrail) =
  IteTrail (trailFunc condTrail) (trailFunc thenTrail) (trailFunc elseTrail)
mapTrail _ trailFunc typeFunc (ALetTrail var varType argTrail bodyTrail) =
  ALetTrail var (typeFunc varType) (trailFunc argTrail) (trailFunc bodyTrail)
mapTrail _ trailFunc _ (TrplTrail branchTrails) =
  TrplTrail $ fmap trailFunc branchTrails

(<-->) :: Trail -> Trail -> Trail
trailOne <--> trailTwo = TTrail trailOne trailTwo
infixr 0 <-->
