#!/usr/bin/env bash
#
# Generate an in-toto SLSA Provenance v1 attestation JSON file.
# Used as a predicate for JFrog Evidence attachment.
#
# Usage:
#   ./scripts/generate-intoto.sh \
#     --bundle-name "my-bundle" \
#     --bundle-version "42" \
#     --repo "owner/repo" \
#     --commit "abc123" \
#     --workflow "Build with Evidence" \
#     --run-id "1234567890" \
#     --ref "refs/heads/main" \
#     --output intoto-attestation.json

set -euo pipefail

BUNDLE_NAME=""
BUNDLE_VERSION=""
REPO=""
COMMIT=""
WORKFLOW=""
RUN_ID=""
REF=""
OUTPUT="intoto-attestation.json"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --bundle-name)    BUNDLE_NAME="$2";    shift 2 ;;
    --bundle-version) BUNDLE_VERSION="$2"; shift 2 ;;
    --repo)           REPO="$2";           shift 2 ;;
    --commit)         COMMIT="$2";         shift 2 ;;
    --workflow)       WORKFLOW="$2";        shift 2 ;;
    --run-id)         RUN_ID="$2";         shift 2 ;;
    --ref)            REF="$2";            shift 2 ;;
    --output)         OUTPUT="$2";         shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

if [[ -z "$BUNDLE_NAME" || -z "$BUNDLE_VERSION" ]]; then
  echo "Error: --bundle-name and --bundle-version are required"
  exit 1
fi

NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

cat > "$OUTPUT" <<EOF
{
  "_type": "https://in-toto.io/Statement/v1",
  "subject": [
    {
      "name": "${BUNDLE_NAME}",
      "version": "${BUNDLE_VERSION}"
    }
  ],
  "predicateType": "https://slsa.dev/provenance/v1",
  "predicate": {
    "buildDefinition": {
      "buildType": "https://github.com/actions/runner",
      "externalParameters": {
        "workflow": "${WORKFLOW}",
        "ref": "${REF}"
      },
      "internalParameters": {
        "github_run_id": "${RUN_ID}"
      },
      "resolvedDependencies": [
        {
          "uri": "git+https://github.com/${REPO}@${REF}",
          "digest": {
            "sha1": "${COMMIT}"
          }
        }
      ]
    },
    "runDetails": {
      "builder": {
        "id": "https://github.com/actions/runner"
      },
      "metadata": {
        "invocationId": "${RUN_ID}",
        "startedOn": "${NOW}"
      }
    }
  }
}
EOF

echo "In-toto attestation written to ${OUTPUT}"
