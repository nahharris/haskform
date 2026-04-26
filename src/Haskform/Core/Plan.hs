{-# LANGUAGE DerivingStrategies #-}

module Haskform.Core.Plan
  ( Plan(..)
  , ResourcePlan(..)
  , PlanAction(..)
  , computePlan
  ) where

import GHC.Generics (Generic)
import Haskform.Core.State
import qualified Data.HashMap.Strict as HashMap

data Plan = Plan
  { planCreates :: [ResourcePlan]
  , planUpdates :: [ResourcePlan]
  , planDeletes :: [ResourcePlan]
  } deriving (Show, Generic)

data ResourcePlan = ResourcePlan
  { rpId   :: ResourceId
  , rpType :: ResourceType
  , rpName :: String
  , rpAction :: PlanAction
  } deriving (Show, Generic, Eq)

data PlanAction = Create | Update | Delete | NoChange
  deriving (Show, Generic, Eq)

computePlan :: State -> State -> Plan
computePlan current desired = Plan
  { planCreates = toCreate
  , planUpdates = toUpdate
  , planDeletes = toDelete
  }
  where
    currentIds = HashMap.keysSet (stateResources current)
    desiredIds = HashMap.keysSet (stateResources desired)

    desiredList = HashMap.toList (stateResources desired)
    currentList = HashMap.toList (stateResources current)

    toCreate = filter (\p -> not $ rpId p `HashMap.member` stateResources current) desiredPlans
    toDelete = filter (\p -> not $ rpId p `HashMap.member` stateResources desired) currentPlans
    toUpdate = [] -- TODO: implement update detection

    currentPlans = flip fmap currentList $ \(rid, res) ->
      ResourcePlan rid (resourceType res) (resourceName res) Delete

    desiredPlans = flip fmap desiredList $ \(rid, res) ->
      ResourcePlan rid (resourceType res) (resourceName res) Create