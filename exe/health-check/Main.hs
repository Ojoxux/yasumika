{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import Calendar
  ( CalendarConfig
  , getTodayJST
  , loadCalendar
  , todayMessage
  )
import Control.Monad (void)
import Control.Monad.IO.Class (liftIO)
import Data.Text (isPrefixOf, toLower)
import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import Env (requireEnv)
import Discord
import Discord.Types
import qualified Discord.Requests as R

main :: IO ()
main = do
  cfg <- loadCalendar
  token <- requireEnv "DISCORD_BOT_TOKEN"

  userFacingError <- runDiscord $ def
    { discordToken = "Bot " <> T.pack token
    , discordOnEvent = eventHandler cfg
    , discordOnLog = \message -> TIO.putStrLn message >> TIO.putStrLn ""
    }

  TIO.putStrLn userFacingError

eventHandler :: CalendarConfig -> Event -> DiscordHandler ()
eventHandler cfg event = case event of
  MessageCreate message
    | not (fromBot message) ->
        case healthCommand (messageContent message) of
          Just Ping -> replyPing message
          Just Health -> replyHealth cfg message
          Nothing -> pure ()
  _ -> pure ()

data HealthCommand = Ping | Health

healthCommand :: T.Text -> Maybe HealthCommand
healthCommand content =
  case toLower content of
    cmd | "!ping" `isPrefixOf` cmd -> Just Ping
    cmd | "!health" `isPrefixOf` cmd -> Just Health
    _ -> Nothing

replyPing :: Message -> DiscordHandler ()
replyPing message =
  void $ restCall $ R.CreateMessage (messageChannelId message) "pong"

replyHealth :: CalendarConfig -> Message -> DiscordHandler ()
replyHealth cfg message = do
  day <- liftIO getTodayJST
  let status = todayMessage day cfg
  void $
    restCall $
      R.CreateMessage (messageChannelId message) ("ok · " <> status)

fromBot :: Message -> Bool
fromBot = userIsBot . messageAuthor
