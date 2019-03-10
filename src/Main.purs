module Main
  ( main
  ) where

import Prelude

import Bouzuya.TemplateString as TemplateString
import Data.Array as Array
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Effect.Console as Console
import Foreign.Object as Object
import Node.FS.Sync as FS
import Node.Process as Process

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

indexContent :: Array String -> String
indexContent _ =
  TemplateString.template
    template
    (Object.fromFoldable
      [ -- FIXME
        Tuple "importTests" "import { tests as fooTests } from './foo';"
        -- FIXME
      , Tuple "concatTests" "  .concat(fooTests)"
      ])

main :: Effect Unit
main = do
  args <- map (Array.drop 2) Process.argv
  Console.logShow args
  cwd <- Process.cwd
  files <- FS.readdir cwd
  Console.logShow files
  Console.log (indexContent files)
