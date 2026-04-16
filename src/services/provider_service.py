"""
ENPM818T_Healthcare_Team4/src/services/provider_service.py
Implements business logic for provider-related operations.
Translates database exceptions into domain errors (ValueError) for the CLI.
"""

from dataclasses import is_dataclass, asdict
from psycopg2 import OperationalError, DatabaseError, InterfaceError
from repositories.appointment_repo import AppointmentRepository
from repositories.provider_repo import ProviderRepository

class ProviderService:

    def __init__(self) -> None:
        self._appointment_repo = AppointmentRepository()
        self._provider_repo = ProviderRepository()

    def show_appointments(self, provider_id: str):
        appointments = self._call_repository_method(
            self._appointment_repo.find_by_provider, 
            provider_id, 
            not_found_message=f"No appointments found for provider with ID {provider_id}", 
            label="appointment")
        return {"appointments": appointments}
        
    def get_provider_by_npi(self, npi: str) -> dict:
        return self._call_repository_method(
            self._provider_repo.find_by_npi, 
            npi, 
            not_found_message=f"No provider found with NPI {npi}", 
            label="provider")
    
    def _call_repository_method(self, repository_func, *args, not_found_message: str, label: str):
        """Call a repository method with error handling for database exceptions and not found cases."""
        try:
            result = repository_func(*args)
        except (OperationalError, InterfaceError) as e:
            raise ValueError("Could not connect to the database. Please try again later.") from e
        except DatabaseError as e:
            raise ValueError(f"An error occured while retreiving {label} details") from e
        if not result:
            raise ValueError(not_found_message)
        if is_dataclass(result) and not isinstance(result, type):
            return asdict(result)
        if isinstance(result, list):
            return [asdict(r) if is_dataclass(r) and not isinstance(r, type) else r for r in result]
        return result
        