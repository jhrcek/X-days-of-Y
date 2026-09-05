-- | The shape of one lesson.
--
-- Every day module in "Course.Day" exports a single 'Day'. Nothing else in the
-- course is hand-written HTML: the renderer turns these values into the pages,
-- the cumulative reference and @tmux.conf@.
module Course.Types
  ( Day (..)
  , Diagram (..)
  , Entry
  , ConfBlock (..)
  , diagram
  ) where

import Data.Text (Text)
import Lucid (Html)

-- | One key, command or option, paired with what it does.
type Entry = (Text, Html ())

-- | A block of configuration the lesson adds to @~/.tmux.conf@. The title is
-- plain text because it is reused as a comment in the generated config file.
data ConfBlock = ConfBlock
  { cbTitle :: Text
  , cbCode  :: Text
  }

-- | An olog: boxes are types (\"a session\"), arrows are aspects (\"is attached
-- to\"). Only the statement list is supplied; the renderer adds the shared
-- graphviz preamble so every diagram in the course looks the same.
data Diagram = Diagram
  { dgAlt     :: Text      -- ^ @alt@ text for the @<img>@
  , dgCaption :: Html ()   -- ^ figure caption
  , dgRankdir :: Text      -- ^ @TB@ or @LR@
  , dgNodesep :: Text
  , dgRanksep :: Text
  , dgBody    :: Text      -- ^ graphviz statements
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
  { dayNum      :: Int
  , dayTitle    :: Text
  , daySubtitle :: Text     -- ^ one line, shown under the title and on the index card
  , dayMinutes  :: Int
  , dayLevel    :: Text     -- ^ essential / intermediate / advanced
  , dayManRef   :: Text     -- ^ the man page section(s) this lesson distils
  , dayTags     :: [Text]
  , dayGoals    :: [Html ()]
  , dayBody     :: Html () -> Html ()
    -- ^ the lesson. The argument is the rendered olog figure, so the day
    -- decides where in the prose it belongs.
  , dayDiagram  :: Maybe Diagram
  , dayKeys     :: [Entry]
  , dayCmds     :: [Entry]
  , dayOpts     :: [Entry]
  , dayConfig   :: [ConfBlock]
  , dayDrills   :: [Html ()]
  , dayQuiz     :: [(Html (), Html ())]
  , dayCheat    :: Html ()
  }
