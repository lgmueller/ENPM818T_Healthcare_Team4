"""
ENPM818T_Healthcare_Team4/src/services/dashboard_service.py
Implements business logic for dashboard-related operations.
Translates database exceptions into domain errors (ValueError) for the CLI.
"""

from psycopg2 import OperationalError, InterfaceError
from src.repositories.patient_repo import PatientRepository
from src.repositories.appointment_repo import AppointmentRepository
from src.repositories.prescription_repo import PrescriptionRepository

class DashboardService:

    def __init__(self) -> None:
        self._patient_repo = PatientRepository()
        self._appointment_repo = AppointmentRepository()
        self._prescription_repo = PrescriptionRepository()

    def main(self) -> dict:
        return {
                "total_patients": self._get_count(self._patient_repo.count_patients, "patients"),
                "prescriptions_this_month": self._get_count(self._prescription_repo.count_monthly_prescriptions, "prescriptions"),
                "appointments_today": self._get_count(self._appointment_repo.count_todays_appointments, "appointments")
            }
            
    def _get_count(self, repository_func, label: str, *args) -> int:
        """Call a repository method to get total count with error handling for database exceptions and not found cases."""
        try:
            result = repository_func(*args)
        except (OperationalError, InterfaceError) as e:
            raise ValueError("Could not connect to the database. Please try again later.") from e
        except (Exception) as e:
            raise ValueError(f"An error occurred while retrieving {label} count") from e
        return result