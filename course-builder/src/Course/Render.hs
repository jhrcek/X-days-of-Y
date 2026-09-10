{- | Turns a 'Course' into HTML pages, graphviz sources and the config file.

Nothing in here knows about any particular tool; every string that names one
comes from the 'Course' record. See "Course.Build" for the IO side.
-}
module Course.Render
    ( pageDay
    , pageIndex
    , pageReference
    , configFileText
    , dotSource
    , cleanSvg
    , dayDir
    , pad
    ) where

import Control.Monad (forM_, unless)
import Data.Text (Text)
import Data.Text qualified as T
import Lucid
import Lucid.Base (makeAttribute)
import Text.Printf (printf)

import Course.Markup (isConfComment)
import Course.Types

-- ---------------------------------------------------------------------------
-- names and numbers
-- ---------------------------------------------------------------------------

dayDir :: Int -> FilePath
dayDir n = printf "day_%02d" n

pad :: Int -> Text
pad = T.pack . printf "%02d"

tshow :: Int -> Text
tshow = T.pack . show

nDays :: Course -> Int
nDays = length . courseDays

-- | \"14 Days of tmux\".
courseTitle :: Course -> Text
courseTitle c = tshow (nDays c) <> " Days of " <> courseTool c

-- | \"fourteen\", for the cover eyebrow; digits beyond thirty.
numberWord :: Int -> Text
numberWord n = case n of
    1 -> "one"
    2 -> "two"
    3 -> "three"
    4 -> "four"
    5 -> "five"
    6 -> "six"
    7 -> "seven"
    8 -> "eight"
    9 -> "nine"
    10 -> "ten"
    11 -> "eleven"
    12 -> "twelve"
    13 -> "thirteen"
    14 -> "fourteen"
    15 -> "fifteen"
    16 -> "sixteen"
    17 -> "seventeen"
    18 -> "eighteen"
    19 -> "nineteen"
    20 -> "twenty"
    21 -> "twenty-one"
    22 -> "twenty-two"
    23 -> "twenty-three"
    24 -> "twenty-four"
    25 -> "twenty-five"
    26 -> "twenty-six"
    27 -> "twenty-seven"
    28 -> "twenty-eight"
    29 -> "twenty-nine"
    30 -> "thirty"
    _ -> tshow n

-- | Average lesson length, to the nearest five minutes.
typicalMinutes :: Course -> Int
typicalMinutes c
    | null ds = 0
    | otherwise = 5 * round (fromIntegral (sum (map dayMinutes ds)) / (5 * fromIntegral (length ds)) :: Double)
  where
    ds = courseDays c

-- | First and last day that contribute to the config file, if any.
configSpan :: Course -> Maybe (Int, Int)
configSpan c = case [dayNum d | d <- courseDays c, not (null (dayConfig d))] of
    [] -> Nothing
    ns -> Just (minimum ns, maximum ns)

-- ---------------------------------------------------------------------------
-- graphviz
-- ---------------------------------------------------------------------------

-- | Shared preamble, so every olog in a course is visually one family.
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

{- | Drop the XML prolog and DOCTYPE (so the file is happy inlined as well as in
an @\<img\>@) and let the page's font stack win over graphviz's hardcoded one.
-}
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

shell_ :: Course -> Text -> Text -> Text -> Html () -> Html ()
shell_ c prefix bodyClass title inner = doctypehtml_ $ do
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
    body_ [class_ bodyClass] $ do
        inner
        footer_ [class_ "foot"] $
            p_ $ do
                "Distilled from the "
                code_ (toHtml (courseManRef c))
                toHtml (" manual page, checked against " <> courseVersion c <> ".")

masthead :: Course -> Text -> Maybe Int -> Html ()
masthead c prefix here = header_ [class_ "masthead"] $ do
    a_ [class_ "home", href_ (prefix <> "index.html")] $ do
        span_ [class_ "home-mark"] "▚"
        toHtml (courseTitle c)
    case here of
        Nothing -> mempty
        Just n ->
            let state i
                    | i == n = "here"
                    | i < n = "past"
                    | otherwise = ""
             in nav_ [class_ "dots", makeAttribute "aria-label" "Jump to a day"] $
                    forM_ [1 .. nDays c] $ \i ->
                        a_
                            [ class_ (T.unwords ["dot", state i])
                            , href_ (prefix <> T.pack (dayDir i) <> "/index.html")
                            , title_ ("Day " <> tshow i)
                            ]
                            (toHtml (tshow i))

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

pageDay :: Course -> Day -> Html ()
pageDay c d =
    shell_ c "../" "day" pageTitle $ do
        a_ [class_ "skip", href_ "#main"] "Skip to content"
        masthead c "../" (Just n)
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

                configBox c d

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
        script_ [] (drillJs c n)
  where
    days = courseDays c
    n = dayNum d
    pageTitle = "Day " <> pad n <> " · " <> dayTitle d <> " · " <> courseTitle c

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
        Nothing ->
            a_ [class_ "prev", href_ "../index.html"] $
                span_ "Back to" <> "The syllabus"

    nextLink = case dayAt (n + 1) of
        Just x -> a_ [class_ "next", href_ ("../" <> T.pack (dayDir (n + 1)) <> "/index.html")] $ do
            span_ "Next"
            toHtml ("Day " <> pad (n + 1) <> " · " <> dayTitle x)
        Nothing ->
            a_ [class_ "next", href_ "../reference.html"] $
                span_ "Next" <> "The whole reference, one page"

configBox :: Course -> Day -> Html ()
configBox c d = case courseConfig c of
    Just cf | not (null (dayConfig d)) -> section_ [class_ "block"] $ do
        h2_ $ do
            "Today's config"
            span_ [class_ "h-note"] (toHtml ("append to " <> cfUserPath cf))
        div_ [class_ "confadd"] $ forM_ (dayConfig d) $ \b -> do
            unless (T.null (cbTitle b)) $ p_ [class_ "confadd-t"] (toHtml (cbTitle b))
            pre_ [class_ "conf"] $ code_ $ foldMap line (T.lines (T.strip (cbCode b)))
        p_ [class_ "confadd-f"] (cfReloadHint cf)
    _ -> mempty
  where
    line l
        | isConfComment l = span_ [class_ "comment"] (toHtml l) <> "\n"
        | otherwise = toHtml l <> "\n"

drillJs :: Course -> Int -> Text
drillJs c n =
    T.unlines
        [ "(function(){var K='" <> courseSlug c <> "-course:';"
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
-- the course's landing page
-- ---------------------------------------------------------------------------

pageIndex :: Course -> Html ()
pageIndex c = shell_ c "" "index" (courseTitle c) $ do
    main_ $ do
        header_ [class_ "cover"] $ do
            p_ [class_ "eyebrow"] $
                toHtml ("a " <> numberWord (nDays c) <> "-day course, distilled from the manual page")
            h1_ $ do
                span_ [class_ "big"] (toHtml (tshow (nDays c) <> " Days"))
                span_ [class_ "of"] "of"
                span_ [class_ "big"] (toHtml (courseTool c))
            p_ [class_ "cover-sub"] (courseTagline c)
            div_ [class_ "cover-meta"] $ do
                meta' (tshow (nDays c)) "lessons"
                meta' ("~" <> tshow (typicalMinutes c)) "minutes each"
                forM_ (courseConfig c) $ \_ -> meta' "1" "config, built line by line"

        unless (null (courseHowTo c)) $
            section_ [class_ "how"] $ do
                h2_ "How to use this"
                div_ [class_ "how-grid"] $
                    forM_ (courseHowTo c) $
                        \(t, body) -> div_ (h3_ (toHtml t) <> p_ body)

        section_ [class_ "syllabus"] $ do
            h2_ "The syllabus"
            ol_ [class_ "cards"] $ forM_ (courseDays c) $ \d ->
                li_ [class_ "card", makeAttribute "data-day" (pad (dayNum d))] $ do
                    a_ [href_ (T.pack (dayDir (dayNum d)) <> "/index.html")] $ do
                        span_ [class_ "card-n"] (toHtml (pad (dayNum d)))
                        h3_ (toHtml (dayTitle d))
                        p_ (toHtml (daySubtitle d))
                    div_ [class_ "tags"] $
                        forM_ (dayTags d) $
                            \t -> span_ [class_ "tag"] (toHtml t)

        section_ [class_ "how"] $ do
            h2_ "Also here"
            div_ [class_ "how-grid"] $ do
                div_ $ do
                    h3_ $ a_ [href_ "reference.html"] "The cumulative reference"
                    p_
                        "Every key, command and option the course introduces, on one page, each \
                        \marked with the day it appears. The page to keep open in a browser tab."
                forM_ (courseConfig c) $ \cf -> div_ $ do
                    h3_ $ a_ [href_ (cfFileName cf)] (toHtml (cfFileName cf))
                    p_ $ do
                        "The configuration assembled over "
                        toHtml (spanText (configSpan c))
                        ", with the reasoning kept as comments. Diff it against your own when you are done."
                div_ $ do
                    h3_ "What is deliberately left out"
                    p_ (courseLeftOut c)
    script_ [] (indexJs c)
  where
    meta' :: Text -> Text -> Html ()
    meta' big small = div_ (strong_ (toHtml big) <> span_ (toHtml small))
    spanText Nothing = "the course"
    spanText (Just (a, b))
        | a == b = "Day " <> tshow a
        | otherwise = "Days " <> tshow a <> "–" <> tshow b

indexJs :: Course -> Text
indexJs c =
    T.unlines
        [ "(function(){try{"
        , "document.querySelectorAll('[data-day]').forEach(function(el){"
        , "var v=localStorage.getItem('" <> courseSlug c <> "-course:day'+el.dataset.day);if(!v)return;"
        , "var p=v.split('/');var s=document.createElement('span');s.className='progress';"
        , "s.textContent='drills '+v;if(p[0]===p[1]&&p[1]!=='0')s.classList.add('done');"
        , "el.appendChild(s)})}catch(e){}})();"
        ]

-- ---------------------------------------------------------------------------
-- reference
-- ---------------------------------------------------------------------------

pageReference :: Course -> Html ()
pageReference c = shell_ c "" "day reference" ("Reference · " <> courseTitle c) $ do
    masthead c "" Nothing
    main_ [id_ "main"] $ article_ $ do
        div_ [class_ "hero"] $ do
            p_ [class_ "hero-num"] "Reference"
            h1_ "Everything, on one page"
            p_
                [class_ "hero-sub"]
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
            tbody_ $ forM_ (courseDays c) $ \d ->
                forM_ (sel d) $ \(a, b) -> tr_ $ do
                    td_ (if cls == "keys" then keyChips a else code_ (toHtml a))
                    td_ b
                    td_ $
                        a_
                            [href_ (T.pack (dayDir (dayNum d)) <> "/index.html")]
                            (toHtml (tshow (dayNum d)))

-- ---------------------------------------------------------------------------
-- the config file
-- ---------------------------------------------------------------------------

{- | The config file assembled from every day's blocks; 'Nothing' when the
course has no config thread.
-}
configFileText :: Course -> Maybe Text
configFileText c = do
    cf <- courseConfig c
    pure . T.unlines $
        cfHeader cf
            <> concatMap section' (filter (not . null . dayConfig) (courseDays c))
  where
    cm = maybe "#" cfComment (courseConfig c)
    rule = cm <> " " <> T.replicate 74 "="
    section' d =
        [ ""
        , rule
        , cm <> " Day " <> pad (dayNum d) <> " - " <> dayTitle d
        , rule
        ]
            <> concatMap blk (dayConfig d)
    blk b =
        ""
            : map ((cm <> " ") <>) (T.lines (cbTitle b))
                <> T.lines (T.strip (cbCode b))
