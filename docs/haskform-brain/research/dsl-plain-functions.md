# DSL Option 2: Plain Functions + Records

## Concept

Use **plain Haskell functions**, **records with lenses**, and **smart constructors**. No special DSL machinery - just idiomatic Haskell. The "DSL" is just a set of functions and data types.

## How It Works

```haskell
-- 1. Define resource types as records
data VPC = VPC
  { vpcId        :: VPCId
  , vpcCidr      :: CIDR
  , vpcName      :: Text
  } deriving (Generic, Show)

data EC2Instance = EC2Instance
  { ec2Id           :: InstanceId
  , ec2InstanceType :: InstanceType
  , ec2VpcId        :: VPCId
  , ec2Ami          :: AMI
  } deriving (Generic, Show)

-- 2. Define resource configurations
data VPCConfig = VPCConfig
  { vpcConfigCidr :: CIDR
  , vpcConfigName :: Text
  } deriving (Generic)

data EC2Config = EC2Config
  { ec2ConfigType :: InstanceType
  , ec2ConfigVpc  :: VPCId
  , ec2ConfigAmi  :: AMI
  } deriving (Generic)

-- 3. Define provider interface
class IaCProvider p where
  type ProviderState p :: *

  createResource :: p -> ResourceConfig a -> IO (Resource a)
  readResource   :: p -> ResourceId -> IO (Maybe (Resource ()))
  updateResource :: p -> ResourceId -> ResourceConfig a -> IO (Resource a)
  deleteResource :: p -> ResourceId -> IO ()

  readState      :: p -> IO (ProviderState p)
  writeState     :: p -> ProviderState p -> IO ()

-- 4. Smart constructors (main user API)
createVPC :: IaC m => VPCConfig -> m (Resource VPC)
createVPC config = do
  provider <- askProvider
  liftIaC $ createResource provider (SomeConfig (VPCConfigC config))

createEC2 :: IaC m => EC2Config -> m (Resource EC2Instance)
createEC2 config = do
  provider <- askProvider
  liftIaC $ createResource provider (SomeConfig (EC2ConfigC config))
```

## User Experience

```haskell
-- User writes normal Haskell:
myInfra :: (HasProvider m, MonadIO m) => m [SomeResource]
myInfra = do
  vpc <- createVPC VPCConfig
    { vpcConfigCidr = CIDR "10.0.0.0/16"
    , vpcConfigName = "my-vpc"
    }

  instance <- createEC2 EC2Config
    { ec2ConfigType = T3.micro
    , ec2ConfigVpc  = resourceId vpc
    , ec2ConfigAmi  = AMI "ami-12345"
    }

  pure [SomeResource vpc, SomeResource instance]

-- Run with a provider:
main :: IO ()
main = do
  provider <- newAWSProvider AWSConfig
    { awsRegion = us-east-1
    , awsCreds  = fromEnv
    }
  result <- runIaC provider myInfra
  case result of
    Left err -> putStrLn $ "Error: " <> show err
    Right resources -> print resources
```

## State Management

```haskell
-- State is just a record
data State = State
  { stateResources :: HashMap ResourceId SomeResource
  , stateVersion    :: Word
  } deriving (Generic, ToJSON, FromJSON)

-- Save/load from YAML
loadState :: FilePath -> IO (Maybe State)
loadState path = decodeFileEither path >>= \case
  Right s -> pure (Just s)
  Left{}  -> pure Nothing

saveState :: FilePath -> State -> IO ()
saveState path = encodeFile path

-- Plan computation (pure function)
computePlan :: DesiredState -> CurrentState -> Plan
computePlan desired current =
  let toCreate = desired `Set.difference` current
      toUpdate = changed desired current
      toDelete = current `Set.difference` desired
  in Plan toCreate toUpdate toDelete
```

## Pros

- **Familiar Haskell**: No new concepts to learn
- **Fast iteration**: No AST to build, runs immediately
- **Easy debugging**: Standard Haskell debugger works
- **Good error messages**: Type errors are clear
- **Less boilerplate**: No functor/monad instances to write
- **IDE support**: Works with Haskell IDE tools out of the box

## Cons

- **Less type-level guarantees**: No AST ensures operations make sense
- **Impure by default**: Side effects happen as you call functions
- **Harder to test**: Need to mock providers for tests
- **Less composable**: Adding new operations requires modifying existing code
- **No AST inspection**: Can't analyze the infrastructure plan before running

## Real-World Examples

- **Terraform CDK**: TypeScript/Python approach (similar philosophy)
- **Pulumi**: Uses plain language, not a custom DSL
- **Go AWS SDK**: Plain functions and structs

## Best For

- When developer ergonomics is more important than maximum type safety
- When you want fast adoption (familiar patterns)
- When you don't need multiple interpreters
- When debugging experience matters most