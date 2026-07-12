{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}

module Calendar
  ( CalendarConfig (..)
  , DayEntry (..)
  , getTodayJST
  , isDayOff
  , loadCalendar
  , readDay
  , todayMessage
  ) where

import Data.Aeson (FromJSON (..), eitherDecodeStrict, withObject, (.:))
import qualified Data.ByteString as BS
import Data.Holiday.Japan (isHoliday)
import Data.Text (Text)
import qualified Data.Text as T
import Data.Time (Day, TimeZone, dayOfWeek, localDay, minutesToTimeZone, utcToLocalTime)
import Data.Time.Calendar (DayOfWeek (..))
import Data.Time.Clock (getCurrentTime)
import Data.Time.Format (defaultTimeLocale, parseTimeM)
import GHC.Generics (Generic)
import System.Environment (lookupEnv)

data CalendarConfig = CalendarConfig
  { closedDates :: [DayEntry]
  , openDates :: [DayEntry]
  }
  deriving (Eq, Show, Generic)

data DayEntry = DayEntry
  { date :: Day
  , label :: Text
  }
  deriving (Eq, Show, Generic)

instance FromJSON CalendarConfig
instance FromJSON DayEntry where
  parseJSON = withObject "DayEntry" $ \obj -> do
    dateText <- obj .: "date"
    entryLabel <- obj .: "label"
    case readDay dateText of
      Just day -> pure DayEntry {date = day, label = entryLabel}
      Nothing -> fail $ "invalid date: " ++ T.unpack dateText

readDay :: Text -> Maybe Day
readDay = parseTimeM True defaultTimeLocale "%Y-%m-%d" . T.unpack

jstTimeZone :: TimeZone
jstTimeZone = minutesToTimeZone 540

getTodayJST :: IO Day
getTodayJST = do
  now <- getCurrentTime
  pure . localDay $ utcToLocalTime jstTimeZone now

loadCalendar :: IO CalendarConfig
loadCalendar = do
  path <- fromMaybe "data/calendar.json" <$> lookupEnv "CALENDAR_PATH"
  bytes <- BS.readFile path
  case eitherDecodeStrict bytes of
    Left err -> fail $ "failed to parse calendar JSON: " ++ err
    Right cfg -> pure cfg

isDayOff :: Day -> CalendarConfig -> Bool
isDayOff day cfg
  | day `elem` map date (openDates cfg) = False
  | day `elem` map date (closedDates cfg) = True
  | isWeekend day = True
  | isHoliday day = True
  | otherwise = False

todayMessage :: Day -> CalendarConfig -> Text
todayMessage day cfg
  | isDayOff day cfg = "今日は休みっす"
  | otherwise = "今日は学校っす"

isWeekend :: Day -> Bool
isWeekend day = case dayOfWeek day of
  Saturday -> True
  Sunday -> True
  _ -> False

fromMaybe :: a -> Maybe a -> a
fromMaybe defaultValue = maybe defaultValue id
