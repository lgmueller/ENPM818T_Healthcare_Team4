from dataclasses import dataclass
from datetime import datetime


@dataclass
class Insurance:
    insurance_id: int
    mrn: str
    policy_no: str
    insurance_company: str
    coverage: str 
    group_no: str
    copay_amount: float
    effective_date: datetime
    termination_date: datetime

    @classmethod
    def from_row(cls, row: dict | None):
        if not row:
            return None
        return cls(
            insurance_id=row["insurance_id"],
            mrn=row["mrn"],
            policy_no=row["policy_no"],
            insurance_company=row["insurance_company"],
            coverage=row["coverage"],
            group_no=row["group_no"],
            copay_amount=row["copay_amount"],
            effective_date=row["effective_date"],
            termination_date=row["termination_date"]
        )