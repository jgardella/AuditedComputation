{
{-# OPTIONS -w #-}
module Nancy.Parser( parseProgram ) where

import Data.Char
import Nancy.Lexer
import Nancy.Core.Language
import Nancy.Core.Util
}

%name parse
%tokentype { Token }
%monad { Alex }
%lexer { lexwrap } { Token _ TokenEOF }
-- Without this we get a type error
%error { happyError }


%token
  id    { Token _ (TokenVar $$) }
  num   { Token _ (TokenNum $$) }
  fun   { Token _ TokenFun }
  insp  { Token _ TokenInspect }
  '='   { Token _ TokenEq }
  '=='  { Token _ TokenDoubleEq }
  '->'  { Token _ TokenArrow }
  '<'   { Token _ TokenLBrack }
  '>'   { Token _ TokenRBrack }
  '('   { Token _ TokenLParen }
  ')'   { Token _ TokenRParen }
  '{'   { Token _ TokenLBrace }
  '}'   { Token _ TokenRBrace }
  ':'   { Token _ TokenColon }
  '!'   { Token _ TokenBang }
  ','   { Token _ TokenComma }
  '+'   { Token _ TokenPlus }
  if    { Token _ TokenIf }
  then  { Token _ TokenThen }
  else  { Token _ TokenElse }
  'r'   { Token _ TokenR }
  't'   { Token _ TokenT }
  ba    { Token _ TokenBA }
  bb    { Token _ TokenBB }
  ti    { Token _ TokenTI }
  lam   { Token _ TokenLAM }
  app   { Token _ TokenAPP }
  pls   { Token _ TokenPLS }
  eq    { Token _ TokenEQ }
  ite   { Token _ TokenITE }
  trpl  { Token _ TokenTRPL }
  let   { Token _ TokenLet }
  alet  { Token _ TokenALet }
  'let!'{ Token _ TokenLetBang }
  in    { Token _ TokenIn }
  int   { Token _ TokenInt }
  bool  { Token _ TokenBool }
  true  { Token _ TokenTrue }
  false { Token _ TokenFalse }

%right in
%right '->'
%left '+'
%nonassoc id num true false '(' fun if '<' '!' let 'let!' insp
%nonassoc APP

%%

Program   : Expr                                { Program $1 }
Type      : int                                 { IntType }
          | bool                                { BoolType }
          | Type '->' Type                      { LamType $1 $3 }
          | '(' Type ')'                        { $2 }
IdType    : '(' id ':' Type ')'                 { ($2, $4) }
IdTypes   : IdType                              { [$1] }
          | IdType IdTypes                      { $1 : $2 }
Assign    : IdType '=' Expr                     { Assign (fst $1) (snd $1) $3 }
Assigns   : Assign                              { [$1] }
          | Assign ',' Assigns                  { $1 : $3 }
Expr      : id                                  { Var $1 }
          | num                                 { Number $1 }
          | true                                { Boolean True }
          | false                               { Boolean False }
          | '(' Expr ')'                        { Brack $2 }
          | Expr Expr %prec APP                 { App $1 $2 }
          | fun IdTypes '->' Expr               { (unwrapLam $2 $4) }
          | Expr '+' Expr                       { Plus $1 $3 }
          | Expr '==' Expr                      { Eq $1 $3 }
          | if Expr then Expr else Expr         { Ite $2 $4 $6 }
          | '<' id '>'                          { AVar $2 }
          | '!' Expr                            { Bang $2 (RTrail (getWit $2)) }
          | let Assigns in Expr                 { (unwrapLetVars $4 $2) }
          | 'let!' Assigns in Expr              { (unwrapALetVars $4 $2) }
          | insp '{'
              'r' '->' Expr
              't' '->' Expr
              ba '->' Expr
              bb '->' Expr
              ti '->' Expr
              lam '->' Expr
              app '->' Expr
              pls '->' Expr
              eq  '->' Expr
              ite '->' Expr
              alet '->' Expr
              trpl '->' Expr
            '}' { Inspect (TrailBranches $5 $8 $11 $14 $17 $20 $23 $26 $29 $32 $35 $38) }

{
data Assign = Assign String Type Term

unwrapLam :: [(String, Type)] -> Term -> Term
unwrapLam ((var, varType):vars) bodyTerm =
  Lam var varType (unwrapLam vars bodyTerm)
unwrapLam [] bodyTerm =
  bodyTerm

unwrapALetVars :: Term -> [Assign] -> Term
unwrapALetVars body ((Assign var varType varTerm):vars) =
  ALet var varType varTerm (unwrapALetVars body vars)
unwrapALetVars body [] =
  body

unwrapLetVars :: Term -> [Assign] -> Term
unwrapLetVars body assigns =
  unwrapApps (unwrapLams body assigns) (reverse assigns)
  where
    unwrapLams body ((Assign var varType _):vars) =
      Lam var varType (unwrapLams body vars)
    unwrapLams body [] =
      body
    unwrapApps lam ((Assign _ _ varExp):vars) =
      App (unwrapApps lam vars) varExp
    unwrapApps lam [] =
      lam

unwrapLetVars body [] =
  body

lexwrap :: (Token -> Alex a) -> Alex a
lexwrap = (alexMonadScan' >>=)

happyError :: Token -> Alex a
happyError (Token p t) =
  alexError' p ("parse error at token '" ++ unLex t ++ "'")

parseProgram :: FilePath -> String -> Either String Program
parseProgram = runAlex' parse
}
