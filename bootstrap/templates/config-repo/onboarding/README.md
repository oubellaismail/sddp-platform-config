# Onboarding — delivery-manifest templates (__PROJECT__)

Parameterized templates + a generator for wiring a new paved-road service into
the `__PROJECT__` namespace. These files are **tooling** — they live outside
`manifests/`, so ArgoCD (which recurses `manifests/`) never tries to apply them.

The project slug `__PROJECT__` is already baked into `service-template/` (the
namespace and the `sddp-registry/__PROJECT__-<svc>` image name), so onboarding a
service is identical to any other project: give it a name, a signed digest, and
optionally a host.

## Use

From the repo root, once the service's first release has signed + promoted an
image (grab the digest from its release run summary):

```bash
./onboarding/onboard.sh app --digest sha256:<64hex> --host app.<your-domain>
```

That stamps `manifests/app/{deployment,service,cnp,ingress}.yaml` from
`service-template/`, substituting the service name, port, host, and digest.
ArgoCD auto-discovers `manifests/app/` on merge.

## What the generator does NOT do (manual by design)

- **The POL-01 signer entry** — a reviewed trust decision, added by hand in
  `sddp-platform-config` (see its `onboarding/`). The signer subject is the
  service repo's own release identity, e.g.
  `https://github.com/<owner>/__PROJECT__-<svc>/.github/workflows/release.yml@refs/heads/main`.
- **The config-bump merge** — a human merges the PR; that is the deploy gate.

Both are deliberately human steps: automating them would defeat the controls.

## Templates

| File | Purpose | Params |
|------|---------|--------|
| `service-template/deployment.yaml` | non-root, small-tier Deployment on the signed digest | svc, port, digest |
| `service-template/service.yaml` | ClusterIP | svc, port |
| `service-template/cnp.yaml` | least-privilege network rules (ingress-reachable; egress example) | svc, port |
| `service-template/ingress.yaml` | TLS + rate-limited public route (only with `--host`) | svc, port, host |

The full step-by-step onboarding runbook lives in the platform docs.
