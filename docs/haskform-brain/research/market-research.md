# Market Research: Infrastructure as Code Tools

## Terraform (HashiCorp)

**Architecture:**
- Plugin-based system with providers as separate processes
- gRPC communication between core and providers
- Declarative HCL configuration language
- State management (local or remote backends)

**Key Concepts:**
- Providers define resources (AWS, Azure, GCP, etc.)
- State tracks current infrastructure
- Plan/apply workflow for change management
- Schema-based resource definitions

**Provider Schema:**
- GetProviderSchema returns complete provider schema
- PlanResourceChange computes planned changes
- ApplyResourceChange executes changes

**Reference:** https://developer.hashicorp.com/terraform/internals

---

## Pulumi

**Architecture:**
- Uses general-purpose programming languages (TypeScript, Python, Go, C#, Java)
- Language host executes user programs
- Deployment engine orchestrates state
- Providers handle API interactions

**Key Concepts:**
- Imperative code, declarative outcome
- Resource registration model
- Component resources for encapsulation
- State backend (file, S3, etc.)

**Three-Part Model:**
1. Language host (imperative - user code)
2. Deployment engine (declarative - state reconciliation)
3. Providers (imperative - API calls)

**Reference:** https://www.pulumi.com/docs/concepts/how-pulumi-works/

---

## Ansible

**Architecture:**
- Push-based (no state file)
- YAML playbooks
- Modules executed over SSH
- Inventory-based target management

**Key Concepts:**
- Inventory defines targets
- Playbooks orchestrate tasks
- Modules are idempotent units
- Roles organize reusable playbooks

**Reference:** https://docs.ansible.com/projects/ansible/latest/dev_guide/overview_architecture.html

---

## Key Takeaways for Haskform

1. **Provider Model**: Follow Terraform's plugin architecture with gRPC
2. **Language Integration**: Like Pulumi, leverage Haskell's type system
3. **State Management**: Declarative plan/apply like Terraform
4. **Pure Functions**: Use Haskell's purity for predictable state transformations

**Inspiration Sources:**
- Terraform provider protocol (gRPC)
- Pulumi's resource registration model
- OpenTofo's open-source approach