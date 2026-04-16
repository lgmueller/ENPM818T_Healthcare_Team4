from models.prescription import Prescription
from repositories.base_repository import BaseRepository


class PrescriptionRepository(BaseRepository):

    # For Third CLI menu: "System dashboard" - count prescriptions prescribed in the current month
    def count_monthly_prescriptions(self):
        row = self._fetch_one(
            """
            SELECT COUNT(*) AS count
            FROM prescription
            WHERE DATE_TRUNC('month', date_prescribed) = DATE_TRUNC('month', CURRENT_DATE)
            """,
            ()
        )
        return row["count"]
    
    
    # EXTRA methods for completeness - not used in CLI but useful for future extensions

    def find_by_id(self, prescription_id):
        row = self._fetch_one(
            "SELECT * FROM prescription WHERE prescription_id = %s",
            (prescription_id,)
        )
        return Prescription.from_row(row) if row else None

    def find_all(self, limit=20, offset=0):
        rows = self._fetch_all(
            "SELECT * FROM prescription ORDER BY prescription_id LIMIT %s OFFSET %s",
            (limit, offset)
        )
        return [Prescription.from_row(r) for r in rows]

    def create(self, p: Prescription):
        self._execute(
            """
            INSERT INTO prescription (
                mrn, provider_id, medication_id,
                date_prescribed, expiration_date,
                dosage, frequency, duration,
                prescription_status, max_num_refills,
                special_instructions
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """,
            (
                p.mrn,
                p.provider_id,
                p.medication_id,
                p.date_prescribed,
                getattr(p, "expiration_date", None),
                getattr(p, "dosage", None),
                getattr(p, "frequency", None),
                getattr(p, "duration", None),
                p.prescription_status,
                p.max_num_refills,
                getattr(p, "special_instructions", None)
            )
        )
        return p

    def update(self, p: Prescription):
        self._execute(
            """
            UPDATE prescription
            SET provider_id=COALESCE(%s, provider_id),
                expiration_date=COALESCE(%s, expiration_date),
                dosage=COALESCE(%s, dosage),
                frequency=COALESCE(%s, frequency),
                duration=COALESCE(%s, duration),
                prescription_status=%s,
                max_num_refills=%s,
                special_instructions=COALESCE(%s, special_instructions)
            WHERE prescription_id=%s
            """,
            (
                p.provider_id,
                getattr(p, "expiration_date", None),
                getattr(p, "dosage", None),
                getattr(p, "frequency", None),
                getattr(p, "duration", None),
                p.prescription_status,
                p.max_num_refills,
                getattr(p, "special_instructions", None),
                p.prescription_id
            )
        )
        return p

    def delete(self, prescription_id):
        self._execute(
            "DELETE FROM prescription WHERE prescription_id = %s",
            (prescription_id,)
        )

    # 🔥 Custom query (important)
    def find_active_prescriptions(self, mrn):
        rows = self._fetch_all(
            """
            SELECT * FROM prescription
            WHERE mrn = %s AND prescription_status = 'active'
            """,
            (mrn,)
        )
        return [Prescription.from_row(r) for r in rows]
    
