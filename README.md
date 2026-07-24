# DevSecOps Terraform Security Pipeline

![Security Scan](https://github.com/harshh211/terraform-security-pipeline/actions/workflows/security-scan.yml/badge.svg)

Shift-left security for AWS infrastructure-as-code: Terraform scanned automatically
by Checkov, tfsec, Trivy, and gitleaks, enforced by a GitHub Actions policy gate
that blocks insecure infrastructure before it can ever be deployed — plus a
custom-written Checkov policy that catches a real gap none of the four
off-the-shelf tools could.

**Result: started at 45 failed security checks across the infrastructure.
Ended at 0.** Every finding was either fixed or is documented with a reasoned
justification in [`docs/findings.md`](docs/findings.md).

> **Note:** `terraform apply` is never run in this project. Everything here is
> static analysis against Terraform source — the pipeline reads the files,
> never deploys them.

## Why this project exists

Most of my other security work — [nhi-escalation-scanner](https://github.com/harshh211/nhi-escalation-scanner),
[Home-SOC-Lab](https://github.com/harshh211/Home-SOC-Lab), [AD-Attack-Defense-Lab](https://github.com/harshh211/AD-Attack-Defense-Lab) —
is offensive or detective: finding a live misconfiguration, or catching an
attack after it happens. This project is preventive and automated instead:
it stops insecure infrastructure from ever being deployed, with no human
running a scanner by hand. That's the "shift-left" half of security
engineering the rest of my portfolio didn't cover yet.

## Architecture

```
Terraform source (.tf files)
        │
        ├──► Checkov ──► policy gate (blocks the build on critical/high findings)
        ├──► tfsec ────► report-only
        ├──► Trivy ────► config + secret scanning (local, comparison)
        └──► gitleaks ─► secret scanning (local, comparison)
        │
   GitHub Actions
   (runs on every push / PR to main)
```

## What's actually built

A realistic small AWS environment, entirely in Terraform:

- **Networking** — VPC, subnet, security group (HTTPS-only, scoped to the
  internal network), locked-down default security group, VPC Flow Logs to a
  KMS-encrypted CloudWatch log group
- **Compute** — EC2 instance (IMDSv2 required, encrypted EBS, private,
  instance profile attached, detailed monitoring), RDS MySQL (private,
  encrypted, Multi-AZ, IAM auth, deletion protection, CloudWatch log exports,
  enhanced monitoring)
- **Storage** — primary S3 bucket (KMS encryption, versioning, lifecycle
  rules, event notifications, access logging, cross-region replication),
  plus a log-delivery bucket and a replication target bucket, each held to
  the same security bar as the primary bucket
- **IAM** — every role and policy scoped to least privilege; the CI
  deployment role's trust policy is scoped to one named principal rather
  than the AWS account root

## The pipeline

[`.github/workflows/security-scan.yml`](.github/workflows/security-scan.yml)
runs on every push and pull request to `main`:

- **Checkov** runs as a hard policy gate. It enforces an explicit allowlist
  of check IDs covering public exposure (open SSH/RDP, public S3/RDS),
  privilege escalation and wildcard IAM policies, and the custom hardcoded-
  secret check below. A build fails if any of these trip — nothing else in
  the check suite blocks the build, which keeps the gate meaningful instead
  of noisy.
- **tfsec** runs in report-only mode for comparison, so both tools' output is
  visible without duplicating the enforcement.

The gate went from failing on an intentionally insecure `main` branch to
passing after remediation — visible directly in the [Actions history](https://github.com/harshh211/terraform-security-pipeline/actions).

## Multi-tool comparison

Checkov, tfsec, and Trivy all statically analyze the same Terraform and
overlap heavily on the obvious issues (open ports, public storage, missing
encryption). Where they're actually useful side by side:

| Finding | Checkov | tfsec | Trivy |
|---|---|---|---|
| S3 default (AWS-managed) encryption | Sufficient (pass) | Requires explicit config (fail) | Requires explicit config (fail) |

Same infrastructure, different built-in opinions about what "encrypted"
means — not a bug in either tool, a real baseline disagreement worth
knowing about before you trust any single scanner's "clean" result.

## The secrets-scan gap (and why the custom policy exists)

`compute.tf` originally had a hardcoded RDS password. Three purpose-built
secret-detection tools were run against it — and every one missed it, for a
different reason:

| Tool | Result | Why |
|---|---|---|
| Checkov (secrets engine) | Scanned, 0 findings | No pattern matched a plain, human-readable password |
| Trivy (secret scanner) | 0 findings | Doesn't treat `.tf` as a scannable file type by default |
| gitleaks | Scanned the file, 0 findings | Default rules target API-key-shaped or high-entropy strings — a dictionary-style password like `SuperSecret123!` matches neither |

Pattern- and entropy-based secret scanning is strong against machine-generated
credentials and weak against human-chosen ones. That gap is what motivated
[`custom_checks/no_hardcoded_sensitive_values.py`](custom_checks/no_hardcoded_sensitive_values.py)
(**`CKV_CUSTOM_1`**) — a Checkov policy that flags a hardcoded literal on
*any* attribute whose name looks sensitive (`password`, `secret`, `token`,
`api_key`), regardless of what the value looks like. Detection by attribute
name instead of value shape closes the exact hole the other three shared.

The check is wired directly into the CI policy gate, not just run locally.

## Repository structure

```
terraform/          Infrastructure — network, compute, IAM, S3, variables
custom_checks/       Custom Checkov policy (CKV_CUSTOM_1) + test fixture
.github/workflows/  CI pipeline definition
docs/findings.md     Full scan history: every finding, every fix, with reasoning
```

## Running it locally

```bash
brew install hashicorp/tap/terraform
pip3 install checkov

terraform -chdir=terraform init
checkov -d terraform --external-checks-dir custom_checks
```

No AWS account or credentials required — everything here is static analysis.

## Stack

Terraform · Checkov · tfsec · Trivy · gitleaks · GitHub Actions

