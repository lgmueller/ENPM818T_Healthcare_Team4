"""
ENPM818T_Healthcare_Team4/src/services/patient_service.py
Implements business logic for patient-related operations.
Translates database exceptions into domain errors (ValueError) for the CLI.
"""

from psycopg2 import OperationalError, InterfaceError
from dataclasses import asdict, is_dataclass
from src.repositories.patient_repo import PatientRepository
from src.repositories.insurance_repo import InsuranceRepository
from src.repositories.prescription_repo import PrescriptionRepository

class PatientService:

    def __init__(self) -> None:
        self._patient_repo = PatientRepository()
        self._patient_insurance = InsuranceRepository()
        self._prescription_repo = PrescriptionRepository()

    def get_patient_by_mrn(self, mrn: str) -> dict:
        patient_details = self._call_repository_method(
            self._patient_repo.find_by_id, 
            mrn)
        if not patient_details:
            raise ValueError(f"Patient details not found for MRN {mrn}")
        
        insurance_details = self._call_repository_method(
            self._patient_insurance.find_by_mrn, 
            mrn)
        active_prescriptions = self._call_repository_method(
            self._prescription_repo.find_active_prescriptions, 
            mrn)
        result = {**patient_details, **insurance_details}
        if active_prescriptions:
            result["active_prescriptions"] = active_prescriptions
        return result            
        
    def _call_repository_method(self, repository_func, *args):
        """Call a repository method with error handling for database exceptions"""
        try:
            result = repository_func(*args)
        except (OperationalError, InterfaceError) as e:
            raise ValueError("Could not connect to the database. Please try again later.") from e
        except (Exception) as e:
            raise ValueError("An error occured while retreiving patient details") from e
        if is_dataclass(result) and not isinstance(result, type):
            return asdict(result)
        if isinstance(result, list):
            return [asdict(r) if is_dataclass(r) and not isinstance(r, type) else r for r in result]
        return result