from models.patient import Patient
from src.repositories.base_repository import BaseRepository


class PatientRepository(BaseRepository):

    def find_by_id(self, mrn):
        row = self._fetch_one(
            "SELECT * FROM patient WHERE mrn = %s",
            (mrn,)
        )
        return Patient.from_row(row) if row else None

    def find_all(self, limit=20, offset=0):
        rows = self._fetch_all(
            "SELECT * FROM patient ORDER BY mrn LIMIT %s OFFSET %s",
            (limit, offset)
        )
        return [Patient.from_row(r) for r in rows]

    def create(self, patient: Patient):
        self._execute(
            """
            INSERT INTO patient (
                mrn, first_name, middle_name, last_name, dob, gender,
                primary_provider_id, has_insurance, registration_date
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            """,
            (
                patient.mrn,
                patient.first_name,
                getattr(patient, "middle_name", None),
                patient.last_name,
                patient.dob,
                patient.gender,
                patient.primary_provider_id,
                patient.has_insurance,
                patient.registration_date
            )
        )
        return patient

    def update(self, patient: Patient):
        self._execute(
            """
            UPDATE patient
            SET first_name=%s,
                middle_name=COALESCE(%s, middle_name),
                last_name=%s,
                gender=coalesce(%s, gender),
                primary_provider_id=COALESCE(%s, primary_provider_id),
                has_insurance=%s
            WHERE mrn=%s
            """,
            (
                patient.first_name,
                getattr(patient, "middle_name", None),
                patient.last_name,
                patient.gender,
                patient.primary_provider_id,
                patient.has_insurance,
                patient.mrn
            )
        )
        return patient

    def delete(self, mrn):
        self._execute(
            "DELETE FROM patient WHERE mrn = %s",
            (mrn,)
        )