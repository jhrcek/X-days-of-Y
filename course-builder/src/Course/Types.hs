{- | The shape of a course and of one lesson.

A course package exports a single 'Course'. Nothing in a course is
hand-written HTML: the renderer turns these values into the pages, the
cumulative reference and (optionally) the config file the course builds up.
-}
module Course.Types
    ( Course (..)
    , ConfigFile (..)
    , Day (..)
    , Diagram (..)
    , Entry
    , ConfBlock (..)
    , diagram
    ) where

import Data.Text (Text)
import Lucid (Html)

-- ---------------------------------------------------------------------------
-- course
-- ---------------------------------------------------------------------------

-- | Everything about a course that is not one of its days.
data Course = Course
    { courseSlug :: Text
    -- ^ directory name under the repo root, and the @localStorage@ key prefix
    , courseTool :: Text
    -- ^ display name, as in \"14 Days of /tmux/\"
    , courseManRef :: Text
    -- ^ the manual page, e.g. @tmux(1)@ (footer)
    , courseVersion :: Text
    -- ^ what the course was checked against, e.g. @tmux 3.7c@ (footer)
    , courseTagline :: Html ()
    -- ^ the paragraph under the big title on the course's index page
    , courseHowTo :: [(Text, Html ())]
    -- ^ the \"How to use this\" cards (title, body); three reads best
    , courseLeftOut :: Html ()
    -- ^ the \"What is deliberately left out\" paragraph
    , courseCardBlurb :: Html ()
    -- ^ one paragraph for the card on the repo-root landing page
    , courseCardTags :: [Text]
    -- ^ small tags on that card
    , courseConfig :: Maybe ConfigFile
    -- ^ the config file the course builds up, if the tool has one
    , courseDays :: [Day]
    }

-- | The configuration file assembled from the days' 'ConfBlock's.
data ConfigFile = ConfigFile
    { cfFileName :: Text
    -- ^ written to the course root and linked from the pages, e.g. @tmux.conf@
    , cfUserPath :: Text
    -- ^ where the reader keeps theirs, e.g. @~/.tmux.conf@
    , cfReloadHint :: Html ()
    -- ^ shown under each day's config box: how to make the tool re-read it
    , cfHeader :: [Text]
    -- ^ raw lines at the top of the generated file, comment markers included
    }

-- ---------------------------------------------------------------------------
-- day
-- ---------------------------------------------------------------------------

-- | One key, command or option, paired with what it does.
type Entry = (Text, Html ())

{- | A block of configuration the lesson adds to the course's config file. The
title is plain text because it is reused as a comment in the generated file.
-}
data ConfBlock = ConfBlock
    { cbTitle :: Text
    , cbCode :: Text
    }

{- | An olog: boxes are types (\"a session\"), arrows are aspects (\"is attached
to\"). Only the statement list is supplied; the renderer adds the shared
graphviz preamble so every diagram in the course looks the same.
-}
data Diagram = Diagram
    { dgAlt :: Text
    -- ^ @alt@ text for the @<img>@
    , dgCaption :: Html ()
    -- ^ figure caption
    , dgRankdir :: Text
    -- ^ @TB@ or @LR@
    , dgNodesep :: Text
    , dgRanksep :: Text
    , dgBody :: Text
    -- ^ graphviz statements
    }

-- | A 'Diagram' with the usual settings; override fields as needed.
diagram :: Text -> Text -> Diagram
diagram alt body =
    Diagram
        { dgAlt = alt
        , dgCaption = mempty
        , dgRankdir = "TB"
        , dgNodesep = "0.35"
        , dgRanksep = "0.5"
        , dgBody = body
        }

data Day = Day
    { dayNum :: Int
    , dayTitle :: Text
    , daySubtitle :: Text
    -- ^ one line, shown under the title and on the index card
    , dayMinutes :: Int
    , dayLevel :: Text
    -- ^ essential / intermediate / advanced
    , dayManRef :: Text
    -- ^ the man page section(s) this lesson distils
    , dayTags :: [Text]
    , dayGoals :: [Html ()]
    , dayBody :: Html () -> Html ()
    {- ^ the lesson. The argument is the rendered olog figure, so the day
    decides where in the prose it belongs.
    -}
    , dayDiagram :: Maybe Diagram
    , dayKeys :: [Entry]
    , dayCmds :: [Entry]
    , dayOpts :: [Entry]
    , dayConfig :: [ConfBlock]
    , dayDrills :: [Html ()]
    , dayQuiz :: [(Html (), Html ())]
    , dayCheat :: Html ()
    }
