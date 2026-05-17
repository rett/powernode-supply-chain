# Contributing to the Powernode Supply Chain Extension

Thanks for your interest in improving this extension. This guide covers the development workflow, including the submodule layout that exists because this extension is consumed by the parent [Powernode platform](https://github.com/nodealchemy/powernode-platform).

## Submodule context

This repo is mounted into `powernode-platform` at `extensions/supply-chain/`. Most real-world testing requires the parent platform running so the Rails autoloader sees the extension's namespaces (`SupplyChain::*`, `Api::V1::SupplyChain::*`).

```
powernode-platform/                  ← parent (separate repo)
├── server/                          ← parent's Rails app
├── frontend/                        ← parent's React app
├── extensions/
│   └── supply-chain/                ← THIS repo (submodule)
│       ├── server/                  ← extension's Rails models / services
│       ├── frontend/                ← extension's React components
│       ├── worker/                  ← extension's Sidekiq jobs
│       └── docs/                    ← extension documentation
```

## Setting up locally

```bash
# Clone the parent platform with submodules
git clone --recurse-submodules https://github.com/nodealchemy/powernode-platform.git
cd powernode-platform

# Or if already cloned without submodules:
git submodule update --init --recursive
```

## Running tests

```bash
# Backend rspec (run from the parent's server/ so the autoloader sees both)
cd /path/to/powernode-platform/server
bundle exec rspec ../extensions/supply-chain/server/spec/

# Frontend type-check
cd ../extensions/supply-chain/frontend
npx tsc --noEmit
```

## Committing

Always commit inside `extensions/supply-chain/` first, then update the parent's submodule pointer:

```bash
cd extensions/supply-chain
git checkout -b my-feature
# ... make changes ...
git add server/...
git commit -m "feat: add foo"
git push origin my-feature

# Then update the parent's submodule pointer:
cd ../..
git add extensions/supply-chain
git commit -m "chore(submodule): bump extensions/supply-chain → my-feature"
```

Conventional commit format (per the parent platform):
- `type(scope): description` — types: `feat`, `fix`, `refactor`, `test`, `chore`, `docs`
- Lowercase, no period

## Submitting a PR

Open the PR against this repo's `develop` branch. Once merged + tagged, the parent platform's submodule pointer is bumped in a follow-up PR there.

Supply-chain changes that touch SBOM generation, attestation signing, or vulnerability ingestion paths get extra scrutiny — they sit on the trust boundary between upstream artifact sources and the platform's policy decisions. Include test coverage that exercises both happy + adversarial inputs.

## Reporting issues

For bugs in the extension itself: open issues here on GitHub. For bugs in the parent platform's integration with this extension: open in [powernode-platform](https://github.com/nodealchemy/powernode-platform).

For **security vulnerabilities**, use the private channel in [SECURITY.md](./SECURITY.md), not public issues — supply-chain security holes have a higher-than-average risk of upstream/downstream cascading.

## License

By contributing, you agree your contributions are licensed under MIT (see [LICENSE](./LICENSE)).
