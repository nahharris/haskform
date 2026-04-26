{-# LANGUAGE DerivingStrategies #-}

module Haskform.Core.State
  ( State(..)
  , ResourceId(..)
  , ResourceType(..)
  , ResourceT(..)
  , Resource
  , emptyState
  ) where

import GHC.Generics (Generic)
import Data.Hashable (Hashable)
import Data.Aeson (ToJSON, FromJSON, ToJSONKey, FromJSONKey)
import Data.HashMap.Strict (HashMap)
import qualified Data.HashMap.Strict as HashMap

newtype ResourceId = ResourceId { unResourceId :: String }
  deriving stock (Eq, Ord, Show, Generic)
  deriving newtype Hashable

newtype ResourceType = ResourceType { unResourceType :: String }
  deriving stock (Eq, Show, Generic)

data ResourceT a = ResourceT
  { resourceId      :: ResourceId
  , resourceType    :: ResourceType
  , resourceName    :: String
  , resourceValue   :: a
  } deriving (Generic, Show, Functor)

type Resource a = ResourceT a

data State = State
  { stateResources :: HashMap ResourceId (Resource ())
  , stateVersion   :: Word
  } deriving (Show, Generic)

instance ToJSON ResourceId
instance ToJSONKey ResourceId
instance FromJSON ResourceId
instance FromJSONKey ResourceId
instance ToJSON ResourceType
instance FromJSON ResourceType
instance ToJSON (ResourceT ())
instance FromJSON (ResourceT ())
instance ToJSON State
instance FromJSON State

emptyState :: State
emptyState = State HashMap.empty 0