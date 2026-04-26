# DSL Option 1: Free Monad DSL

## Concept

Define infrastructure operations as a **typed AST (Abstract Syntax Tree)**. Users write pure code that builds this AST, which is then interpreted by separate interpreters. This separates the "what" from the "how".

## How It Works

```haskell
-- 1. Define DSL operations as a GADT (functor)
data IaCF r where
  MkResource    :: ResourceType a -> ResourceConfig a -> IaCF (Resource a)
  ReadState     :: IaCF State
  WriteState    :: State -> IaCF ()
  DeleteResource:: ResourceId -> IaCF ()
  Log           :: LogLevel -> String -> IaCF ()

-- 2. Make it a functor (required for free monad)
instance Functor IaCF where
  fmap f (MkResource rt rc) = MkResource rt rc
  fmap _ (ReadState)        = ReadState
  fmap _ (WriteState s)    = WriteState s
  fmap _ (DeleteResource i)= DeleteResource i
  fmap _ (Log l msg)        = Log l msg

-- 3. Free monad (wraps the functor)
data Free f a
  = Pure a                -- Terminal value
  | Free (f (Free f a))   -- Effect to execute

instance Functor f => Monad (Free f) where
  return = Pure
  (>>=) = bindFree

bindFree :: Functor f => Free f a -> (a -> Free f b) -> Free f b
bindFree (Pure a) f = f a
bindFree (Free fa) f = Free (fmap (>>= f) fa)

-- 4. Lift effects into the free monad
liftF :: f a -> Free f a
liftF fa = Free (fmap Pure fa)

-- Smart constructors (user-facing API)
mkResource :: ResourceType a -> ResourceConfig a -> Free IaCF (Resource a)
mkResource rt rc = liftF (MkResource rt rc)

readState :: Free IaCF State
readState = liftF ReadState

writeState :: State -> Free IaCF ()
writeState s = liftF (WriteState s)
```

## User Experience

```haskell
-- User writes pure code that builds an AST:
myInfra :: Free IaCF (Resource EC2.Instance)
myInfra = do
  vpcId <- mkResource (resourceType @VPC) ("my-vpc", CIDR "10.0.0.0/16")
  mkResource (resourceType @EC2.Instance) (EC2Config
    { instanceType = T3.micro
    , vpcId = vpcId
    , ami = "ami-12345"
    })
-- This produces an AST, nothing executes yet!

-- To actually run:
result :: IO (Either IaCError (Resource EC2.Instance))
result = runIaC myInfra
```

## Interpreter (How the AST is executed)

```haskell
-- Natural transformation: IaCF ~> IO
runIaC :: Free IaCF a -> IO (Either IaCError a)
runIaC = iterM runIaCF

runIaCF :: IaCF (IO (Either IaCError a)) -> IO (Either IaCError a)
runIaCF = \case
  MkResource rt rc -> do
    state <- readStateFile
    case computePlan rt rc state of
      Left err -> pure (Left err)
      Right (resource, newState) -> do
        writeStateFile newState
        pure (Right resource)
  ReadState -> Right <$> readStateFile
  WriteState s -> Right <$> writeStateFile s
  Log _ msg -> putStrLn msg >> pure (Right ())
  DeleteResource rid -> do
    state <- readStateFile
    writeStateFile (removeResource rid state)
    pure (Right ())
```

## Pros

- **Maximum type safety**: The AST is typed, errors caught at compile time
- **Testable**: Write alternative interpreters (mock, test, etc.)
- **Composable**: Combine DSLs, add new operations without modifying existing code
- **Pure**: User code is pure, no side effects until interpretation
- **Extensible**: Add new operations by adding new constructors

## Cons

- **Steeper learning curve**: Requires understanding functors, monads, free monads
- **More code to write**: Boilerplate for the GADT, functor instance, interpreters
- **Debugging**: AST can be hard to inspect
- **Error messages**: Can be cryptic, especially with complex types

## Real-World Examples

- **Clay** (CSS library): Uses free monads for typed CSS
- **Cloudflare/cf-security-ingress**: Pure DSL for Cloudflare rules
- **Hakyll**: Blog engine with declarative site structure
- **IHP**: Haskell web framework with type-safe queries

## Best For

- When type safety is paramount
- When you need to test infrastructure code without real infrastructure
- When you want to support multiple backends (interpreters)
- When composability matters