from dataclasses import dataclass
from datetime import datetime


@dataclass
class Insurance:
    insurance_id: int
    mrn: str
    policy_no: str
    insurance_company: str
    coverage: str

    @classmethod
    def from_row(cls, row: dict | None):
        if not row:
            return None
        return cls(
            insurance_id=row["insurance_id"],
            mrn=row["mrn"],
            policy_no=row["policy_no"],
            insurance_company=row["insurance_company"],
            coverage=row["coverage"]
        )