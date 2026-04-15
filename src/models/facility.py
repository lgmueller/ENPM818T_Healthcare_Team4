from dataclasses import dataclass


@dataclass
class Facility:
    facility_id: int
    facility_name: str
    facility_type: str

    @classmethod
    def from_row(cls, row: dict | None):
        if not row:
            return None
        return cls(
            facility_id=row["facility_id"],
            facility_name=row["facility_name"],
            facility_type=row["facility_type"]
        )