{-# LANGUAGE DerivingStrategies #-}

module Haskform.DSL.Core
  ( IaCOp(..)
  , IaC(..)
  , mkResource
  , readState
  , writeState
  , deleteResource
  , logMsg
  , ResourceConfig(..)
  , LogLevel(..)
  , module Haskform.Core.State
  ) where

import Haskform.Core.State
import GHC.Generics (Generic)

newtype ResourceConfig a = ResourceConfig { unResourceConfig :: a }
  deriving (Functor, Generic)

data LogLevel = LogDebug | LogInfo | LogWarn | LogError
  deriving (Eq, Show, Generic)

data IaCOp a where
  MkResourceOp   :: ResourceType -> ResourceConfig a -> IaCOp (Resource a)
  ReadStateOp     :: IaCOp State
  WriteStateOp   :: State -> IaCOp ()
  DeleteResourceOp :: ResourceId -> IaCOp ()
  LogOp          :: LogLevel -> String -> IaCOp ()

data IaC a where
  Pure :: a -> IaC a
  Op :: IaCOp b -> (b -> IaC a) -> IaC a

instance Functor IaC where
  fmap f (Pure a) = Pure (f a)
  fmap f (Op op k) = Op op (fmap f . k)

instance Applicative IaC where
  pure = Pure
  Pure f <*> x = fmap f x
  Op op k <*> x = Op op (\a -> k a <*> x)

instance Monad IaC where
  (>>=) = bindIaC

bindIaC :: IaC a -> (a -> IaC b) -> IaC b
bindIaC (Pure a) f = f a
bindIaC (Op op k) f = Op op (\a -> bindIaC (k a) f)

mkResource :: ResourceType -> ResourceConfig a -> IaC (Resource a)
mkResource rt rc = Op (MkResourceOp rt rc) Pure

readState :: IaC State
readState = Op ReadStateOp Pure

writeState :: State -> IaC ()
writeState s = Op (WriteStateOp s) Pure

deleteResource :: ResourceId -> IaC ()
deleteResource rid = Op (DeleteResourceOp rid) Pure

logMsg :: LogLevel -> String -> IaC ()
logMsg level msg = Op (LogOp level msg) Pure