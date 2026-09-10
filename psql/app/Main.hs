{- | @cabal run psql-course@ regenerates this course in place, from anywhere
inside the repository.
-}
module Main (main) where

import Course.Build (buildCourse, findRepoRoot)
import System.FilePath ((</>))

import Courses.Psql (course)

main :: IO ()
main = do
    root <- findRepoRoot
    buildCourse (root </> "psql") course
