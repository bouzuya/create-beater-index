module Main
  ( main
  ) where

import Prelude

import Bouzuya.CommandLineOption as CommandLineOption
import Bouzuya.String.Case as Case
import Bouzuya.TemplateString as TemplateString
import Data.Array as Array
import Data.Either as Either
import Data.Maybe (Maybe(..))
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

indexContent :: Boolean -> Array String -> String
indexContent toRun files = TemplateString.template (template toRun) variables
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
        baseName -> Case.camelCase baseName

    template :: Boolean -> String
    template toRun' =
      Array.intercalate
        "\n"
        [ if toRun'
            then "import { Test, run } from 'beater';"
            else "import { Test } from 'beater';"
        , "{{importTests}}"
        , ""
        , "const tests = ([] as Test[])"
        , "{{concatTests}};"
        , ""
        , if toRun'
            then "run(tests).catch(() => process.exit(1));"
            else "export { tests };"
        ]

    variables :: Object String
    variables =
      Object.fromFoldable
        [ Tuple "importTests" importTests
        , Tuple "concatTests" concatTests
        ]

createIndex ::
  forall r.
  { recursive :: Boolean, runInRoot :: Boolean | r }
  -> String
  -> String
  -> Effect Unit
createIndex options root dir = do
  Console.log dir
  indexPath <- pure (Path.concat (Array.snoc [dir] "index.ts"))
  files <- FS.readdir dir
  paths <-
    pure
      (Array.filter
        (notEq indexPath)
        (map (Path.concat <<< (Array.snoc [dir])) files))
  FS.writeTextFile
    Encoding.UTF8
    indexPath
    (indexContent ((root == dir) && options.runInRoot) paths)
  if options.recursive
    then do
      stats <- Traversable.traverse FS.stat paths
      Traversable.for_
        (map
          Tuple.fst
          (Array.filter
            (Stats.isDirectory <<< Tuple.snd)
            (Array.zip paths stats)))
        (createIndex options root)
    else pure unit

help :: String
help =
  Array.intercalate
    "\n"
    [ "Usage: create-beater-index [options]"
    , ""
    , "Options:"
    , "  -h, --help  display help"
    , "  --recursive recursive"
    , "  --run       call run (root only)"
    ]

main :: Effect Unit
main = do
  args <- map (Array.drop 2) Process.argv
  { options } <-
    Either.either
      (const (Exception.throw "invalid options"))
      pure
      (CommandLineOption.parse
        { help:
            CommandLineOption.booleanOption "help" (Just 'h') "display help"
        , recursive:
            CommandLineOption.booleanOption "recursive" Nothing "recursive"
        , runInRoot:
            CommandLineOption.booleanOption "run" Nothing "call run (root only)"
        }
        args)
  if options.help
    then Console.log help
    else do
      cwd <- Process.cwd
      createIndex options cwd cwd
