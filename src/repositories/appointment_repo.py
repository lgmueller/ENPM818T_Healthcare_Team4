from src.models.appointment import Appointment
from src.repositories.base_repository import BaseRepository


class AppointmentRepository(BaseRepository):

    # For Second CLI Menu option: "Show provider appointments"
    # It finds appointments by provider_id using a JOIN with provider_availability over slot_id
    def find_by_provider(self, provider_id):
        rows = self._fetch_all(
            """
            SELECT a.appointment_id, a.mrn, a.slot_id, a.appt_type, a.appt_status
            FROM appointment a
            JOIN provider_availability pa ON a.slot_id = pa.slot_id
            WHERE pa.provider_id = %s
            """,
            (provider_id,)
        )
        return [Appointment.from_row(r) for r in rows]
    
    # For Third CLI menu: "System dashboard" - count total appointments for today
    def count_todays_appointments(self):
        row = self._fetch_one(
            """
            SELECT COUNT(*) AS count
            FROM appointment a
            JOIN provider_availability pa ON a.slot_id = pa.slot_id
            WHERE pa.slot_date = CURRENT_DATE
            """,
            ()
        )
        return row["count"]
    
    
    # EXTRA methods for completeness - not used in CLI but useful for future extensions

    def find_by_id(self, appointment_id):
        row = self._fetch_one(
            "SELECT * FROM appointment WHERE appointment_id = %s",
            (appointment_id,)
        )
        return Appointment.from_row(row) if row else None

    def find_all(self, limit=20, offset=0):
        rows = self._fetch_all(
            "SELECT * FROM appointment ORDER BY appointment_id LIMIT %s OFFSET %s",
            (limit, offset)
        )
        return [Appointment.from_row(r) for r in rows]

    def create(self, appt: Appointment):
        self._execute(
            """
            INSERT INTO appointment (
                mrn, slot_id, appt_type, appt_status, visit_reason, previous_admission_id
            )
            VALUES (%s, %s, %s, %s, %s, %s)
            """,
            (
                appt.mrn,
                appt.slot_id,
                appt.appt_type,
                appt.appt_status,
                getattr(appt, "visit_reason", None)
            )
        )
        return appt

    def update(self, appt: Appointment):
        self._execute(
            """
            UPDATE appointment
            SET appt_type=%s,
                appt_status=%s,
                visit_reason=COALESCE(%s, visit_reason),
                previous_admission_id=COALESCE(%s, previous_admission_id)
            WHERE appointment_id=%s
            """,
            (
                appt.appt_type,
                appt.appt_status,
                getattr(appt, "visit_reason", None),
                appt.previous_admission_id,
                appt.appointment_id
            )
        )
        return appt

    def delete(self, appointment_id):
        self._execute(
            "DELETE FROM appointment WHERE appointment_id = %s",
            (appointment_id,)
        )

    def find_by_patient(self, mrn):
        rows = self._fetch_all(
            "SELECT * FROM appointment WHERE mrn = %s ORDER BY appointment_id",
            (mrn,)
        )
        return [Appointment.from_row(r) for r in rows]
    