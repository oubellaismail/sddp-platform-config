#!/usr/bin/env bash
# Project-bootstrap generator — stand up a NEW project on the paved road.
#
# The project-level twin of a config repo's per-service onboard.sh. Given a
# project slug, it stamps the two pieces of scaffolding a new project needs that a
# new *service* reuses from an existing project:
#
#   1. PLATFORM side (this repo): apps/<project>.yaml — an AppProject + Application
#      scoping ArgoCD to pull ONLY from <project>-config and deploy ONLY into the
#      <project> namespace. The root app-of-apps discovers it on merge.
#   2. CONFIG side (a new repo): the <project>-config skeleton — the default-deny
#      NetworkPolicy floor + namespace-wide DNS egress + the parameterized service
#      onboarding tooling, with the project slug baked in.
#
# Run from anywhere:
#
#   bootstrap/new-project.sh <project> --owner <github-owner> --out <dir>
#
# <project>   project slug = the namespace + config-repo prefix, e.g. `demo`
#             (services then follow the <project>-<service> convention: demo-app).
# --owner     GitHub owner of the (to-be-created) <project>-config repo.
# --out       directory to write the <project>-config skeleton into (must not exist).
#
# What stays MANUAL by design (never scripted):
#   * creating the GitHub <project>-config repo + its ArgoCD deploy key,
#   * each service's POL-01 signer entry (a reviewed trust act),
#   * every PR merge (the deploy gate).
set -euo pipefail

PROJECT="${1:-}"; shift || true
OWNER=""; OUT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --owner) OWNER="${2:-}"; shift 2;;
    --out)   OUT="${2:-}"; shift 2;;
    *) echo "unknown arg: $1" >&2; exit 2;;
  esac
done

usage() { echo "usage: new-project.sh <project> --owner <github-owner> --out <dir>" >&2; exit 2; }
[ -n "$PROJECT" ] || usage
[ -n "$OWNER" ]   || { echo "error: --owner is required" >&2; usage; }
[ -n "$OUT" ]     || { echo "error: --out is required (where to write the <project>-config skeleton)" >&2; usage; }

# Slug must be a valid Kubernetes namespace / DNS-1123 label.
case "$PROJECT" in
  *[!a-z0-9-]*|-*|*-) echo "error: <project> must be a DNS-1123 label (lowercase alphanumeric + hyphens, no leading/trailing hyphen)" >&2; exit 2;;
esac
# The <project>-<service> convention means an `sddp`-prefixed project reads as a
# service of the existing sddp project — refuse it to keep the naming honest.
case "$PROJECT" in
  sddp|sddp-*) echo "error: '$PROJECT' collides with the existing sddp project namespace convention; pick a distinct project slug" >&2; exit 2;;
esac

HERE="$(cd "$(dirname "$0")" && pwd)"           # .../sddp-platform-config/bootstrap
REPO="$(cd "$HERE/.." && pwd)"                  # .../sddp-platform-config
TPL="$HERE/templates"
APP_OUT="$REPO/apps/${PROJECT}.yaml"

[ -e "$APP_OUT" ] && { echo "error: $APP_OUT already exists — is project '$PROJECT' already onboarded?" >&2; exit 1; }
[ -e "$OUT" ]     && { echo "error: --out path '$OUT' already exists; refusing to overwrite" >&2; exit 1; }

# Only __PROJECT__ and __OWNER__ are filled here. __SVC__/__PORT__/__HOST__/
# __DIGEST__ are intentionally LEFT for the per-service onboard.sh.
proj_stamp() { # <src> <dst>
  sed -e "s/__PROJECT__/${PROJECT}/g" \
      -e "s#__OWNER__#${OWNER}#g" \
      "$1" > "$2"
}

# 1. Platform side: apps/<project>.yaml
proj_stamp "$TPL/app-of-apps-application.yaml" "$APP_OUT"
echo "Wrote platform entry: apps/${PROJECT}.yaml"

# 2. Config side: the <project>-config skeleton
SRC="$TPL/config-repo"
while IFS= read -r -d '' f; do
  rel="${f#"$SRC"/}"
  dst="$OUT/$rel"
  mkdir -p "$(dirname "$dst")"
  proj_stamp "$f" "$dst"
  # preserve the onboarder's exec bit
  [ -x "$f" ] && chmod +x "$dst"
done < <(find "$SRC" -type f -print0)
# onboard.sh ships executable even if the template lost its bit in git
chmod +x "$OUT/onboarding/onboard.sh" 2>/dev/null || true
echo "Wrote config skeleton: $OUT/"

cat <<EOF

Next (manual, by design):
  1. Create the GitHub repo '${OWNER}/${PROJECT}-config' and push $OUT as its main.
  2. Give ArgoCD a read deploy key for it (same pattern as sddp-app-config), and add
     an argocd repo credential whose url EXACTLY matches
       git@github.com:${OWNER}/${PROJECT}-config.git
  3. Review + open a PR adding apps/${PROJECT}.yaml here (sddp-platform-config).
     On merge, the root app-of-apps creates the AppProject + Application, and the
     '${PROJECT}' namespace comes up with the default-deny floor + DNS egress.
  4. For EACH service (repo named ${PROJECT}-<service>, e.g. ${PROJECT}-app):
       a. create it from sddp-service-template; set its CONFIG_REPO repo variable to
          '${OWNER}/${PROJECT}-config' so its release pipeline auto-PRs the right repo:
            gh variable set CONFIG_REPO --repo ${OWNER}/${PROJECT}-<service> --body ${OWNER}/${PROJECT}-config
          then let its pipeline sign + promote.
       b. add its signer entry to POL-01 (onboarding/pol-01-signer-entry.snippet.yaml,
          subject .../${PROJECT}-<service>/.github/workflows/release.yml@refs/heads/main).
       c. in ${PROJECT}-config, onboard with the FULL repo name as <svc>:
            ./onboarding/onboard.sh ${PROJECT}-<service> --digest sha256:... [--host ...]
EOF
