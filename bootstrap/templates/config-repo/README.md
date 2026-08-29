# __PROJECT__-config

GitOps config repo for the **__PROJECT__** project — the single source of truth
for everything ArgoCD delivers into the `__PROJECT__` namespace (ADR-005/009: one
config repo per project, unified across that project's services).

Scaffolded by `sddp-platform-config/bootstrap/new-project.sh`.

## Layout

```
manifests/                 # ArgoCD syncs this dir (recurse: true)
  networkpolicy.yaml       # default-deny-all floor (POL-05 anchor), sync-wave -1
  dns-egress.cnp.yaml      # namespace-wide DNS egress (L7), sync-wave -1
  <svc>/                   # one dir per onboarded service (deployment/service/cnp[/ingress])
onboarding/                # tooling — NOT synced by ArgoCD (outside manifests/)
  onboard.sh               # stamp a new service's manifests from the templates
  service-template/        # the parameterized per-service manifests
```

## How this project was stood up

1. `sddp-platform-config` got an `apps/__PROJECT__.yaml` (AppProject + Application)
   scoping ArgoCD to pull ONLY from this repo and deploy ONLY into `__PROJECT__`.
2. This repo was created with the default-deny floor + DNS egress above.
3. Each service is onboarded via `onboarding/onboard.sh` (see `onboarding/README.md`),
   with its signer trusted in POL-01 first.

## Guardrails that apply here

- **POL-01** — every image must be a signed digest from a trusted first-party signer.
- **POL-02** — no privileged / root containers.
- **POL-03** — resource limits required.
- **POL-04** — images only from DOCR (`registry.digitalocean.com/sddp-registry/...`).
- **POL-05** — a NetworkPolicy must exist in the namespace (the floor above).

`__PROJECT__` is a fully enforced namespace — **no policy exceptions**.
