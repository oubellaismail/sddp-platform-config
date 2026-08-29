# Onboarding — the platform trust step

When a new paved-road service is onboarded into an **existing** project, the only
platform-config change is **trusting its signer**: add the service repo's keyless
release identity to POL-01's allowlist. Everything else (delivery manifests,
network policy, ingress) lives in that project's config repo (e.g.
`sddp-app-config/onboarding/`), and the project's namespace already exists — no
new AppProject/Application is needed for a service that joins a namespace that is
already standing.

> **Standing up a NEW project** (its own namespace + AppProject + config repo)?
> That's a different, project-level step — see `../bootstrap/`. Come back here to
> trust each of the new project's services once the project scaffolding exists.

## The step

1. Copy `pol-01-signer-entry.snippet.yaml`, fill in `<owner>` and the service's
   `<project>-<svc>` repo name.
2. Append it to `attestors[0].entries` in
   `manifests/kyverno-policies/pol-01-verify-signature.yaml`.
3. Open a PR, review, merge. Confirm POL-01 is enforcing.

Do this **before** merging the service's first config-bump PR — otherwise
admission is fail-closed and rejects the new signer's digest.

## Why it's manual

This is the trust boundary: adding a signer means "images signed by this identity
may run in the cluster." That decision is reviewed by a human and recorded
explicitly in the allowlist — never a wildcard, never scripted.
