{- | The small vocabulary the lesson modules are written in.

Day modules import this and nothing else beyond "Lucid": if a lesson needs a
new kind of visual element, it gets added here so every day looks the same.
-}
module Course.Markup
    ( -- * Inline
      k
    , c
    , opt
    , var

      -- * Blocks
    , block
    , sh
    , cfg
    , ascii

      -- * Terminal mock-ups
    , termWin
    , termStatus

      -- * Callouts
    , note
    , tip
    , gotcha
    , why

      -- * Predicates
    , isConfComment

      -- * Lists
    , steps
    , defs
    , cols
    ) where

import Data.Text (Text)
import Data.Text qualified as T
import Lucid

-- ---------------------------------------------------------------------------
-- inline
-- ---------------------------------------------------------------------------

-- | Key chips. @k "C-b c"@ renders two chips: @C-b@ then @c@.
k :: Text -> Html ()
k = foldMap (kbd_ . toHtml) . T.words

-- | Inline code.
c :: Text -> Html ()
c = code_ . toHtml

-- | An option name; styled like code but marked up so the reference can find it.
opt :: Text -> Html ()
opt = code_ [class_ "opt"] . toHtml

-- | A placeholder inside a command synopsis, e.g. @var "target-pane"@.
var :: Text -> Html ()
var = i_ [class_ "var"] . toHtml

-- ---------------------------------------------------------------------------
-- blocks
-- ---------------------------------------------------------------------------

-- | A titled section of the lesson.
block :: Text -> Html () -> Html ()
block heading inner = section_ [class_ "block"] $ do
    h2_ (toHtml heading)
    inner

-- | A shell transcript. Lines beginning with @$@ are treated as commands.
sh :: [Text] -> Html ()
sh ls = pre_ [class_ "sh"] $ code_ $ foldMap line ls
  where
    line l
        | "$ " `T.isPrefixOf` l =
            span_ [class_ "prompt"] "$ " <> span_ [class_ "cmd"] (toHtml (T.drop 2 l)) <> "\n"
        | "# " `T.isPrefixOf` l = span_ [class_ "comment"] (toHtml l) <> "\n"
        | otherwise = toHtml l <> "\n"

{- | A config-file excerpt shown inside the prose (the per-day \"add this\"
box is generated separately from 'Course.Types.ConfBlock').
-}
cfg :: [Text] -> Html ()
cfg ls = pre_ [class_ "conf"] $ code_ $ foldMap confLine ls

confLine :: Text -> Html ()
confLine l
    | isConfComment l = span_ [class_ "comment"] (toHtml l) <> "\n"
    | otherwise = toHtml l <> "\n"

{- | A comment line in a config-file excerpt. Both markers are recognised, so
the same helper works for hash-commented and SQL-commented formats.
-}
isConfComment :: Text -> Bool
isConfComment l = any (`T.isPrefixOf` T.stripStart l) ["#", "--"]

-- | Monospaced art: pane layouts, trees, tables of boxes.
ascii :: [Text] -> Html ()
ascii ls = pre_ [class_ "ascii"] $ code_ $ toHtml (T.unlines ls)

-- ---------------------------------------------------------------------------
-- terminal mock-ups
-- ---------------------------------------------------------------------------

-- | A terminal window with a caption bar and no status line.
termWin :: Text -> [Text] -> Html ()
termWin title body = div_ [class_ "term"] $ do
    termBar title
    pre_ [class_ "term-body"] $ code_ $ toHtml (T.unlines body)

-- | A terminal window showing a status line along the bottom (as tmux draws one).
termStatus :: Text -> [Text] -> Text -> Text -> Html ()
termStatus title body left right = div_ [class_ "term"] $ do
    termBar title
    pre_ [class_ "term-body"] $ code_ $ toHtml (T.unlines body)
    div_ [class_ "term-status"] $ do
        span_ [class_ "st-l"] (toHtml left)
        span_ [class_ "st-r"] (toHtml right)

termBar :: Text -> Html ()
termBar title = div_ [class_ "term-bar"] $ do
    span_ [class_ "tb-dots"] mempty
    span_ [class_ "tb-title"] (toHtml title)

-- ---------------------------------------------------------------------------
-- callouts
-- ---------------------------------------------------------------------------

callout :: Text -> Text -> Html () -> Html ()
callout cls label inner = aside_ [class_ ("call " <> cls)] $ do
    p_ [class_ "call-l"] (toHtml label)
    div_ [class_ "call-b"] inner

-- | Neutral aside.
note :: Html () -> Html ()
note = callout "note" "Note"

-- | Something that makes daily use nicer.
tip :: Html () -> Html ()
tip = callout "tip" "Worth knowing"

-- | The thing that will confuse you at 2am.
gotcha :: Html () -> Html ()
gotcha = callout "gotcha" "Gotcha"

-- | The reasoning behind a design decision in the tool itself.
why :: Html () -> Html ()
why = callout "why" "Why it works this way"

-- ---------------------------------------------------------------------------
-- lists
-- ---------------------------------------------------------------------------

-- | A numbered walk-through inside the prose (drills are separate).
steps :: [Html ()] -> Html ()
steps = ol_ [class_ "steps"] . foldMap li_

-- | Term / meaning pairs.
defs :: [(Html (), Html ())] -> Html ()
defs xs = dl_ [class_ "defs"] $ flip foldMap xs $ \(t, d) -> dt_ t <> dd_ d

-- | Side-by-side panels for comparisons.
cols :: [Html ()] -> Html ()
cols = div_ [class_ "cols"] . foldMap (div_ [class_ "col"])
