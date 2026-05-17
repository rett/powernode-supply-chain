# Security Policy

We take security seriously. This document covers how to report vulnerabilities in the Powernode supply chain extension and what to expect from us in response.

Supply-chain security holes are especially sensitive — a vulnerability that lets an attacker forge an SBOM, suppress a CVE match, or counterfeit an attestation can cascade across every downstream consumer of the platform's trust signals. We treat this surface accordingly.

## Reporting a vulnerability

**Do not report security vulnerabilities through public GitHub issues, X, or any other public channel.** Public reports give attackers a window between disclosure and patch availability that we can't shorten.

Email **security@nodealchemy.com** with:

- Description of the vulnerability + components affected
- Steps to reproduce (proof-of-concept welcome but not required)
- Impact assessment (data exposure, integrity bypass, trust-boundary violation, denial of service, etc.)
- Your name + affiliation if you'd like attribution after the fix ships

You can expect:

- **Acknowledgment within 48 hours** of receipt
- A coordinated-disclosure timeline proposal within **5 business days**
- Weekly status updates during active investigation

## Coordinated disclosure

1. You report privately to security@nodealchemy.com
2. We investigate, develop + verify a fix, and assign a CVE if warranted
3. We release the fix + publish a security advisory on the repo
4. You may publish your write-up after the advisory ships

We aim for a 90-day disclosure window from initial report but can negotiate based on complexity. We won't pursue legal action against good-faith security research that follows this policy.

## Scope

**In scope:**

- Server-side Rails (`server/` — SBOM models, vulnerability scan results, attestation records, vendor risk scoring)
- React frontend (`frontend/` — supply chain operator UI)
- Sidekiq worker jobs (`worker/` — scheduled scans, ingest, attestation generation)
- **SBOM integrity** — any path that could let a forged or modified SBOM be accepted as authoritative
- **Vulnerability scanning** — bypass paths, scanner-evasion vectors, CVE-suppression flaws
- **Container image verification** — signature-validation bypasses, trust-store tampering
- **Attestation signing + verification** — cryptographic provenance flaws (SLSA, in-toto)
- **Vendor risk scoring** — input validation, score-manipulation paths
- **License compliance** — license-misidentification or compliance-bypass paths

**Out of scope:**

- Vulnerabilities in third-party SBOM/scanner tools — please report to the upstream project first; we'll address our integration exposure after the upstream fix is available
- Issues requiring physical access to a deployed server
- Theoretical attacks without practical exploitability
- Findings from automated scanners without manual verification
- Misconfigurations of operator-controlled policy or risk-score settings

## Supported versions

| Version | Supported |
|---|---|
| `develop` branch | Active development; security fixes land here first |
| Most recent tagged release | Critical + high-severity fixes backported |
| Older tags | Please upgrade to the latest tag |

## Acknowledgments

Security researchers who responsibly disclose vulnerabilities through this process are credited in the resulting advisory unless they prefer anonymity. We don't currently run a paid bug bounty.

See also [CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md) — community conduct issues go through a separate channel (conduct@nodealchemy.com), not the security inbox.
