
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
