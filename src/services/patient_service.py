"""
healthcare_management/services/patient_service.py
Implements business logic for patient-related operations.
Translates database exceptions into domain errors (ValueError) for the CLI.
"""

from psycopg2 import OperationalError, DatabaseError, InterfaceError
from src.repositories.patient_repository import PatientRepository
from src.repositories.patient_insurance_repository import PatientInsuranceRepository
from src.repositories.prescription_repository import PrescriptionRepository

class PatientService:

    def __init__(self) -> None:
        self._patient_repo = PatientRepository()
        self._patient_insurance = PatientInsuranceRepository()
        self._prescription_repo = PrescriptionRepository()

    def get_patient_by_mrn(self, mrn: str) -> dict:
        patient_details = self._call_repository_method(
            self._patient_repo.find_by_mrn, 
            mrn, 
            not_found_message=f"No patient found with MRN {mrn}")
        insurance_details = self._call_repository_method(
            self._patient_insurance.find_by_mrn, 
            mrn, 
            not_found_message=f"No insurance details found for patient with MRN {mrn}")
        active_prescriptions = self._call_repository_method(
            self._prescription_repo.find_active_by_mrn, 
            mrn, 
            not_found_message=f"No active prescriptions found for patient with MRN {mrn}")
        return {**patient_details, **insurance_details, **active_prescriptions}
            
        
    def _call_repository_method(self, repository_func, *args, not_found_message: str) -> dict:
        """Call a repository method with error handling for database exceptions and not found cases."""
        try:
            result = repository_func(*args)
        except (OperationalError, InterfaceError) as e:
            raise ValueError("Could not connect to the database. Please try again later.") from e
        except DatabaseError as e:
            raise ValueError("An error occured while retreiving patient details") from e
        if not result:
            raise ValueError(not_found_message)
        return result