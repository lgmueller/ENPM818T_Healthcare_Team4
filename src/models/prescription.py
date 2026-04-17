from dataclasses import dataclass
from datetime import datetime

@dataclass
class Prescription:
    mrn: str
    medication_id: int
    date_prescribed: datetime
    prescription_status: str
    max_num_refills: int
    provider_id: int | None
    prescription_id: int | None = None
    expiration_date: datetime | None = None
    dosage: str | None = None
    frequency: str | None = None
    duration: str | None = None
    special_instructions: str | None = None


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
            prescription_status=row["prescription_status"],
            expiration_date=row.get("expiration_date"),
            dosage=row.get("dosage"),
            frequency=row.get("frequency"),
            duration=row.get("duration"),
            max_num_refills=row["max_num_refills"],
            special_instructions=row.get("special_instructions")
        )