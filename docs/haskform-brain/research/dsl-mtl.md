# DSL Option 3: MTL-style Monad Transformers

## Concept

Use Haskell's **mtl pattern** - typeclasses representing effects, with instances for different monad stacks. Similar to how `MonadReader`, `MonadState`, `MonadIO` work in standard Haskell.

## How It Works

```haskell
-- 1. Define effect typeclasses (what operations the DSL supports)
class Monad m => MonadIaC m where
  createResource  :: ResourceType a -> ResourceConfig a -> m (Resource a)
  readResource     :: ResourceId -> m (Maybe (Resource ()))
  deleteResource   :: ResourceId -> m ()
  getState         :: m State
  putState         :: State -> m ()

class Monad m => MonadLog m where
  logInfo  :: String -> m ()
  logWarn  :: String -> m ()
  logError :: String -> m ()

-- 2. Create a monad transformer (stack)
newtype IaCT m a = IaCT
  { unIaCT :: ReaderT IaCEnv (StateT IaCState m) a
  } deriving (Functor, Applicative, Monad)

instance MonadTrans IaCT where
  lift = IaCT . lift . lift

-- 3. Instances for the IaC monad
instance Monad m => MonadIaC (IaCT m) where
  createResource rt rc = IaCT $ do
    env <- ask
    st <- get
    case runProviderAction (provider env) (Create rt rc) of
      Left err -> lift (throwError err)
      Right (res, newSt) -> do
        put newSt
        pure res

  getState = IaCT $ gets stateResources
  putState s = IaCT $ modify (\st -> st { stateResources = s })

instance Monad m => MonadLog (IaCT m) where
  logInfo msg = IaCT $ lift (lift (lift (putStrLn msg)))
  logWarn = logInfo . ("WARN: " <>)
  logError = logInfo . ("ERROR: " <>)

-- 4. Smart constructors (convenience)
createVPC :: MonadIaC m => VPCConfig -> m (Resource VPC)
createVPC config = createResource (resourceType @VPC) (VPCConfigC config)

createEC2 :: MonadIaC m => EC2Config -> m (Resource EC2Instance)
createEC2 config = createResource (resourceType @EC2) (EC2ConfigC config)
```

## User Experience

```haskell
-- User writes Haskell with constraints:
myInfra :: (MonadIaC m, MonadLog m) => m (Resource EC2Instance)
myInfra = do
  logInfo "Creating VPC..."
  vpc <- createVPC VPCConfig
    { vpcConfigCidr = CIDR "10.0.0.0/16"
    , vpcConfigName = "my-vpc"
    }

  logInfo "Creating EC2 instance..."
  instance <- createEC2 EC2Config
    { ec2ConfigType = T3.micro
    , ec2ConfigVpc  = resourceId vpc
    , ec2ConfigAmi  = AMI "ami-12345"
    }

  pure instance

-- Run it:
runIaC :: IaCConfig -> IaCT IO a -> IO a
runIaC config prog =
  let env = IaCEnv (awsProvider config)
      st  = IaCState emptyState
  in evalStateT (runReaderT (unIaCT prog) env) st
```

## Combining Effects

```haskell
-- Extend with more effects as needed
class Monad m => MonadHTTP m where
  httpGet  :: URL -> m ByteString
  httpPost :: URL -> ByteString -> m ByteString

class Monad m => MonadCache m where
  getCached :: Key -> m (Maybe Value)
  setCached :: Key -> Value -> m ()

-- User code can use any combination:
fullInfra :: (MonadIaC m, MonadHTTP m, MonadCache m) => m (Resource SomeResource)
fullInfra = do
  cached <- getCached "remote-config"
  case cached of
    Just cfg -> createFromConfig cfg
    Nothing -> do
      cfg <- httpGet "https://api.example.com/config"
      setCached "remote-config" cfg
      createFromConfig cfg
```

## Running Different Interpreters

```haskell
-- Production: real AWS
instance MonadIaC AWSM where
  createResource = realAWSCreate

-- Test: mock provider
instance MonadIaC MockM where
  createResource _ _ = pure (mockResource "test-id")

-- Repl: interactive
instance MonadIaC ReplM where
  createResource rt cfg = do
    liftIO (putStrLn ("Create " <> show rt <> "? [y/N]"))
    answer <- getLine
    if answer == "y"
      then pure (mockResource "repl-id")
      else throwError UserDeclined
```

## Pros

- **Standard Haskell**: Uses established mtl patterns
- **Extensible effects**: Add new effects by adding new typeclasses
- **Multiple interpreters**: Easy to run with different backends
- **Good error messages**: Typeclass constraints are readable
- **IDE support**: Works with standard tools
- **Composable**: Stack effects as needed

## Cons

- **Impure by default**: Side effects happen as called (no AST)
- **Less testable than free monads**: Mocks work but setup is involved
- **Tight coupling**: User code constrained to specific typeclasses
- **No AST for analysis**: Can't inspect plan before running
- **Stack complexity**: Deep transformer stacks can get unwieldy

## Real-World Examples

- **Servant**: Uses mtl-style for HTTP server handlers
- **Yesod**: Uses mtl for request handling
- **Persistent**: Database library with MonadIO-style classes
- **Polysemy**: Extends this pattern with better ergonomics

## Best For

- When you want a balance of type safety and ergonomics
- When you need multiple backends (test, dev, prod)
- When team is familiar with mtl patterns
- When effects need to be extensible
- When you want IDE support without custom tooling