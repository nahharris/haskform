{-# LANGUAGE DerivingStrategies #-}

module Haskform.Provider.Protocol
  ( Provider(..)
  , ProviderM()
  , runProviderM
  , StateStore(..)
  , ProviderConfig(..)
  ) where

import Control.Monad.Trans.Reader (ReaderT, runReaderT)
import GHC.Generics (Generic)
import Haskform.Core.State

class Provider p where
  providerName :: p -> String
  providerVersion :: p -> String

newtype ProviderM p a = ProviderM (ReaderT (ProviderConfig p) IO a)
  deriving (Functor, Applicative, Monad)

data ProviderConfig p = ProviderConfig
  { pcStateStore :: SomeStateStore
  , pcProvider   :: p
  } deriving (Generic)

data SomeStateStore = forall s. StateStore s => SomeStateStore s

class StateStore s where
  loadState :: s -> IO (Maybe State)
  saveState :: s -> State -> IO ()

runProviderM :: ProviderM p a -> ProviderConfig p -> IO a
runProviderM (ProviderM m) = runReaderT m