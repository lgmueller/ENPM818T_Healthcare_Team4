from dataclasses import dataclass

@dataclass
class Appointment:
    mrn: str
    slot_id: int
    appt_type: str
    appt_status: str
    appointment_id: int | None = None
    previous_admission_id: int | None = None
    visit_reason: str | None = None

    @classmethod
    def from_row(cls, row: dict | None):
        if not row:
            return None
        return cls(
            appointment_id=row["appointment_id"],
            mrn=row["mrn"],
            slot_id=row["slot_id"],
            appt_type=row["appt_type"],
            appt_status=row["appt_status"],
            previous_admission_id=row.get("previous_admission_id"),
            visit_reason=row.get("visit_reason")
        )