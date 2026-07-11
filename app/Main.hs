{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import Control.Monad (void, when)
import Data.Text (isPrefixOf, toLower)
import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import Discord
import Discord.Types
import qualified Discord.Requests as R
import System.Environment (lookupEnv)
import System.Exit (exitFailure)

main :: IO ()
main = do
  maybeToken <- lookupEnv "DISCORD_TOKEN"
  token <- case maybeToken of
    Just value | not (null value) -> pure value
    _ -> do
      TIO.putStrLn "DISCORD_TOKEN is not set. Set it to your bot token and try again."
      exitFailure

  userFacingError <- runDiscord $ def
    { discordToken = "Bot " <> T.pack token
    , discordOnEvent = eventHandler
    , discordOnLog = \message -> TIO.putStrLn message >> TIO.putStrLn ""
    }

  TIO.putStrLn userFacingError

-- | Respond to messages beginning with "!hello", ignoring other bots.
eventHandler :: Event -> DiscordHandler ()
eventHandler event = case event of
  MessageCreate message -> when (isHello message && not (fromBot message)) $ do
    void $ restCall $ R.CreateMessage (messageChannelId message) "Hello, world!"
  _ -> pure ()

fromBot :: Message -> Bool
fromBot = userIsBot . messageAuthor

isHello :: Message -> Bool
isHello = ("!hello" `isPrefixOf`) . toLower . messageContent
