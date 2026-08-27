{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}

module Calendar
  ( CalendarConfig (..)
  , DayEntry (..)
  , emptyCalendarConfig
  , getTodayJST
  , isDayOff
  , loadCalendar
  , readDay
  , todayMessage
  ) where

import Control.Exception (SomeException, try)
import Data.Aeson (FromJSON (..), eitherDecodeStrict, withObject, (.:))
import qualified Data.ByteString as BS
import qualified Data.ByteString.Char8 as BS8
import qualified Data.ByteString.Lazy as BSL
import Data.Holiday.Japan (isHoliday)
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import Data.Time (Day, TimeZone, dayOfWeek, localDay, minutesToTimeZone, utcToLocalTime)
import Data.Time.Calendar (DayOfWeek (..))
import Data.Time.Clock (getCurrentTime)
import Data.Time.Format (defaultTimeLocale, parseTimeM)
import GHC.Generics (Generic)
import Network.HTTP.Client
import Network.HTTP.Client.TLS
import Network.HTTP.Types (statusCode)
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

emptyCalendarConfig :: CalendarConfig
emptyCalendarConfig = CalendarConfig {closedDates = [], openDates = []}

loadCalendar :: IO CalendarConfig
loadCalendar = do
  apiUrl <- lookupEnv "CALENDAR_API_URL"
  case apiUrl of
    Just url -> loadCalendarFromApi url
    Nothing -> loadCalendarFromFile

loadCalendarFromFile :: IO CalendarConfig
loadCalendarFromFile = do
  path <- fromMaybe "data/calendar.json" <$> lookupEnv "CALENDAR_PATH"
  bytes <- BS.readFile path
  case eitherDecodeStrict bytes of
    Left err -> fail $ "failed to parse calendar JSON: " ++ err
    Right cfg -> pure cfg

loadCalendarFromApi :: String -> IO CalendarConfig
loadCalendarFromApi url = do
  result <- try (fetchCalendarBytes url) :: IO (Either SomeException BS.ByteString)
  case result of
    Left err -> do
      TIO.putStrLn $ "warning: failed to fetch calendar from " <> T.pack url <> ": " <> T.pack (show err)
      pure emptyCalendarConfig
    Right bytes -> case eitherDecodeStrict bytes of
      Left err -> do
        TIO.putStrLn $ "warning: failed to parse calendar JSON from " <> T.pack url <> ": " <> T.pack err
        pure emptyCalendarConfig
      Right cfg -> pure cfg

fetchCalendarBytes :: String -> IO BS.ByteString
fetchCalendarBytes url = do
  clientId <- lookupEnv "CF_ACCESS_CLIENT_ID"
  clientSecret <- lookupEnv "CF_ACCESS_CLIENT_SECRET"
  manager <- newTlsManager
  baseRequest <- parseRequest url
  let accessHeaders = case (clientId, clientSecret) of
        (Just cid, Just secret) ->
          [ ("CF-Access-Client-Id", BS8.pack cid)
          , ("CF-Access-Client-Secret", BS8.pack secret)
          ]
        _ -> []
      request =
        baseRequest
          { requestHeaders = requestHeaders baseRequest ++ accessHeaders
          , responseTimeout = responseTimeoutMicro (5 * 1000000)
          }
  response <- httpLbs request manager
  let code = statusCode (responseStatus response)
  if code >= 200 && code < 300
    then pure $ BSL.toStrict (responseBody response)
    else fail $ "calendar API returned status " ++ show code

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
