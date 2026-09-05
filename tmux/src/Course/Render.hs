-- | Turns the list of 'Day' values into the static site.
module Course.Render (buildSite) where

import Control.Monad (forM_, unless, when)
import Data.Maybe (isJust)
import Data.Text (Text)
import Data.Text qualified as T
import Data.Text.IO qualified as TIO
import Lucid
import Lucid.Base (makeAttribute)
import System.Directory (createDirectoryIfMissing, findExecutable)
import System.FilePath ((</>))
import System.IO (hPutStrLn, stderr)
import System.Process (readProcess)
import Text.Printf (printf)

import Course.Types

-- ---------------------------------------------------------------------------
-- entry point
-- ---------------------------------------------------------------------------

buildSite :: FilePath -> [Day] -> IO ()
buildSite root days = do
  hasDot <- isJust <$> findExecutable "dot"
  unless hasDot $
    hPutStrLn stderr "warning: graphviz `dot` not on PATH - diagrams will not be rendered"
  forM_ days $ \d -> do
    let dir = root </> dayDir (dayNum d)
    createDirectoryIfMissing True dir
    forM_ (dayDiagram d) $ \dg -> writeDiagram hasDot dir dg
    renderToFile (dir </> "index.html") (pageDay days d)
  renderToFile (root </> "index.html") (pageIndex days)
  renderToFile (root </> "reference.html") (pageReference days)
  TIO.writeFile (root </> "tmux.conf") (tmuxConf days)
  printf "built %d lessons, index.html, reference.html, tmux.conf\n" (length days)

dayDir :: Int -> FilePath
dayDir n = printf "day_%02d" n

-- ---------------------------------------------------------------------------
-- graphviz
-- ---------------------------------------------------------------------------

-- | Shared preamble, so all fourteen ologs are visually one family.
dotSource :: Diagram -> Text
dotSource dg =
  T.unlines
    [ "digraph olog {"
    , "  bgcolor=\"transparent\";"
    , "  rankdir=" <> dgRankdir dg <> ";"
    , "  splines=spline;"
    , "  nodesep=" <> dgNodesep dg <> ";"
    , "  ranksep=" <> dgRanksep dg <> ";"
    , "  node [shape=box, style=\"rounded,filled\", fillcolor=\"#ffffff\","
    , "        color=\"#d6cfc4\", penwidth=1.1, fontname=\"Helvetica\", fontsize=11.5,"
    , "        fontcolor=\"#23201c\", margin=\"0.17,0.09\", height=0.34];"
    , "  edge [color=\"#a09587\", penwidth=1.05, fontname=\"Helvetica\", fontsize=9.5,"
    , "        fontcolor=\"#6f675c\", arrowsize=0.72];"
    , ""
    ]
    <> dgBody dg
    <> "\n}\n"

writeDiagram :: Bool -> FilePath -> Diagram -> IO ()
writeDiagram hasDot dir dg = do
  let dotPath = dir </> "olog.dot"
  TIO.writeFile dotPath (dotSource dg)
  when hasDot $ do
    svg <- readProcess "dot" ["-Tsvg", dotPath] ""
    TIO.writeFile (dir </> "olog.svg") (cleanSvg (T.pack svg))

-- | Drop the XML prolog and DOCTYPE (so the file is happy inlined as well as in
-- an @\<img\>@) and let the page's font stack win over graphviz's hardcoded one.
cleanSvg :: Text -> Text
cleanSvg =
  T.replace "font-family=\"Helvetica,sans-serif\"" "font-family=\"var(--sans)\""
    . T.replace
      "<svg "
      "<svg style=\"--sans:ui-sans-serif,system-ui,'Segoe UI',Helvetica,Arial,sans-serif\" "
    . snd
    . T.breakOn "<svg"

-- ---------------------------------------------------------------------------
-- shared chrome
-- ---------------------------------------------------------------------------

nDays :: Int
nDays = 14

shell_ :: Text -> Text -> Text -> Html () -> Html () -> Html ()
shell_ prefix bodyClass title extraHead inner = doctypehtml_ $ do
  head_ $ do
    meta_ [charset_ "utf-8"]
    meta_ [name_ "viewport", content_ "width=device-width, initial-scale=1"]
    title_ (toHtml title)
    link_ [rel_ "stylesheet", href_ (prefix <> "assets/style.css")]
    link_
      [ rel_ "icon"
      , href_
          "data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><text y='.9em' font-size='90'>▚</text></svg>"
      ]
    extraHead
  body_ [class_ bodyClass] $ do
    inner
    footer_ [class_ "foot"] $
      p_ $ do
        "Distilled from the "
        code_ "tmux(1)"
        " manual page, checked against tmux 3.7c."

masthead :: Text -> Maybe Int -> Html ()
masthead prefix here = header_ [class_ "masthead"] $ do
  a_ [class_ "home", href_ (prefix <> "index.html")] $ do
    span_ [class_ "home-mark"] "▚"
    "14 Days of tmux"
  case here of
    Nothing -> mempty
    Just n ->
      let state i
            | i == n = "here"
            | i < n = "past"
            | otherwise = ""
       in nav_ [class_ "dots", makeAttribute "aria-label" "Jump to a day"] $
            forM_ [1 .. nDays] $ \i ->
              a_
                [ class_ (T.unwords ["dot", state i])
                , href_ (prefix <> T.pack (dayDir i) <> "/index.html")
                , title_ ("Day " <> tshow i)
                ]
                (toHtml (tshow i))

tshow :: Int -> Text
tshow = T.pack . show

-- ---------------------------------------------------------------------------
-- tables
-- ---------------------------------------------------------------------------

keyChips :: Text -> Html ()
keyChips = foldMap (kbd_ . toHtml) . T.words

entryTable :: Text -> Text -> [Entry] -> Html ()
entryTable cls headA rows
  | null rows = mempty
  | otherwise = table_ [class_ cls] $ do
      thead_ $ tr_ $ th_ (toHtml headA) <> th_ "Does"
      tbody_ $ forM_ rows $ \(a, b) ->
        tr_ $ td_ (leftCell a) <> td_ b
  where
    leftCell = if cls == "keys" then keyChips else code_ . toHtml

vocabulary :: Day -> Html ()
vocabulary d =
  div_ [class_ "tables"] $ do
    labelled "Keys" "keys" "Key" (dayKeys d)
    labelled "Commands" "cmds" "Command" (dayCmds d)
    labelled "Options" "cmds" "Option" (dayOpts d)
  where
    labelled lbl cls headA rows
      | null rows = mempty
      | otherwise = div_ [class_ "tblock"] (h4_ lbl <> entryTable cls headA rows)

cumulativeTables :: [Day] -> Int -> Html ()
cumulativeTables days n = do
  sub "Keys" "keys" "Key" dayKeys
  sub "Commands" "cmds" "Command" dayCmds
  sub "Options" "cmds" "Option" dayOpts
  where
    upto = takeWhile ((<= n) . dayNum) days
    sub lbl cls headA sel =
      let rows = concatMap sel upto
       in if null rows then mempty else h4_ lbl <> entryTable cls headA rows

-- ---------------------------------------------------------------------------
-- the lesson page
-- ---------------------------------------------------------------------------

pageDay :: [Day] -> Day -> Html ()
pageDay days d =
  shell_ "../" "day" pageTitle mempty $ do
    a_ [class_ "skip", href_ "#main"] "Skip to content"
    masthead "../" (Just n)
    main_ [id_ "main"] $ do
      article_ $ do
        div_ [class_ "hero"] $ do
          p_ [class_ "hero-num"] $ do
            "Day "
            b_ (toHtml (pad n))
          h1_ (toHtml (dayTitle d))
          p_ [class_ "hero-sub"] (toHtml (daySubtitle d))
          ul_ [class_ "hero-meta"] $ do
            li_ (toHtml (tshow (dayMinutes d) <> " min"))
            li_ (toHtml (dayLevel d))
            li_ $ do
              "man page: "
              span_ [class_ "manref"] (toHtml (dayManRef d))

        section_ [class_ "goals"] $ do
          p_ [class_ "goals-h"] "By the end of today you can"
          ul_ (foldMap li_ (dayGoals d))

        dayBody d figure

        block' "New vocabulary" (vocabulary d)

        configBox d

        section_ [class_ "block"] $ do
          h2_ $ do
            "Drills"
            span_ [class_ "h-note"] "do these in a real terminal, today"
          drills

        section_ [class_ "block"] $ do
          h2_ "Self-check"
          p_ [class_ "lede-sm"] "Answer out loud first, then unfold."
          forM_ (dayQuiz d) $ \(q, a) ->
            details_ [class_ "q"] $ summary_ q <> div_ [class_ "a"] a

        section_ [class_ "block"] $ do
          h2_ "Cheat sheet"
          div_ [class_ "cheat"] (dayCheat d)
          details_ [class_ "cumu"] $ do
            summary_ (toHtml ("Everything through Day " <> pad n))
            div_ [class_ "cumu-body"] (cumulativeTables days n)

      nav_ [class_ "pager"] (prevLink <> nextLink)
    script_ [] (drillJs n)
  where
    n = dayNum d
    pageTitle = "Day " <> pad n <> " · " <> dayTitle d <> " · 14 Days of tmux"
    block' :: Text -> Html () -> Html ()
    block' t inner = section_ [class_ "block"] (h2_ (toHtml t) <> inner)

    figure = case dayDiagram d of
      Nothing -> mempty
      Just dg -> figure_ [class_ "olog"] $ do
        img_ [src_ "olog.svg", alt_ (dgAlt dg)]
        figcaption_ $ span_ [class_ "fig-l"] "Olog" <> dgCaption dg

    drills
      | null (dayDrills d) = mempty
      | otherwise = ol_ [class_ "drills"] $
          forM_ (zip [0 :: Int ..] (dayDrills d)) $ \(i, item) ->
            let ident = T.pack (printf "d%02d-%d" n i)
             in li_ $ do
                  input_ [type_ "checkbox", id_ ident, makeAttribute "data-drill" ""]
                  label_ [for_ ident] item

    dayAt i = lookup i [(dayNum x, x) | x <- days]

    prevLink = case dayAt (n - 1) of
      Just p -> a_ [class_ "prev", href_ ("../" <> T.pack (dayDir (n - 1)) <> "/index.html")] $ do
        span_ "Previous"
        toHtml ("Day " <> pad (n - 1) <> " · " <> dayTitle p)
      Nothing -> a_ [class_ "prev", href_ "../index.html"] $
        span_ "Back to" <> "The syllabus"

    nextLink = case dayAt (n + 1) of
      Just x -> a_ [class_ "next", href_ ("../" <> T.pack (dayDir (n + 1)) <> "/index.html")] $ do
        span_ "Next"
        toHtml ("Day " <> pad (n + 1) <> " · " <> dayTitle x)
      Nothing -> a_ [class_ "next", href_ "../reference.html"] $
        span_ "Next" <> "The whole reference, one page"

pad :: Int -> Text
pad = T.pack . printf "%02d"

configBox :: Day -> Html ()
configBox d
  | null (dayConfig d) = mempty
  | otherwise = section_ [class_ "block"] $ do
      h2_ $ do
        "Today's config"
        span_ [class_ "h-note"] "append to ~/.tmux.conf"
      div_ [class_ "confadd"] $ forM_ (dayConfig d) $ \b -> do
        unless (T.null (cbTitle b)) $ p_ [class_ "confadd-t"] (toHtml (cbTitle b))
        pre_ [class_ "conf"] $ code_ $ foldMap line (T.lines (T.strip (cbCode b)))
      p_ [class_ "confadd-f"] $ do
        "Reload with "
        code_ "tmux source-file ~/.tmux.conf"
        " and watch for errors in the status line."
  where
    line l
      | "#" `T.isPrefixOf` T.stripStart l = span_ [class_ "comment"] (toHtml l) <> "\n"
      | otherwise = toHtml l <> "\n"

drillJs :: Int -> Text
drillJs n =
  T.unlines
    [ "(function(){var K='tmux-course:';"
    , "function safe(f){try{return f()}catch(e){return null}}"
    , "var b=[].slice.call(document.querySelectorAll('input[data-drill]'));"
    , "function save(){var d=b.filter(function(x){return x.checked}).length;"
    , "safe(function(){return localStorage.setItem(K+'day" <> pad n <> "',d+'/'+b.length)})}"
    , "b.forEach(function(x){var key=K+x.id;"
    , "if(safe(function(){return localStorage.getItem(key)})==='1')x.checked=true;"
    , "x.addEventListener('change',function(){"
    , "safe(function(){return localStorage.setItem(key,x.checked?'1':'0')});save()})});"
    , "save()})();"
    ]

-- ---------------------------------------------------------------------------
-- landing page
-- ---------------------------------------------------------------------------

pageIndex :: [Day] -> Html ()
pageIndex days = shell_ "" "index" "14 Days of tmux" mempty $ do
  main_ $ do
    header_ [class_ "cover"] $ do
      p_ [class_ "eyebrow"] "a fourteen-day course, distilled from the manual page"
      h1_ $ do
        span_ [class_ "big"] "14 Days"
        span_ [class_ "of"] "of"
        span_ [class_ "big"] "tmux"
      p_ [class_ "cover-sub"] $ do
        "From "
        em_ "“I know it keeps shells alive over ssh”"
        " to writing your own key tables, formats, hooks and session scripts. \
        \One sitting a day, each small enough to actually use at work the same afternoon."
      div_ [class_ "cover-meta"] $ do
        meta' "14" "lessons"
        meta' "~30" "minutes each"
        meta' "1" "config, built line by line"

    section_ [class_ "how"] $ do
      h2_ "How to use this"
      div_ [class_ "how-grid"] $ do
        div_ $ do
          h3_ "One sitting a day"
          p_ $ do
            "Each lesson introduces a handful of concepts and stops. The drills at the \
            \bottom are the actual lesson — tmux is muscle memory, and reading about "
            code_ "C-b z"
            " teaches you nothing. Do the drills inside whatever work you were going to \
            \do anyway."
        div_ $ do
          h3_ "Live in it from Day 1"
          p_ $ do
            "Start every terminal session with "
            code_ "tmux new -A -s main"
            ". Everything after Day 1 is refinement of a habit you already have. Drop the \
            \habit and none of this sticks."
        div_ $ do
          h3_ "Build your own config"
          p_ $ do
            "From Day 5 each lesson adds a few justified lines to "
            code_ "~/.tmux.conf"
            ". Nothing is pasted from a stranger's dotfiles: by Day 14 you can defend \
            \every line. The finished file is "
            a_ [href_ "tmux.conf"] "here"
            "."

    section_ [class_ "syllabus"] $ do
      h2_ "The syllabus"
      ol_ [class_ "cards"] $ forM_ days $ \d ->
        li_ [class_ "card", makeAttribute "data-day" (pad (dayNum d))] $ do
          a_ [href_ (T.pack (dayDir (dayNum d)) <> "/index.html")] $ do
            span_ [class_ "card-n"] (toHtml (pad (dayNum d)))
            h3_ (toHtml (dayTitle d))
            p_ (toHtml (daySubtitle d))
          div_ [class_ "tags"] $
            forM_ (dayTags d) $ \t -> span_ [class_ "tag"] (toHtml t)

    section_ [class_ "how"] $ do
      h2_ "Also here"
      div_ [class_ "how-grid"] $ do
        div_ $ do
          h3_ $ a_ [href_ "reference.html"] "The cumulative reference"
          p_ "Every key, command and option the course introduces, on one page, each \
             \marked with the day it appears. The page to keep open in a browser tab."
        div_ $ do
          h3_ $ a_ [href_ "tmux.conf"] "tmux.conf"
          p_ "The configuration assembled over Days 5–14, with the reasoning kept as \
             \comments. Diff it against your own when you are done."
        div_ $ do
          h3_ "What is deliberately left out"
          p_ "Server access control, terminfo minutiae, the deeper reaches of control \
             \mode, and the genuinely exotic flags. By Day 14 you can read the man page \
             \for those yourself — which is the real skill on offer here."
  script_ [] indexJs
  where
    meta' big small = div_ (strong_ big <> span_ small)

indexJs :: Text
indexJs =
  T.unlines
    [ "(function(){try{"
    , "document.querySelectorAll('[data-day]').forEach(function(el){"
    , "var v=localStorage.getItem('tmux-course:day'+el.dataset.day);if(!v)return;"
    , "var p=v.split('/');var s=document.createElement('span');s.className='progress';"
    , "s.textContent='drills '+v;if(p[0]===p[1]&&p[1]!=='0')s.classList.add('done');"
    , "el.appendChild(s)})}catch(e){}})();"
    ]

-- ---------------------------------------------------------------------------
-- reference
-- ---------------------------------------------------------------------------

pageReference :: [Day] -> Html ()
pageReference days = shell_ "" "day reference" "Reference · 14 Days of tmux" mempty $ do
  masthead "" Nothing
  main_ [id_ "main"] $ article_ $ do
    div_ [class_ "hero"] $ do
      p_ [class_ "hero-num"] "Reference"
      h1_ "Everything, on one page"
      p_ [class_ "hero-sub"]
        "Every key, command and option introduced by the course, with the day it first \
        \appears. This is the page to keep open while the habits settle."
    sect "Keys" "keys" "Key" dayKeys
    sect "Commands" "cmds" "Command" dayCmds
    sect "Options" "cmds" "Option" dayOpts
  where
    sect :: Text -> Text -> Text -> (Day -> [Entry]) -> Html ()
    sect lbl cls headA sel = section_ [class_ "block"] $ do
      h2_ (toHtml lbl)
      table_ [class_ (cls <> " ref")] $ do
        thead_ $ tr_ $ th_ (toHtml headA) <> th_ "Does" <> th_ "Day"
        tbody_ $ forM_ days $ \d ->
          forM_ (sel d) $ \(a, b) -> tr_ $ do
            td_ (if cls == "keys" then keyChips a else code_ (toHtml a))
            td_ b
            td_ $ a_ [href_ (T.pack (dayDir (dayNum d)) <> "/index.html")]
                     (toHtml (tshow (dayNum d)))

-- ---------------------------------------------------------------------------
-- tmux.conf
-- ---------------------------------------------------------------------------

tmuxConf :: [Day] -> Text
tmuxConf days =
  T.unlines $
    [ "# ~/.tmux.conf"
    , "#"
    , "# Assembled over Days 5-14 of the '14 Days of tmux' course. Every line was"
    , "# introduced with a reason, and the comments are that reason. Reload with:"
    , "#"
    , "#     tmux source-file ~/.tmux.conf        (or prefix R, once Day 8 is done)"
    , "#"
    ]
      <> concatMap section' (filter (not . null . dayConfig) days)
  where
    section' d =
      [ ""
      , "# " <> T.replicate 74 "="
      , "# Day " <> pad (dayNum d) <> " - " <> dayTitle d
      , "# " <> T.replicate 74 "="
      ]
        <> concatMap blk (dayConfig d)
    blk b =
      ""
        : map ("# " <>) (T.lines (cbTitle b))
        <> T.lines (T.strip (cbCode b))
