module Nancy.Core.Output where

import Text.PrettyPrint.HughesPJClass

import Nancy.Core.Language
import Nancy.Core.Errors.Typechecker
import Nancy.Core.Errors.Interpreter

data ParserOutput
  = ParseSuccess Program
  | ParseFailure String
  deriving (Eq, Show)

data TypecheckerOutput
  = TypecheckSuccess (Type, Witness)
  | TypecheckFailure TypecheckError
  deriving (Eq, Show)

data InterpreterOutput
  = InterpretSuccess (Value, [String])
  | InterpretFailure (InterpretError, [String])
  deriving (Eq, Show)

instance Pretty ParserOutput where
  pPrint (ParseSuccess (Program expr)) =
    text (show expr)
  pPrint (ParseFailure err) =
    text "Error during lexing/parsing:" <+> text err

instance Pretty TypecheckerOutput where
  pPrint (TypecheckSuccess (resultType, resultWit)) =
    pPrint resultType <+> brackets(pPrint resultWit)
  pPrint (TypecheckFailure err) =
    text "Error during typechecking:" <+> pPrint err

instance Pretty InterpreterOutput where
  pPrint (InterpretSuccess (resultVal, _)) =
    pPrint resultVal
  pPrint (InterpretFailure (err, _)) =
    text "Error during interpreting:" <+> pPrint err
