{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import Calendar (getTodayJST, isDayOff, loadCalendar, todayMessage)
import Control.Exception (throwIO)
import Data.Aeson (ToJSON, encode)
import Data.ByteString.Char8 (pack)
import Env (envFlag, requireEnv)
import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import GHC.Generics (Generic)
import Network.HTTP.Client
import Network.HTTP.Client.TLS
import Network.HTTP.Types (methodPost, statusCode)

main :: IO ()
main = do
  day <- getTodayJST
  cfg <- loadCalendar

  if isDayOff day cfg
    then TIO.putStrLn "skipped: 休みのため投稿なし"
    else do
      let message = todayMessage day cfg
      dryRun <- envFlag "DRY_RUN"
      if dryRun
        then TIO.putStrLn $ "dry-run: " <> message
        else do
          token <- requireEnv "DISCORD_BOT_TOKEN"
          channelId <- requireEnv "DISCORD_CHANNEL_ID"
          sendDiscordMessage token channelId message
          TIO.putStrLn $ "posted: " <> message

data CreateMessageBody = CreateMessageBody
  { content :: T.Text
  }
  deriving (Generic)

instance ToJSON CreateMessageBody

sendDiscordMessage :: String -> String -> T.Text -> IO ()
sendDiscordMessage token channelId message = do
  manager <- newTlsManager
  let url =
        "https://discord.com/api/v10/channels/"
          ++ channelId
          ++ "/messages"
  request <- parseRequest url
  let req =
        request
          { method = methodPost
          , requestHeaders =
              [ ("Authorization", "Bot " <> pack token)
              , ("Content-Type", "application/json")
              ]
          , requestBody =
              RequestBodyLBS $
                encode $
                  CreateMessageBody message
          }
  response <- httpLbs req manager
  let code = statusCode (responseStatus response)
  if code >= 200 && code < 300
    then pure ()
    else throwIO $
        userError $
          "Discord API error: "
            ++ show (responseStatus response)
            ++ " "
            ++ show (responseBody response)
