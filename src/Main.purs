module Main
  ( main
  ) where

import Prelude

import Bouzuya.TemplateString as TemplateString
import Data.Array as Array
import Data.Either as Either
import Data.String as String
import Data.String.Regex as Regex
import Data.String.Regex.Flags as RegexFlags
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Effect.Console as Console
import Foreign.Object (Object)
import Foreign.Object as Object
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
          , Tuple
              "name"
              (camelCase
                (Regex.split
                  (Unsafe.unsafePartial
                    (Either.fromRight
                      (Regex.regex "[^a-z]" RegexFlags.noFlags)))
                  (Path.basenameWithoutExt f (Path.extname f))))
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

main :: Effect Unit
main = do
  args <- map (Array.drop 2) Process.argv
  Console.logShow args
  cwd <- Process.cwd
  files <- FS.readdir cwd
  Console.logShow files
  Console.log (indexContent files)
