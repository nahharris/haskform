module Haskform.DSL.SmartConstructors
  ( mkResource
  , readState
  , writeState
  , deleteResource
  , logDebug
  , logInfo
  , logWarn
  , logError
  ) where

import Haskform.DSL.Core

logDebug :: String -> IaC ()
logDebug msg = logMsg LogDebug msg

logInfo :: String -> IaC ()
logInfo msg = logMsg LogInfo msg

logWarn :: String -> IaC ()
logWarn msg = logMsg LogWarn msg

logError :: String -> IaC ()
logError msg = logMsg LogError msg