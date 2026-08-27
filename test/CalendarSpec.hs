{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import Calendar
  ( CalendarConfig (..)
  , DayEntry (..)
  , emptyCalendarConfig
  , isDayOff
  , readDay
  , todayMessage
  )
import Data.Text (pack)
import Data.Time (Day)
import System.Exit (exitFailure)

main :: IO ()
main =
  if failures == []
    then pure ()
    else do
      mapM_ print failures
      exitFailure
  where
    failures = concat
      [ [ "2026-07-06 should be off" | not (isDayOff day20260706 cfg) ]
      , [ "2026-07-07 should be school" | isDayOff day20260707 cfg ]
      , [ "2026-07-12 should be off (Sunday)" | not (isDayOff day20260712 cfg) ]
      , [ "2026-07-20 should be off (Marine Day)" | not (isDayOff day20260720 cfg) ]
      , [ "2026-07-21 should be school" | isDayOff day20260721 cfg ]
      , [ "2026-07-27 should be off" | not (isDayOff day20260727 cfg) ]
      , [ "2026-08-03 should be off" | not (isDayOff day20260803 cfg) ]
      , [ "2026-08-04 should be school (no makeup exam days)" | isDayOff day20260804 cfg ]
      , [ "message for school day" | todayMessage day20260707 cfg /= "今日は学校っす" ]
      , [ "message for holiday" | todayMessage day20260706 cfg /= "今日は休みっす" ]
      , [ "readDay parses YYYY-MM-DD" | readDay "2026-07-06" /= Just day20260706 ]
      , [ "empty config: Sunday should be off" | not (isDayOff day20260712 emptyCalendarConfig) ]
      , [ "empty config: weekday without holiday should be school" | isDayOff day20260707 emptyCalendarConfig ]
      ]

cfg :: CalendarConfig
cfg =
  CalendarConfig
    { closedDates =
        [ DayEntry day20260706 "休み"
        , DayEntry day20260727 "休み"
        , DayEntry day20260803 "休み"
        ]
    , openDates = []
    }

day20260706, day20260707, day20260712, day20260720, day20260721, day20260727, day20260803, day20260804 :: Day
day20260706 = mustDay "2026-07-06"
day20260707 = mustDay "2026-07-07"
day20260712 = mustDay "2026-07-12"
day20260720 = mustDay "2026-07-20"
day20260721 = mustDay "2026-07-21"
day20260727 = mustDay "2026-07-27"
day20260803 = mustDay "2026-08-03"
day20260804 = mustDay "2026-08-04"

mustDay :: String -> Day
mustDay value =
  case readDay (pack value) of
    Just day -> day
    Nothing -> error $ "invalid test date: " ++ value
