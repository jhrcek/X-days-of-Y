{- | @cabal run pgrep-course@ regenerates this course in place, from anywhere
inside the repository.
-}
module Main (main) where

import Course.Build (buildCourse, findRepoRoot)
import System.FilePath ((</>))

import Courses.Pgrep (course)

main :: IO ()
main = do
    root <- findRepoRoot
    buildCourse (root </> "pgrep") course
