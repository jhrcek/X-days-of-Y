-- | @cabal run htop-course@ regenerates this course in place, from anywhere
-- inside the repository.
module Main (main) where

import System.FilePath ((</>))

import Course.Build (buildCourse, findRepoRoot)
import Courses.Htop (course)

main :: IO ()
main = do
    root <- findRepoRoot
    buildCourse (root </> "htop") course
