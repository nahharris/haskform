---
id: arch-001
title: Free Monad DSL Architecture
status: open
priority: high
type: architecture
---

# Free Monad DSL Architecture

## Decision

Use **Free Monad DSL** for the infrastructure definition layer.

## Rationale

- Maximum type safety via typed AST
- Testable without real infrastructure
- Multiple interpreters (plan, apply, mock, etc.)
- Composable and extensible
- Aligns with "everything is a library" philosophy

## Design Overview

### Three-Layer Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    User Infrastructure                   │
│   (Pure Haskell code building Free IaC AST)             │
└─────────────────────┬───────────────────────────────────┘
                      │ runs
                      ▼
┌─────────────────────────────────────────────────────────┐
│                    IaC Interpreter                       │
│   - Plan interpreter (computes diff)                   │
│   - Apply interpreter (executes changes)               │
│   - Mock interpreter (for testing)                     │
└─────────────────────┬───────────────────────────────────┘
                      │ calls
                      ▼
┌─────────────────────────────────────────────────────────┐
│                    Providers                             │
│   (In-process Haskell libraries)                        │
│   - AWS Provider                                        │
│   - Generic HTTP Provider                              │
└─────────────────────────────────────────────────────────┘
```

### Plan/Apply Workflow

1. **Refresh**: Load existing state from provider (or empty if none)
2. **Plan**: Run user's Free IaC program, compute diff, show plan
3. **Apply**: Execute the plan, modifying infrastructure to match desired state
4. **Output**: New state is serialized (YAML)

## Module Structure

```
haskform/
├── src/
│   └── Haskform/
│       ├── DSL/                    -- The Free Monad DSL
│       │   ├── Core.hs             -- IaCF functor, Free monad
│       │   ├── SmartConstructors.hs -- User-facing API
│       │   └── Interpreters/       -- Plan, Apply, Mock
│       ├── Core/                   -- Core engine
│       │   ├── State.hs           -- State types
│       │   ├── Plan.hs            -- Plan types & computation
│       │   └── ResourceGraph.hs   -- Resource graph
│       ├── Provider/              -- Provider interface
│       │   ├── Types.hs           -- Provider types
│       │   ├── Protocol.hs        -- Provider class
│       │   └── StateStore/        -- YAML state persistence
│       └── Provider/              -- Built-in providers
│           └── Aws/
│               ├── Provider.hs    -- AWS provider
│               └── Resources/     -- AWS resource types
```

## Key Types

### DSL Layer

```haskell
-- Functor for DSL operations
data IaCF r where
  MkResource    :: ResourceType a -> ResourceConfig a -> IaCF (Resource a)
  ReadState     :: IaCF State
  WriteState    :: State -> IaCF ()
  DeleteResource:: ResourceId -> IaCF ()
  Log           :: LogLevel -> String -> IaCF ()

-- Free monad
type IaC = Free IaCF
```

### State Layer

```haskell
-- Managed state with versioning
data State = State
  { stateResources   :: Map ResourceId (Resource ())
  , stateVersion     :: Word
  , stateChecksum    :: Text
  } deriving (Generic)

-- Plan output
data Plan = Plan
  { planCreates :: [ResourcePlan]
  , planUpdates :: [ResourcePlan]
  , planDeletes :: [ResourcePlan]
  , planNoChange :: [ResourcePlan]
  } deriving (Generic)

data ResourcePlan = ResourcePlan
  { rpId      :: ResourceId
  , rpType    :: ResourceType
  , rpAction  :: PlanAction
  , rpBefore  :: Maybe (Resource ())
  , rpAfter   :: Maybe (Resource ())
  }
```

### Provider Layer

```haskell
-- Provider interface (class, not separate process)
class Monad m => MonadProvider p m where
  readResource    :: p -> ResourceId -> m (Maybe (Resource ()))
  createResource  :: p -> ResourceType a -> ResourceConfig a -> m (Resource a)
  updateResource  :: p -> ResourceId -> ResourceType a -> ResourceConfig a -> m (Resource a)
  deleteResource  :: p -> ResourceId -> m ()

-- YAML state store (configurable as a "provider")
data YamlStateStore = YamlStateStore
  { stateFilePath :: FilePath
  }
```

## References

- [DSL Free Monad Research](../research/dsl-free-monad.md)
- [Market Research](../research/market-research.md)