from dataclasses import dataclass
from datetime import datetime

@dataclass
class Prescription:
    prescription_id: int
    mrn: str
    provider_id: int | None
    medication_id: int
    date_prescribed: datetime
    prescription_status: str

    @classmethod
    def from_row(cls, row: dict | None):
        if not row:
            return None
        return cls(
            prescription_id=row["prescription_id"],
            mrn=row["mrn"],
            provider_id=row.get("provider_id"),
            medication_id=row["medication_id"],
            date_prescribed=row["date_prescribed"],
            prescription_status=row["prescription_status"]
        )