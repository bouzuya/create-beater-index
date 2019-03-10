module Main
  ( main
  ) where

import Prelude

import Bouzuya.TemplateString as TemplateString
import Data.Array as Array
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Effect.Console as Console
import Foreign.Object (Object)
import Foreign.Object as Object
import Node.FS.Sync as FS
import Node.Process as Process

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
          [ Tuple "file" f
          , Tuple "name" f -- FIXME
          ])

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
