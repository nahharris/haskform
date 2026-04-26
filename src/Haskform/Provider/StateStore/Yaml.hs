{-# LANGUAGE DerivingStrategies #-}

module Haskform.Provider.StateStore.Yaml
  ( YamlStateStore(..)
  , defaultYamlStateStore
  ) where

import GHC.Generics (Generic)
import Data.Yaml (decodeFileEither, encodeFile)
import Haskform.Core.State
import Haskform.Provider.Protocol (StateStore(..))
import System.Directory (doesFileExist)

newtype YamlStateStore = YamlStateStore
  { yamlFilePath :: FilePath
  } deriving (Show, Generic)

defaultYamlStateStore :: FilePath -> YamlStateStore
defaultYamlStateStore = YamlStateStore

instance StateStore YamlStateStore where
  loadState store = do
    let path = yamlFilePath store
    exists <- doesFileExist path
    if exists
      then do
        result <- decodeFileEither path
        case result of
          Right state -> pure (Just state)
          Left{} -> pure Nothing
      else pure Nothing

  saveState store state = do
    let path = yamlFilePath store
    encodeFile path state