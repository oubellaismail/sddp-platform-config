# Project bootstrap — stand up a NEW project on the paved road

Onboarding has two levels:

- **Service onboarding** — add a service to an *existing* project. The project's
  namespace, AppProject, and config repo already exist, so the only platform
  change is trusting the new signer (POL-01), then the config repo's `onboard.sh`
  stamps the delivery manifests. See `../onboarding/`.
- **Project onboarding** (this directory) — stand up a *new* project: its own
  enforced namespace, its own ArgoCD scope (AppProject + Application), its own
  default-deny floor, and its own config repo. Only then do its services onboard
  via the service road above.

`new-project.sh` is the project-level twin of a config repo's `onboard.sh`.

## Naming

Everything follows `<project>-<service>`. `<project>` is the namespace and the
config-repo prefix (`demo` -> namespace `demo`, repo `demo-config`); its services
are `demo-app`, `demo-web`, … with images `sddp-registry/demo-app` etc. Do not
reuse `sddp` (that's an existing project) — the script refuses it.

## Run

```bash
bootstrap/new-project.sh demo --owner <github-owner> --out /tmp/demo-config
```

That produces:

1. **`apps/demo.yaml`** here (platform side) — the AppProject + Application that
   scope ArgoCD to pull ONLY from `demo-config` and deploy ONLY into namespace
   `demo` (`CreateNamespace=true`).
2. **`/tmp/demo-config/`** (config side) — the new config-repo skeleton:
   - `manifests/networkpolicy.yaml` — default-deny-all floor (POL-05 anchor).
   - `manifests/dns-egress.cnp.yaml` — namespace-wide DNS egress (L7 visibility).
   - `onboarding/` — the per-service onboarder + templates, project slug baked in.

## What stays MANUAL (by design — the controls depend on it)

- Creating the GitHub `demo-config` repo + its ArgoCD read deploy key.
- Each service's POL-01 signer entry (a reviewed trust act, never scripted).
- Every PR merge (the deploy gate).

## Per-service wiring for a new project

Services are created from `sddp-service-template` as usual, with one extra step:
point each service's release pipeline at this project's config repo by setting a
repository variable (it defaults to `sddp-app-config` for the original project):

```bash
gh variable set CONFIG_REPO --repo <owner>/demo-app --body <owner>/demo-config
```

Onboard each service by its **full repo name** (`demo-app`, `demo-web`), which is
what the pipeline promotes as the image and derives the config path from:

```bash
# in demo-config
./onboarding/onboard.sh demo-app --digest sha256:<64hex> --host app.<domain>
```

## Templates

| File | Becomes |
|------|---------|
| `templates/app-of-apps-application.yaml` | `apps/<project>.yaml` (AppProject + Application) |
| `templates/config-repo/` | the `<project>-config` repo skeleton |

Placeholders: `__PROJECT__`, `__OWNER__` are filled by `new-project.sh`;
`__SVC__` / `__PORT__` / `__HOST__` / `__DIGEST__` are left for the per-service
`onboard.sh` inside the generated repo.
