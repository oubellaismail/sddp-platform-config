# Onboarding — the platform trust step

When a new paved-road service is onboarded, the only platform-config change is
**trusting its signer**: add the service repo's keyless release identity to
POL-01's allowlist. Everything else (delivery manifests, network policy, ingress)
lives in the project config repo (`sddp-app-config/onboarding/`), and the cluster
namespace already exists — no new AppProject/Application is needed for a service
that joins the existing `sddp-app` namespace.

## The step

1. Copy `pol-01-signer-entry.snippet.yaml`, fill in `<owner>` / `<svc>`.
2. Append it to `attestors[0].entries` in
   `manifests/kyverno-policies/pol-01-verify-signature.yaml`.
3. Open a PR, review, merge. Confirm POL-01 is enforcing.

Do this **before** merging the service's first config-bump PR — otherwise
admission is fail-closed and rejects the new signer's digest.

## Why it's manual

This is the trust boundary: adding a signer means "images signed by this identity
may run in the cluster." That decision is reviewed by a human and recorded
explicitly in the allowlist — never a wildcard, never scripted.
