# sddp-platform-config

Declarative configuration for the platform's own components: Kyverno policies, Falco rules, Cilium network policy, Vault policy, and ArgoCD's own configuration.

Watched by ArgoCD via the "app of apps" pattern (cluster-architecture-spec.md §1a) — the root `Application` points here, and this repo defines the `Application` resources for every platform component. Occasional change frequency, high review weight: these files *are* the platform's defense-in-depth (Tier 1, cluster-architecture-spec.md §6.3).

Design docs: see the `pfa` repo (particularly `kyverno-policy-spec.md`, `falco-detection-spec.md`).
