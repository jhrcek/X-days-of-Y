{-# LANGUAGE TemplateHaskell #-}

-- | The IO side: write a whole course to disk.
module Course.Build
    ( buildCourse
    , findRepoRoot
    , styleCss
    ) where

import Control.Monad (forM_, unless, when)
import Data.FileEmbed (embedStringFile)
import Data.Maybe (isJust)
import Data.Text (Text)
import Data.Text qualified as T
import Data.Text.IO qualified as TIO
import Lucid (renderToFile)
import System.Directory
    ( createDirectoryIfMissing
    , doesFileExist
    , findExecutable
    , getCurrentDirectory
    )
import System.FilePath (takeDirectory, (</>))
import System.IO (hPutStrLn, stderr)
import System.Process (readProcess)
import Text.Printf (printf)

import Course.Render
import Course.Types

{- | The one stylesheet, compiled into the library so every course gets the
same copy written next to its pages (GitHub Pages needs it there).
-}
styleCss :: Text
styleCss = $(embedStringFile "assets/style.css")

{- | Render a course into @root@ (normally @<repo>/<slug>@): the stylesheet,
one directory per day with the olog source and SVG, the landing page, the
reference, and the config file if the course has one.
-}
buildCourse :: FilePath -> Course -> IO ()
buildCourse root c = do
    hasDot <- isJust <$> findExecutable "dot"
    unless hasDot $
        hPutStrLn stderr "warning: graphviz `dot` not on PATH - diagrams will not be rendered"
    createDirectoryIfMissing True (root </> "assets")
    TIO.writeFile (root </> "assets" </> "style.css") styleCss
    forM_ (courseDays c) $ \d -> do
        let dir = root </> dayDir (dayNum d)
        createDirectoryIfMissing True dir
        forM_ (dayDiagram d) (writeDiagram hasDot dir)
        renderToFile (dir </> "index.html") (pageDay c d)
    renderToFile (root </> "index.html") (pageIndex c)
    renderToFile (root </> "reference.html") (pageReference c)
    forM_ (courseConfig c) $ \cf ->
        forM_ (configFileText c) $ \txt ->
            TIO.writeFile (root </> T.unpack (cfFileName cf)) txt
    printf
        "%s: built %d lessons, index.html, reference.html%s\n"
        (T.unpack (courseSlug c))
        (length (courseDays c))
        (maybe "" ((", " <>) . T.unpack . cfFileName) (courseConfig c))

writeDiagram :: Bool -> FilePath -> Diagram -> IO ()
writeDiagram hasDot dir dg = do
    let dotPath = dir </> "olog.dot"
    TIO.writeFile dotPath (dotSource dg)
    when hasDot $ do
        svg <- readProcess "dot" ["-Tsvg", dotPath] ""
        TIO.writeFile (dir </> "olog.svg") (cleanSvg (T.pack svg))

{- | Walk up from the current directory to the one holding @cabal.project@, so
@cabal run@ does the right thing from anywhere inside the repository. Falls
back to the current directory.
-}
findRepoRoot :: IO FilePath
findRepoRoot = getCurrentDirectory >>= go
  where
    go dir = do
        here <- doesFileExist (dir </> "cabal.project")
        let parent = takeDirectory dir
        if here || parent == dir then pure dir else go parent
