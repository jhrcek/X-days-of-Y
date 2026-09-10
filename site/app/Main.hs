{- | @cabal run build-site@ rebuilds every course and the landing page that
lists them. Adding a course: import it, add it to 'courses'.
-}
module Main (main) where

import Control.Monad (forM_)
import Course.Build (buildCourse, findRepoRoot)
import Course.Site
import Course.Types (Course (..))
import Courses.Psql qualified as Psql
import Courses.Tmux qualified as Tmux
import Data.Text qualified as T
import System.FilePath ((</>))

courses :: [Course]
courses =
    [ Tmux.course
    , Psql.course
    ]

main :: IO ()
main = do
    root <- findRepoRoot
    forM_ courses $ \c -> buildCourse (root </> T.unpack (courseSlug c)) c
    buildRoot
        root
        Site
            { siteTitle = "X Days of Y"
            , siteEyebrow = "learn one thing properly, a day at a time"
            , siteBlurb =
                "Short courses distilled from primary sources — one manual page, one sitting a day, \
                \drills you do in real work rather than exercises you read."
            , siteSource = "https://github.com/jhrcek/X-days-of-Y"
            , siteCourses = courses
            }
    putStrLn "root index.html rebuilt"
