from dataclasses import dataclass
from datetime import date

@dataclass
class Patient:
    mrn: str
    first_name: str
    middle_name: str | None = None
    last_name: str
    dob: date
    gender: str | None = None
    primary_provider_id: int | None = None

    @classmethod
    def from_row(cls, row: dict | None):
        if not row:
            return None
        return cls(
            mrn=row["mrn"],
            first_name=row["first_name"],
            middle_name=row.get("middle_name"),
            last_name=row["last_name"],
            dob=row["dob"],
            gender=row.get("gender"),
            primary_provider_id=row.get("primary_provider_id")
        )