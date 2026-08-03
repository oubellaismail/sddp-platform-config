# sddp-platform-config

Declarative configuration for the platform's own components: Kyverno policies, Falco rules, Cilium network policy, Vault policy, and ArgoCD's own configuration.

Watched by ArgoCD via the "app of apps" pattern — the root `Application` points here, and this repo defines the `Application` resources for every platform component. Occasional change frequency, high review weight: these files *are* the platform's defense-in-depth.

## Imperative prerequisite — Kyverno's registry read credential

The image-signature policy (`manifests/kyverno-policies/pol-01-verify-signature.yaml`) makes Kyverno fetch signatures from the **private** production registry **at admission time**, from its own controller pod. This is a different access path than the kubelet's image pull, so the cluster↔registry integration secret does **not** cover it — without its own credential Kyverno gets `401 Unauthorized` and (fail-closed) blocks every matching Pod.

Provide it as a docker-registry secret named `docr-read` in the `kyverno` namespace, holding a registry **read** token (the DigitalOcean API token doubles as both username and password):

```
kubectl -n kyverno create secret docker-registry docr-read \
  --docker-server=registry.digitalocean.com \
  --docker-username="$DIGITALOCEAN_TOKEN" \
  --docker-password="$DIGITALOCEAN_TOKEN"
```

This secret holds a credential, so it is **not** committed to git — it is created imperatively and must be **re-created after any cluster recreate** (like the registry attach on the infrastructure side). A future External Secrets + Vault integration will adopt it.
