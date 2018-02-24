module Main(main) where

import Options.Applicative
import Data.Function((&))
import Data.Semigroup((<>))
import Nancy.Helper
import Text.PrettyPrint.HughesPJClass( Pretty, prettyShow )

data Mode = Parse
          | Typecheck
          | Interpret
  deriving (Read)

data Args = Args
  { mode :: Mode
  , pretty :: Bool
  , fileName :: String }

parseMode :: Parser Mode
parseMode = option auto
            ( long "mode"
            <> short 'm'
            <> metavar "MODE"
            <> value Interpret )

parsePretty :: Parser Bool
parsePretty = switch
              ( long "pretty"
              <> short 'p' )

parseArgs :: Parser Args
parseArgs = Args
         <$> parseMode
         <*> parsePretty
         <*> argument str (metavar "FILE" <> value "<stdin>")

opts :: ParserInfo Args
opts = info (parseArgs <**> helper)
  ( fullDesc
 <> progDesc "Interpreter for Nancy Programming Language"
 <> header "Nancy Interpreter" )

smartShow :: (Show a, Pretty a) => Args -> a -> String
smartShow args a =
  if pretty args then
    prettyShow a
  else
    show a

main :: IO ()
main = do
  args <- execParser opts
  let input = case fileName args of
                "<stdin>" -> getContents
                file -> readFile file
  case mode args of
    Parse -> do
      result <- fmap (parse $ fileName args) input
      either (putStrLn . smartShow args) print result
    Typecheck -> do
      typecheckResult <- fmap (parseTypecheck $ fileName args) input
      case typecheckResult of
        (Left l) -> ("Error: " ++ smartShow args l) & putStrLn
        (Right (t, p)) -> ("Type: \n" ++ smartShow args t ++ "\nProof: \n" ++ smartShow args p) & putStrLn
    Interpret -> do
      (interpretResult, logs) <- fmap (parseTypecheckInterpret $ fileName args) input
      mapM_ putStrLn logs
      case interpretResult of
        (Left l) -> ("Error: " ++ smartShow args l) & putStrLn
        (Right v) -> ("Value: \n" ++ smartShow args v) & putStrLn
