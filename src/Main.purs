module Main
  ( main
  ) where

import Prelude

import Bouzuya.CommandLineOption as CommandLineOption
import Bouzuya.TemplateString as TemplateString
import Data.Array as Array
import Data.Either as Either
import Data.Maybe (Maybe(..))
import Data.String as String
import Data.String.Regex as Regex
import Data.String.Regex.Flags as RegexFlags
import Data.Traversable as Traversable
import Data.Tuple (Tuple(..))
import Data.Tuple as Tuple
import Effect (Effect)
import Effect.Console as Console
import Effect.Exception as Exception
import Foreign.Object (Object)
import Foreign.Object as Object
import Node.Encoding as Encoding
import Node.FS.Stats as Stats
import Node.FS.Sync as FS
import Node.Path as Path
import Node.Process as Process
import Partial.Unsafe as Unsafe

indexContent :: Array String -> String
indexContent files = TemplateString.template template variables
  where
    concatTests :: String
    concatTests = lines "  .concat({{name}}Tests)" files

    fileTemplate :: String -> String -> String
    fileTemplate t f =
      TemplateString.template
        t
        (Object.fromFoldable
          [ Tuple "file" (Path.basenameWithoutExt f (Path.extname f))
          , Tuple "name" (pathToName f)
          ])

    camelCase :: Array String -> String
    camelCase ss =
      Array.fold
        ( (Array.take 1 ss) <>
          (map
            (\s -> (String.toUpper (String.take 1 s)) <> (String.drop 1 s))
            (Array.drop 1 ss)))

    importTests :: String
    importTests =
      lines "import { tests as {{name}}Tests } from './{{file}}';" files

    lines :: String -> Array String -> String
    lines t fs = Array.intercalate "\n" (map (fileTemplate t) fs)

    pathToName :: String -> String
    pathToName f =
      case Path.basenameWithoutExt f (Path.extname f) of
        "_" -> "underscore"
        "$" -> "dollar"
        baseName ->
          camelCase
            (Regex.split
              (Unsafe.unsafePartial
                (Either.fromRight
                  (Regex.regex "[^a-z]" RegexFlags.noFlags)))
              baseName)

    template :: String
    template =
      Array.intercalate
        "\n"
        [ "import { Test } from 'beater';"
        , "{{importTests}}"
        , ""
        , "const tests = ([] as Test[])"
        , "{{concatTests}};"
        , ""
        , "export { tests };"
        ]

    variables :: Object String
    variables =
      Object.fromFoldable
        [ Tuple "importTests" importTests
        , Tuple "concatTests" concatTests
        ]

createIndex :: Boolean -> String -> Effect Unit
createIndex recursive dir = do
  Console.log dir
  indexPath <- pure (Path.concat (Array.snoc [dir] "index.ts"))
  files <- FS.readdir dir
  paths <-
    pure
      (Array.filter
        (notEq indexPath)
        (map (Path.concat <<< (Array.snoc [dir])) files))
  FS.writeTextFile Encoding.UTF8 indexPath (indexContent paths)
  if recursive
    then do
      stats <- Traversable.traverse FS.stat paths
      Traversable.for_
        (map
          Tuple.fst
          (Array.filter
            (Stats.isDirectory <<< Tuple.snd)
            (Array.zip paths stats)))
        (createIndex recursive)
    else pure unit

main :: Effect Unit
main = do
  args <- map (Array.drop 2) Process.argv
  { options } <-
    Either.either
      (const (Exception.throw "invalid options"))
      pure
      (CommandLineOption.parse
        { recursive:
            CommandLineOption.booleanOption "recursive" Nothing "recursive"
        }
        args)
  cwd <- Process.cwd
  createIndex options.recursive cwd
