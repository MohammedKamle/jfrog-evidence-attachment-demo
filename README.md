# JFrog Evidence Attachment Demo

End-to-end demonstration of JFrog's **Evidence Management** feature. This repo builds a Node.js Docker image, publishes it to JFrog Artifactory, attaches signed evidence at every stage of the SDLC, creates an immutable Release Bundle v2, and promotes it from **DEV** to **PROD** with a complete audit trail.

## Evidence Chain

```
┌─────────────┐    ┌─────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  Unit Tests  │    │  SonarQube  │    │    Build     │    │   In-Toto    │    │  Promotion   │
│  Results     │    │  Quality    │    │  Signature   │    │  Attestation │    │  Approval    │
│  (package)   │    │  (package)  │    │  (build)     │    │  (RBv2)      │    │  (RBv2)      │
└──────┬───────┘    └──────┬──────┘    └──────┬───────┘    └──────┬───────┘    └──────┬───────┘
       │                   │                  │                   │                   │
       ▼                   ▼                  ▼                   ▼                   ▼
  Docker Image ────► Build Info ────► Release Bundle v2 ────► Promote to PROD
```

## Prerequisites

- **JFrog Platform** account (SaaS or self-hosted, with Evidence feature enabled)
- **JFrog CLI** v2.65.0+ ([install guide](https://jfrog.com/help/r/jfrog-cli/install-jfrog-cli))
- **GitHub** repository (to host this code and run Actions)
- **OpenSSL** (to generate signing keys)

---

## Part 1: JFrog Platform Setup (UI)

### Step 1 — Create Environments

1. Go to **Administration > Lifecycle > Environments**
2. Click **New Environment**
3. Create two environments:

| Environment | Description |
|-------------|-------------|
| `DEV`       | Development / CI builds |
| `PROD`      | Production releases |

### Step 2 — Create Repositories

Go to **Administration > Repositories > Add Repositories**.

#### 2a. Local Docker Repositories

| Repository Name | Type | Package Type | Environment |
|-----------------|------|-------------|-------------|
| `evidence-demo-docker-dev-local` | Local | Docker | DEV |
| `evidence-demo-docker-prod-local` | Local | Docker | PROD |

For each: click **New Local Repository** > select **Docker** > enter the name > go to the **Advanced** tab and assign the environment.

#### 2b. Remote Docker Repository

| Repository Name | Type | Package Type | URL |
|-----------------|------|-------------|-----|
| `evidence-demo-docker-remote` | Remote | Docker | `https://registry-1.docker.io` |

Click **New Remote Repository** > select **Docker** > set the URL to Docker Hub.

#### 2c. Virtual Docker Repository

| Repository Name | Type | Included Repos | Default Deployment |
|-----------------|------|----------------|-------------------|
| `evidence-demo-docker-dev-virtual` | Virtual | `evidence-demo-docker-dev-local`, `evidence-demo-docker-remote` | `evidence-demo-docker-dev-local` |

Click **New Virtual Repository** > select **Docker** > add the local and remote repos > set the default deployment target.

#### 2d. Generic Local Repository

| Repository Name | Type | Package Type | Environment |
|-----------------|------|-------------|-------------|
| `evidence-demo-generic-dev` | Local | Generic | DEV |

### Step 3 — Create a Signing Key for Release Bundles

1. Go to **Administration > Lifecycle > Signing Keys**
2. Click **Generate Signing Key**
3. Key name: `demo-signing-key`
4. Type: GPG/RSA
5. Click **Generate**

This key makes Release Bundles immutable and tamper-proof.

### Step 4 — Generate a Private Key for Evidence Signing

Run on your local machine:

```bash
# Generate ECDSA key pair
openssl ecparam -genkey -name prime256v1 -noout -out evidence-private.pem
openssl ec -in evidence-private.pem -pubout -out evidence-public.pem

# View the private key content (you will paste this into GitHub Secrets)
cat evidence-private.pem
```

### Step 5 — Create an Access Token

1. Go to **Administration > User Management > Access Tokens**
2. Click **Generate Token**
3. Grant it permissions to deploy artifacts, publish builds, create release bundles, and attach evidence
4. Copy the token value

### Step 6 — Configure GitHub Secrets & Variables

Go to your GitHub repo > **Settings > Secrets and variables > Actions**.

#### Secrets

| Secret Name | Value |
|-------------|-------|
| `ARTIFACTORY_ACCESS_TOKEN` | The access token from Step 5 |
| `JF_USER` | Your JFrog Platform username |
| `PRIVATE_KEY` | Full content of `evidence-private.pem` |

#### Variables

| Variable Name | Example Value |
|---------------|---------------|
| `ARTIFACTORY_URL` | `https://yourcompany.jfrog.io` |
| `BUILD_NAME` | `evidence-demo-build` |
| `BUNDLE_NAME` | `evidence-demo-bundle` |

---

## Part 2: Repository Structure

```
evidence-attachment-demo/
├── app/
│   ├── server.js              # Express REST API
│   └── server.test.js         # Jest unit tests
├── .github/
│   └── workflows/
│       ├── build-with-evidence.yml  # CI: build, test, publish, attach evidence
│       └── promote.yml              # CD: promote RBv2 DEV → PROD
├── policy/
│   ├── policy.rego            # OPA policy for promotion gating
│   └── policy_test.rego       # OPA policy tests
├── scripts/
│   └── generate-intoto.sh     # Helper to create in-toto attestation
├── Dockerfile                 # Multi-stage Docker build
├── .dockerignore
├── package.json
├── sonar-project.properties   # SonarQube config (optional)
└── README.md
```

---

## Part 3: What the Pipelines Do

### `build-with-evidence.yml` — Build Pipeline

This workflow runs on push to `main` or manual dispatch. It performs the following:

| Step | Action | Evidence Attached |
|------|--------|-------------------|
| 1 | Install deps, run Jest unit tests | — |
| 2 | Build and push Docker image to Artifactory | — |
| 3 | **Attach evidence** to Docker package | Unit test results (`test-results/v1`) |
| 4 | **Attach evidence** to Docker package | SonarQube quality gate (`sonarqube/v1`) |
| 5 | Upload JUnit XML as generic artifact | — |
| 6 | Publish Build Info to Artifactory | — |
| 7 | **Attach evidence** to Build | Build signature (`build-signature/v1`) |
| 8 | Create Release Bundle v2 from Build | — |
| 9 | **Attach evidence** to Release Bundle | In-toto SLSA provenance (`attestation/v1`) |

### `promote.yml` — Promotion Pipeline

This workflow is triggered manually via `workflow_dispatch`. You provide the bundle version to promote.

| Step | Action | Evidence Attached |
|------|--------|-------------------|
| 1 | Promote Release Bundle v2 from DEV → PROD | — |
| 2 | **Attach evidence** to Release Bundle | Promotion approval (`promotion/v1`) |

---

## Part 4: Running the Demo

### Phase 1 — Build and Attach Evidence

1. Push code to your GitHub repo (or trigger manually):
   - Go to **Actions** > **Build with Evidence** > **Run workflow**
2. Watch the pipeline run. Each step attaches signed evidence.
3. When complete, you will have:
   - A Docker image in `evidence-demo-docker-dev-local`
   - A Build Info record with evidence
   - A Release Bundle v2 with evidence

### Phase 2 — Verify Evidence in JFrog UI

1. **Package evidence:**
   - Go to **Application > Artifactory > Packages**
   - Find `evidence-demo-app` > click the version
   - Go to the **Evidence** tab
   - You should see `test-results` and `sonarqube` evidence entries

2. **Build evidence:**
   - Go to **Application > Artifactory > Builds**
   - Find `evidence-demo-build` > click the build number
   - Go to the **Evidence** tab
   - You should see the `build-signature` evidence

3. **Release Bundle evidence:**
   - Go to **Application > Lifecycle**
   - Find `evidence-demo-bundle` > click the version
   - Go to **Version Timeline**
   - You should see `in-toto attestation` evidence

### Phase 3 — Promote to PROD

1. Go to **Actions** > **Promote Release Bundle** > **Run workflow**
2. Enter the bundle version (same as the build number from Phase 1)
3. Select `PROD` as target environment
4. Click **Run workflow**

### Phase 4 — Verify the Full Evidence Chain

1. Go to **Application > Lifecycle** in JFrog UI
2. Find `evidence-demo-bundle` > click the version
3. The bundle should now show in `PROD` environment
4. Go to **Version Timeline** — you will see the complete chain:
   - `test-results` (from package)
   - `sonarqube` (from package)
   - `build-signature` (from build)
   - `in-toto attestation` (from release bundle)
   - `promotion` (from promotion step)
5. Click any evidence entry to see the DSSE-signed envelope with the predicate payload

---

## Part 5: Evidence Types Reference

| Predicate Type URL | Slug | Attached To | Description |
|--------------------|------|-------------|-------------|
| `https://jfrog.com/evidence/test-results/v1` | `test-results` | Docker package | Unit test pass/fail with counts |
| `https://jfrog.com/evidence/sonarqube/v1` | `sonarqube` | Docker package | Quality gate status and metrics |
| `https://jfrog.com/evidence/build-signature/v1` | `build-signature` | Build Info | CI build metadata and provenance |
| `https://in-toto.io/attestation/v1` | `attestation` | Release Bundle v2 | SLSA provenance attestation |
| `https://jfrog.com/evidence/promotion/v1` | `promotion` | Release Bundle v2 | Promotion approval record |

---

## Part 6: OPA Policy for Promotion Gating

The `policy/policy.rego` file defines which evidence must be present before a Release Bundle can be promoted. The policy checks for three required predicate slugs:

- `test-results`
- `sonarqube`
- `build-signature`

You can test the policy locally with the OPA CLI:

```bash
# Install OPA
brew install opa   # macOS

# Run tests
opa test policy/ -v
```

To integrate with JFrog's external policy engine, point your promotion policy configuration to this Rego file.

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `jf evd create` fails with auth error | Ensure your access token has Evidence write permissions |
| Docker push fails | Verify the virtual repo resolves to a local repo and Docker login is correct |
| Release bundle creation fails | Check that the signing key `demo-signing-key` exists in Lifecycle > Signing Keys |
| Promotion fails | Ensure the target environment exists and the bundle version is in the source environment |
| Evidence not visible in UI | Navigate to the correct subject (package/build/bundle) and check the Evidence tab |

---

## References

- [JFrog Evidence Management Docs](https://jfrog.com/help/r/jfrog-artifactory-documentation/evidence-management)
- [JFrog CLI Evidence Service](https://docs.jfrog-applications.jfrog.io/jfrog-applications/jfrog-cli/binaries-management-with-jfrog-artifactory/evidence-service)
- [Release Lifecycle Management](https://jfrog.com/help/r/jfrog-artifactory-documentation/release-lifecycle-management-workflow)
- [JFrog Evidence Examples (Official)](https://github.com/jfrog/Evidence-Examples)
- [in-toto Attestation Framework](https://in-toto.io/)
- [SLSA Provenance](https://slsa.dev/provenance/v1)
