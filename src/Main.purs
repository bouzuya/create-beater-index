module Main
  ( main
  ) where

import Prelude

import Data.Array as Array
import Effect (Effect)
import Effect.Console as Console
import Node.Process as Process

main :: Effect Unit
main = do
  args <- map (Array.drop 2) Process.argv
  Console.logShow args
