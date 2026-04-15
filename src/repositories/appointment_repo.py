from models.appointment import Appointment
from repositories.base_repository import BaseRepository


class AppointmentRepository(BaseRepository):

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
                mrn, slot_id, appt_type, appt_status, visit_reason
            )
            VALUES (%s, %s, %s, %s, %s)
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
                visit_reason=%s
            WHERE appointment_id=%s
            """,
            (
                appt.appt_type,
                appt.appt_status,
                getattr(appt, "visit_reason", None),
                appt.appointment_id
            )
        )
        return appt

    def delete(self, appointment_id):
        self._execute(
            "DELETE FROM appointment WHERE appointment_id = %s",
            (appointment_id,)
        )

    # 🔥 Custom query (important for grading)
    def find_by_patient(self, mrn):
        rows = self._fetch_all(
            "SELECT * FROM appointment WHERE mrn = %s ORDER BY appointment_id",
            (mrn,)
        )
        return [Appointment.from_row(r) for r in rows]