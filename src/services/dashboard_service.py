"""
healthcare_management/services/dashboard_service.py
Implements business logic for dashboard-related operations.
Translates database exceptions into domain errors (ValueError) for the CLI.
"""

from datetime import date
from psycopg2 import OperationalError, DatabaseError, InterfaceError
from src.repositories.patient_repository import PatientRepository
from src.repositories.appointment_repository import AppointmentRepository
from src.repositories.prescription_repository import PrescriptionRepository

class DashboardService:

    def __init__(self) -> None:
        self._patient_repo = PatientRepository()
        self._appointment_repo = AppointmentRepository()
        self._prescription_repo = PrescriptionRepository()

    def main(self) -> dict:
        return {
                "total_patients": self._get_count(self._patient_repo.find_count, "patients"),
                "prescriptions_this_month": self._get_count(self._prescription_repo.find_count_by_month, "prescriptions", date.today()),
                "appointments_today": self._get_count(self._appointment_repo.find_count_by_day, "appointments", date.today())
            }
            
    def _get_count(self, repository_func, label: str, *args) -> int:
        """Call a repository method to get total count with error handling for database exceptions and not found cases."""
        try:
            result = repository_func(*args)
        except (OperationalError, InterfaceError) as e:
            raise ValueError("Could not connect to the database. Please try again later.") from e
        except DatabaseError as e:
            raise ValueError(f"An error occurred while retrieving {label} count") from e
        return result.get("count", 0) if result else 0