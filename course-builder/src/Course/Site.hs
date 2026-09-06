-- | The repository-root landing page: one card per course.
module Course.Site
    ( Site (..)
    , buildRoot
    ) where

import Control.Monad (forM_)
import Data.Text (Text)
import Data.Text qualified as T
import Lucid
import System.FilePath ((</>))

import Course.Types

data Site = Site
    { siteTitle :: Text
    -- ^ e.g. \"X Days of Y\"; the first word pair is set large
    , siteEyebrow :: Text
    , siteBlurb :: Html ()
    , siteSource :: Text
    -- ^ URL of the repository
    , siteCourses :: [Course]
    }

buildRoot :: FilePath -> Site -> IO ()
buildRoot root s = renderToFile (root </> "index.html") (page s)

page :: Site -> Html ()
page s = doctypehtml_ $ do
    head_ $ do
        meta_ [charset_ "utf-8"]
        meta_ [name_ "viewport", content_ "width=device-width, initial-scale=1"]
        title_ (toHtml (siteTitle s))
        link_
            [ rel_ "icon"
            , href_ "data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><text y='.9em' font-size='90'>▚</text></svg>"
            ]
        style_ css
    body_ $ main_ $ do
        p_ [class_ "eyebrow"] (toHtml (siteEyebrow s))
        h1_ (title' (siteTitle s))
        p_ [class_ "sub"] (siteBlurb s)
        h2_ "Courses"
        forM_ (siteCourses s) $ \c ->
            a_ [class_ "card", href_ (courseSlug c <> "/index.html")] $ do
                h3_ (toHtml (T.pack (show (length (courseDays c))) <> " Days of " <> courseTool c))
                p_ (courseCardBlurb c)
                div_ [class_ "tags"] $ forM_ (courseCardTags c) $ \t -> span_ [class_ "tag"] (toHtml t)
        footer_ $ p_ $ do
            "Source: "
            a_ [href_ (siteSource s)] (toHtml (T.replace "https://" "" (siteSource s)))
  where
    -- "X Days of Y" -> X Days <em>of</em> Y; anything else is shown as-is
    title' t = case T.splitOn " of " t of
        [a, b] -> toHtml a <> " " <> em_ "of" <> " " <> toHtml b
        _ -> toHtml t

css :: Text
css =
    T.unlines
        [ ":root{color-scheme:light;--paper:#faf7f2;--card:#fff;--ink:#23201c;--ink-2:#423d36;"
        , "--muted:#7c7365;--rule:#e6dfd2;--rule-2:#d8cfbe;--accent:#2f7a63;"
        , "--serif:\"Iowan Old Style\",Charter,Georgia,\"Times New Roman\",serif;"
        , "--sans:ui-sans-serif,system-ui,-apple-system,\"Segoe UI\",Roboto,Arial,sans-serif}"
        , "*{box-sizing:border-box}"
        , "body{margin:0;background:var(--paper);color:var(--ink);font-family:var(--serif);font-size:17px;line-height:1.62}"
        , "main{max-width:46rem;margin:0 auto;padding:5rem 1.5rem 4rem}"
        , ".eyebrow{font-family:var(--sans);font-size:.73rem;letter-spacing:.16em;text-transform:uppercase;color:var(--accent);margin:0 0 1.2rem}"
        , "h1{font-family:var(--sans);font-weight:700;letter-spacing:-.035em;font-size:clamp(2.6rem,9vw,4.4rem);line-height:.95;margin:0 0 1.3rem}"
        , "h1 em{font-family:var(--serif);font-style:italic;font-weight:400;color:var(--muted)}"
        , ".sub{font-size:1.12rem;color:var(--ink-2);max-width:34rem;margin:0 0 3rem}"
        , "h2{font-family:var(--sans);font-size:.74rem;letter-spacing:.14em;text-transform:uppercase;color:var(--muted);font-weight:650;margin:0 0 1.1rem;padding-bottom:.5rem;border-bottom:1px solid var(--rule)}"
        , ".card{display:block;text-decoration:none;color:inherit;border:1px solid var(--rule-2);border-radius:11px;background:var(--card);padding:1.2rem 1.35rem;margin-bottom:.8rem;transition:border-color .12s ease,transform .12s ease}"
        , ".card:hover{border-color:var(--accent);transform:translateY(-1px)}"
        , ".card h3{font-family:var(--sans);font-size:1.25rem;font-weight:650;letter-spacing:-.015em;margin:0 0 .35rem}"
        , ".card p{margin:0 0 .8rem;font-size:.95rem;color:var(--ink-2)}"
        , "code{font-family:ui-monospace,\"SFMono-Regular\",Menlo,Consolas,monospace;font-size:.855em;background:var(--paper);border:1px solid var(--rule);border-radius:4px;padding:.08em .34em;white-space:nowrap}"
        , ".tags{display:flex;flex-wrap:wrap;gap:.3rem}"
        , ".tag{font-family:var(--sans);font-size:.64rem;letter-spacing:.04em;color:var(--muted);background:var(--paper);border:1px solid var(--rule);border-radius:999px;padding:.16em .55em}"
        , "footer{margin-top:4rem;padding-top:1.3rem;border-top:1px solid var(--rule);font-family:var(--sans);font-size:.78rem;color:var(--muted)}"
        , "footer a{color:var(--accent)}"
        ]
