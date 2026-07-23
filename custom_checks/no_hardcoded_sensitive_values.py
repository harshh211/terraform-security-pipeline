import re
from typing import Any, Dict, List

from checkov.common.models.enums import CheckCategories, CheckResult
from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck

SENSITIVE_KEY_PATTERN = re.compile(r"(password|secret|token|api_key|access_key)", re.IGNORECASE)

# Matches either a full ${...} interpolation, or a bare Terraform reference
# expression like var.x, local.x, data.aws_x.y, aws_instance.foo.id
REFERENCE_PATTERN = re.compile(
    r"^\$\{.*\}$|^[A-Za-z_][A-Za-z0-9_\-]*(\.[A-Za-z0-9_\-\[\]\*]+)+$"
)


class NoHardcodedSensitiveValues(BaseResourceCheck):
    def __init__(self):
        name = "Ensure no literal value is hardcoded on a sensitive-named attribute"
        check_id = "CKV_CUSTOM_1"
        supported_resources = [
            "aws_db_instance",
            "aws_instance",
            "aws_iam_role_policy",
            "aws_iam_user",
            "aws_secretsmanager_secret",
        ]
        categories = [CheckCategories.SECRETS]
        super().__init__(name=name, id=check_id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf: Dict[str, List[Any]]) -> CheckResult:
        for key, value in conf.items():
            if not SENSITIVE_KEY_PATTERN.search(key):
                continue
            if not value:
                continue
            actual = value[0]
            if isinstance(actual, str) and not REFERENCE_PATTERN.match(actual):
                self.details = [f"Attribute '{key}' is set to a hardcoded literal value"]
                return CheckResult.FAILED
        return CheckResult.PASSED


check = NoHardcodedSensitiveValues()
