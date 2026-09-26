{- | @cabal run git-course@ regenerates this course in place, from anywhere
inside the repository.
-}
module Main (main) where

import Course.Build (buildCourse, findRepoRoot)
import System.FilePath ((</>))

import Courses.Git (course)

main :: IO ()
main = do
    root <- findRepoRoot
    buildCourse (root </> "git") course
