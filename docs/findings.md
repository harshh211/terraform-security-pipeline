
## Network scan — VPC + security group

Running total: 18 failed, 8 passed

| Check | Issue | Severity | Verdict |
|---|---|---|---|
| CKV_AWS_24 | SSH (22) open to 0.0.0.0/0 | High | Fix |
| CKV_AWS_25 | RDP (3389) open to 0.0.0.0/0 | High | Fix |
| CKV2_AWS_12 | Default SG allows all traffic | High | Fix |
| CKV2_AWS_11 | VPC flow logs disabled | Medium | Fix — detection gap |
| CKV_AWS_382 | Unrestricted egress | Medium | Fix — exfil path |
| CKV_AWS_23 | Rules missing descriptions | Low | Fix — hygiene |
| CKV2_AWS_5 | SG not attached to a resource | Info | Accept — no EC2 yet |

## IAM scan

Running total: 31 failed, 23 passed

| Check | Resource | Issue | Severity | Verdict |
|---|---|---|---|---|
| CKV_AWS_62/63/286/287/288/289/290/355, CKV2_AWS_40 | app_policy | Action:* on Resource:* — full admin | Critical | Fix — 9 findings, one root cause |
| CKV_AWS_60 | ci_role | Trust policy allows any AWS principal | Critical | Fix |
| CKV_AWS_286/289/355 | ci_policy | Escalation primitives on Resource:* | High | Fix |

Note: ci_policy passes every wildcard-action check (no literal `*`) but still
fails the escalation check. Checkov flags escalation-capable permissions; it
does not trace where the path leads or how many hops it takes.

## EC2 + RDS scan

Running total: 45 failed, 30 passed

| Check | Resource | Issue | Severity | Verdict |
|---|---|---|---|---|
| CKV_AWS_79 | app_server | IMDSv1 enabled | Critical | Fix — SSRF-to-credential-theft path |
| CKV_AWS_88 | app_server | Public IP assigned | High | Fix |
| CKV_AWS_8 | app_server | Root volume unencrypted | Medium | Fix |
| CKV2_AWS_41 | app_server | No IAM role attached | Low | Fix |
| CKV_AWS_17 | app_db | Publicly accessible | Critical | Fix |
| CKV_AWS_16 | app_db | Storage unencrypted | High | Fix |
| CKV_AWS_293 | app_db | No deletion protection | Medium | Fix |
| CKV_AWS_161 | app_db | No IAM authentication | Medium | Fix |
| CKV_AWS_129/157/118/226, CKV2_AWS_60 | app_db | Logging, Multi-AZ, monitoring, auto-upgrade, snapshot tags | Low | Fix — ops hardening |
| CKV_AWS_126/135 | app_server | Detailed monitoring, EBS optimization | Info | Accept — cost/perf, not security |

## Secrets scan

Checkov secrets framework run standalone: 0 findings. The hardcoded RDS
password in compute.tf was NOT detected — Checkov's console masking of
password-shaped fields is cosmetic, not a rule match. This is the gap
gitleaks is added to close in Week 2.
