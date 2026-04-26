# Haskform - Haskell Infrastructure as Code

A framework written in Haskell to enable people to have infrastructure as code writing Haskell. The idea is that we can leverage Haskell's pure functional soul to provide an amazing experience for the users.

## Getting Started

```bash
# Install dependencies
scoop install haskell stack

# Build
stack build

# Test
stack test
```

## Architecture

Inspired by Terraform and Pulumi:
- **Core Engine**: Stateful resource graph execution
- **Providers**: Plugin-based system for cloud/API integration
- **State Management**: Declarative plan/apply workflow

## Reference Documentation
- Terraform internals: https://developer.hashicorp.com/terraform/internals
- Pulumi concepts: https://www.pulumi.com/docs/concepts/how-pulumi-works/

## Development

```bash
# Watch mode
stack build --file-watch

# Run ci locally
stack build && stack test
```

## License

BSD 3-Clause