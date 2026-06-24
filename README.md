# Powernode Supply Chain Extension

Software supply chain security for Powernode: SBOM management, vulnerability scanning, container security, attestations, vendor risk, and license compliance — wired into the [Powernode platform](https://github.com/nodealchemy/powernode-platform) via the extension contract.

This repository is mounted into the platform as a submodule at `extensions/supply-chain/`. It can be developed independently — the platform consumes it via the standard extension contract.

---

## What this extension provides

- **SBOM management** — generate, store, and query software bill of materials for every module + container in the fleet
- **Vulnerability scanning** — identify CVEs across dependencies + container images, with severity scoring + exploitability context
- **Container security** — image signature verification, runtime policy enforcement, attestation cross-checks at attach time
- **Attestations** — cryptographic provenance records (SLSA, in-toto) generated at build + verified at install
- **Vendor risk** — third-party supplier risk scoring with configurable inputs
- **License compliance** — track + flag license obligations across dependencies; surface conflicts before they ship

---

## Requirements

A running Powernode platform installation. See the [parent platform repo](https://github.com/nodealchemy/powernode-platform) for installation instructions.

---

## Layout

```
extensions/supply-chain/
├── server/                 # Rails models, services, controllers, specs
├── frontend/               # React TypeScript surface
├── worker/                 # Sidekiq job classes
└── docs/                   # Extension documentation
```

---

## License

MIT — see [LICENSE](./LICENSE). Code of Conduct: see [CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md).

---

## Community

- **GitHub Discussions** — [nodealchemy/powernode-platform/discussions](https://github.com/nodealchemy/powernode-platform/discussions) for questions, support, ideas, and commercial/enterprise inquiries
- **GitHub Issues** — [nodealchemy/powernode-supply-chain/issues](https://github.com/nodealchemy/powernode-supply-chain/issues) for bugs + feature requests
- **Security vulnerabilities** — [report a private advisory](https://github.com/nodealchemy/powernode-platform/security/advisories/new); see [SECURITY.md](./SECURITY.md)
- **Code of Conduct** — see [CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md)
- **X (@nodealchemy)** — [@nodealchemy](https://x.com/nodealchemy) for updates and informal questions

---

## Related

- [Powernode platform](https://github.com/nodealchemy/powernode-platform) — the parent platform that mounts this extension
- [Powernode system extension](https://github.com/nodealchemy/powernode-system) — node lifecycle + module composition; consumes this extension's attestation + scan outputs at module-attach time
