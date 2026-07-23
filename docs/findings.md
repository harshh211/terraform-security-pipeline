
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
