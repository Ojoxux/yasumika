{-# LANGUAGE OverloadedStrings #-}

module Env
  ( requireEnv
  , envFlag
  ) where

import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import System.Environment (lookupEnv)
import System.Exit (exitFailure)

requireEnv :: String -> IO String
requireEnv name = do
  value <- lookupEnv name
  case value of
    Just v | not (null v) -> pure v
    _ -> do
      TIO.putStrLn $
        T.pack name
          <> " is not set. Add it to .env and run `direnv allow` in this directory."
      exitFailure

envFlag :: String -> IO Bool
envFlag name = do
  value <- lookupEnv name
  pure $ case value of
    Just v -> not (null v)
    Nothing -> False
