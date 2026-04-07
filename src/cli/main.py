"""
healthcare_management/cli/main.py
Prints menu, takes user input, and calls service functions to display results.
Catches ValueError from services and prints user-friendly messages.
"""

from src.services.patient_service import PatientService
from src.services.provider_service import ProviderService
from src.services.dashboard_service import DashboardService


def main() -> None:
    patient_service = PatientService()
    provider_service = ProviderService()
    dashboard_service = DashboardService()
    
    while True:
        _print_menu()
        choice = input("Select option: ").strip()
        
        if choice == "1":
            mrn = input("\nEnter MRN: ").strip()
            _call_function("Patient Record", patient_service.get_patient_by_mrn, mrn)
        elif choice == "2":
            provider_id = input("\nEnter Provider ID: ").strip()
            _call_function(f"Appointments for Provider {provider_id}", provider_service.show_appointments, provider_id)
        elif choice == "3":
            _call_function("Dashboard Results", dashboard_service.main)
        elif choice == "4":
            npi = input("\nEnter NPI: ").strip()
            _call_function("Provider Details", provider_service.get_provider_by_npi, npi)
        elif choice == "5":
            print("Exiting...")
            break
        else:
            print("Invalid choice. Please choose an option from 1 - 5.")

def _print_menu() -> None:
    print("\n=== Healthcare Management System ===")
    print("1. Look up patient by MRN")
    print("2. Show provider appointments")
    print("3. System dashboard")
    print("4. Lookup provider by NPI")
    print("5. Exit")
    print("----------------------")

def _format_label(key: str) -> str:
    """Convert snake_case DB column names to Title Case labels."""
    special = {"npi": "NPI", "id": "ID", "mrn": "MRN"}
    return " ".join(special.get(w, w.capitalize()) for w in key.split("_"))

def _print_output(title: str, data: dict) -> None:
    """Print the output data in a formatted way."""
    if not data:
        print("\nNo data found.")
        return
    print(f"\n=== {title} ===")
    max_len = max(len(_format_label(k)) for k in data)
    for key, value in data.items():
        label = _format_label(key)
        print(f"{label:<{max_len}}  {value}")
        
def _call_function(title: str, service_func, *args) -> None:
    """Call a service function and print the results, handling ValueError exceptions."""
    try:
        _print_output(title, service_func(*args))
    except ValueError as e:
        print(f"Error: {e}")