{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Haskform.DSL.Interpreters
  ( PlanResult(..)
  , planInterpreter
  , ApplyResult(..)
  , applyInterpreter
  , MockState(..)
  , mockInterpreter
  , runIaC
  , IaCError(..)
  , MonadProvider(..)
  ) where

import GHC.Generics (Generic)
import Control.Monad.IO.Class (MonadIO, liftIO)
import Haskform.DSL.Core
import Haskform.Core.State
import Haskform.Core.Plan
import qualified Data.HashMap.Strict as HashMap

data IaCError
  = IaCError String
  deriving (Show, Generic)

data PlanResult = PlanResult
  { prState :: State
  , prPlan  :: Plan
  , prLogs  :: [(LogLevel, String)]
  } deriving (Show, Generic)

planInterpreter
  :: State
  -> IaC a
  -> Either IaCError (PlanResult, a)
planInterpreter initialState prog = iter prog initialResult
  where
    initialResult = PlanResult initialState (Plan [] [] []) []

    iter :: IaC a -> PlanResult -> Either IaCError (PlanResult, a)
    iter (Pure a) pr = Right (pr, a)
    iter (Op op k) pr = case op of
      MkResourceOp rt (ResourceConfig cfg) -> do
        let currentSt = prState pr
            newId = ResourceId $ "resource-" <> show (HashMap.size (stateResources currentSt))
            newResource = ResourceT
              { resourceId = newId
              , resourceType = rt
              , resourceName = ""
              , resourceValue = ()
              }
            rp = ResourcePlan newId rt "" Create
            newState = State
              { stateResources = HashMap.insert newId newResource (stateResources currentSt)
              , stateVersion = stateVersion currentSt + 1
              }
            currentPlan = prPlan pr
            newPlan = Plan
              { planCreates = rp : planCreates currentPlan
              , planUpdates = planUpdates currentPlan
              , planDeletes = planDeletes currentPlan
              }
        iter (k (ResourceT newId rt "" cfg)) (PlanResult newState newPlan [])
      ReadStateOp -> iter (k (prState pr)) pr
      WriteStateOp _ -> Left (IaCError "WriteState not supported in plan interpreter")
      DeleteResourceOp rid -> do
        let currentSt = prState pr
            newState = State
              { stateResources = HashMap.delete rid (stateResources currentSt)
              , stateVersion = stateVersion currentSt + 1
              }
            rp = ResourcePlan rid (ResourceType "") "" Delete
            currentPlan = prPlan pr
            newPlan = Plan
              { planCreates = planCreates currentPlan
              , planUpdates = planUpdates currentPlan
              , planDeletes = rp : planDeletes currentPlan
              }
        iter (k ()) (PlanResult newState newPlan [])
      LogOp level msg -> iter (k ()) (pr { prLogs = (level, msg) : prLogs pr })

data ApplyResult = ApplyResult { arState :: State }
  deriving (Show, Generic)

class Monad m => MonadProvider p m | p -> m where
  createResource :: p -> ResourceType -> a -> m (Resource a)
  readResource :: p -> ResourceId -> m (Maybe (Resource ()))
  updateResource :: p -> ResourceId -> ResourceType -> a -> m (Resource a)
  deleteResourceImpl :: p -> ResourceId -> m ()

applyInterpreter
  :: forall p m a. (MonadProvider p m, MonadIO m)
  => p
  -> State
  -> IaC a
  -> m (Either IaCError (ApplyResult, a))
applyInterpreter provider initialState prog = iter prog initialState >>= \result ->
  pure (fmap (\(st, a) -> (ApplyResult st, a)) result)
  where
    iter :: IaC b -> State -> m (Either IaCError (State, b))
    iter (Pure a) st = pure (Right (st, a))
    iter (Op op k) st = case op of
      MkResourceOp rt (ResourceConfig cfg) -> do
        res <- createResource provider rt cfg
        iter (k res) st
      ReadStateOp -> iter (k st) st
      WriteStateOp newSt -> iter (k ()) newSt
      DeleteResourceOp rid -> do
        deleteResourceImpl provider rid
        iter (k ()) st
      LogOp level msg -> do
        liftIO $ putStrLn $ show level <> ": " <> msg
        iter (k ()) st

newtype MockState = MockState { unMockState :: State }
  deriving (Show, Generic)

mockInterpreter :: IaC a -> Either IaCError (MockState, a)
mockInterpreter prog = iter prog initialState >>= \result ->
  pure $ (\(st, a) -> (MockState st, a)) result
  where
    initialState = State HashMap.empty 0

    iter :: IaC b -> State -> Either IaCError (State, b)
    iter (Pure a) st = Right (st, a)
    iter (Op op k) st = case op of
      MkResourceOp rt (ResourceConfig cfg) -> do
        let newId = ResourceId $ "mock-" <> show (HashMap.size (stateResources st))
            newResource = ResourceT
              { resourceId = newId
              , resourceType = rt
              , resourceName = ""
              , resourceValue = ()
              }
            newSt = st { stateResources = HashMap.insert newId newResource (stateResources st) }
        iter (k (ResourceT newId rt "" cfg)) newSt
      ReadStateOp -> iter (k st) st
      WriteStateOp newSt -> iter (k ()) newSt
      DeleteResourceOp rid -> do
        let newSt = st { stateResources = HashMap.delete rid (stateResources st) }
        iter (k ()) newSt
      LogOp _ _msg -> iter (k ()) st

runIaC :: IaC a -> Either IaCError a
runIaC = fmap snd . mockInterpreter