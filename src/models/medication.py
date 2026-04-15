from dataclasses import dataclass


@dataclass
class Medication:
    medication_id: int
    medication_name: str
    schedule: str | None = None

    @classmethod
    def from_row(cls, row: dict | None):
        if not row:
            return None
        return cls(
            medication_id=row["medication_id"],
            medication_name=row["medication_name"],
            schedule=row.get("schedule")
        )