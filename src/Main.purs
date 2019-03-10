module Main
  ( main
  ) where

import Prelude

import Data.Array as Array
import Effect (Effect)
import Effect.Console as Console
import Node.FS.Sync as FS
import Node.Process as Process

main :: Effect Unit
main = do
  args <- map (Array.drop 2) Process.argv
  Console.logShow args
  cwd <- Process.cwd
  files <- FS.readdir cwd
  Console.logShow files
