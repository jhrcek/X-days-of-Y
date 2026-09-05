-- | @cabal run tmux-course@ regenerates the whole course in place.
module Main (main) where

import Course.Days (allDays)
import Course.Render (buildSite)
import System.Environment (getArgs)

main :: IO ()
main = do
  args <- getArgs
  let root = case args of
        (p : _) -> p
        [] -> "."
  buildSite root allDays
