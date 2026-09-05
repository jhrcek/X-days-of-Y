-- | The course, in order.
module Course.Days (allDays) where

import Course.Types (Day)

import Course.Day.D01 qualified as D01
import Course.Day.D02 qualified as D02
import Course.Day.D03 qualified as D03
import Course.Day.D04 qualified as D04
import Course.Day.D05 qualified as D05
import Course.Day.D06 qualified as D06
import Course.Day.D07 qualified as D07
import Course.Day.D08 qualified as D08
import Course.Day.D09 qualified as D09
import Course.Day.D10 qualified as D10
import Course.Day.D11 qualified as D11
import Course.Day.D12 qualified as D12
import Course.Day.D13 qualified as D13
import Course.Day.D14 qualified as D14

allDays :: [Day]
allDays =
  [ D01.day
  , D02.day
  , D03.day
  , D04.day
  , D05.day
  , D06.day
  , D07.day
  , D08.day
  , D09.day
  , D10.day
  , D11.day
  , D12.day
  , D13.day
  , D14.day
  ]
