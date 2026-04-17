"""
Test suite for service classes.
pytest tests/ --cov=src --cov-report=html
"""

from datetime import date, datetime
from decimal import Decimal
from zoneinfo import ZoneInfo

import pytest
from config.database import DatabaseConfig

# ----------------------------------------------------------------
from services.patient_service import PatientService
from services.dashboard_service import DashboardService
from services.provider_service import ProviderService
# ----------------------------------------------------------------


# ----------------------------------------------------------------
# Fixtures
# ----------------------------------------------------------------

@pytest.fixture(scope="session", autouse=True)
def initialize_db():
    """Initialize the connection pool once for the entire test session."""
    DatabaseConfig.initialize()
    yield
    DatabaseConfig.close()


@pytest.fixture
def patient_service():
    """Provide a fresh PatientService instance for each test."""
    return PatientService()

@pytest.fixture
def dashboard_service():
    """Provide a fresh DashboardService instance for each test."""
    return DashboardService()

@pytest.fixture
def provider_service():
    """Provide a fresh ProviderService instance for each test."""
    return ProviderService()


# ----------------------------------------------------------------
# Patient Lookup by MRN (menu option 1)
# ----------------------------------------------------------------

class TestPatientLookup:
    """Tests for the patient lookup by MRN feature."""

    def test_returns_patient_for_valid_mrn(self, patient_service):
        result = patient_service.get_patient_by_mrn("1000000000")
        assert result is not None
        assert len(result) == 17
        assert result["mrn"] == "1000000000"
        assert result["first_name"] == "Xavier"
        assert result["middle_name"] == "G"
        assert result["last_name"] == "Martin"
        assert result["dob"] == date(1995, 12, 13)
        assert result["gender"] == "M"
        assert result["registration_date"] == date(2025, 9, 20)
        assert result["has_insurance"] == True
        assert result["primary_provider_id"] == 35

    def test_patient_not_found(self, patient_service):
        with pytest.raises(ValueError, match="Patient details not found for MRN 9999999999"):
            patient_service.get_patient_by_mrn("9999999999")

    def test_includes_insurance_info(self, patient_service):
        result = patient_service.get_patient_by_mrn("1000000000")
        assert result["insurance_id"] == 1
        assert result["policy_no"] == "POL000114251"
        assert result["insurance_company"] == "UnitedHealthcare"
        assert result["coverage"] == "Employee health plan"
        assert result["group_no"] == "G75104"
        assert result["copay_amount"] == Decimal(20.00)
        assert result["effective_date"] == datetime(2025, 8, 15, 0, 0, 0, tzinfo=ZoneInfo("America/New_York"))
        assert result["termination_date"] == datetime(2027, 1, 24, 0, 0, 0, tzinfo=ZoneInfo("America/New_York"))

    def test_no_prescription_info(self, patient_service):
        result = patient_service.get_patient_by_mrn("1000000000")
        assert "active_prescriptions" not in result

    def test_includes_active_prescription_info(self, patient_service):
        result = patient_service.get_patient_by_mrn("1000000096")
        assert result["mrn"] == "1000000096"
        assert len(result["active_prescriptions"][0]) == 12
        assert len(result["active_prescriptions"][1]) == 12
        assert result["active_prescriptions"][0]["prescription_id"] == 102
        assert result["active_prescriptions"][0]["mrn"] == "1000000096"
        assert result["active_prescriptions"][0]["medication_id"] == 19
        assert result["active_prescriptions"][0]["date_prescribed"] == datetime(2026, 2, 23, 10, 15, 0, tzinfo=ZoneInfo("America/New_York"))
        assert result["active_prescriptions"][0]["prescription_status"] == "active"
        assert result["active_prescriptions"][0]["max_num_refills"] == 0
        assert result["active_prescriptions"][0]["provider_id"] == 26
        assert result["active_prescriptions"][0]["expiration_date"] == datetime(2026, 3, 25, 10, 15, 0, tzinfo=ZoneInfo("America/New_York"))
        assert result["active_prescriptions"][0]["dosage"] == "650 mg"
        assert result["active_prescriptions"][0]["frequency"] == "every 6 hours as needed"
        assert result["active_prescriptions"][0]["duration"] == "10 days"
        assert result["active_prescriptions"][0]["special_instructions"] == "Do not drive after dosing"
        assert result["active_prescriptions"][1]["prescription_id"] == 144

# ----------------------------------------------------------------
# System Dashboard (menu option 3)
# ----------------------------------------------------------------

class TestSystemDashboard:
    """Tests for the system-wide dashboard feature."""

    def test_returns_metrics(self, dashboard_service):
        metrics = dashboard_service.main()
        assert metrics is not None

    def test_metrics_include_expected_fields(self, dashboard_service):
        metrics = dashboard_service.main()
        assert len(metrics) == 3
        assert "total_patients" in metrics
        assert "prescriptions_this_month" in metrics
        assert "appointments_today" in metrics
        assert metrics["total_patients"] == 110

# ----------------------------------------------------------------
# Provider appointments and lookup by npi (menu options 2 and 4)
# ----------------------------------------------------------------
class TestProviderService:
    """Tests for the provider service feature."""

    def test_returns_provider_info(self, provider_service):
        provider = provider_service.get_provider_by_npi("8000000002")
        assert provider is not None
        assert len(provider) == 6
        assert provider["npi"] == "8000000002"
        assert provider["provider_id"] == 2
        assert provider["first_name"] == "Marcus"
        assert provider["last_name"] == "Reed"
        assert provider["provider_type"] == "Physician"
        assert provider["can_prescribe"] == True

    def test_provider_not_found(self, provider_service):
        with pytest.raises(ValueError, match="No provider found with NPI 9999999999"):
            provider_service.get_provider_by_npi("9999999999")

    def test_returns_appointments_for_provider(self, provider_service):
        appointments = provider_service.show_appointments("3")
        assert appointments is not None
        assert "appointments" in appointments
        assert isinstance(appointments["appointments"], list)
        assert len(appointments["appointments"]) == 2
        assert len(appointments["appointments"][0]) == 7
        assert len(appointments["appointments"][1]) == 7
        assert appointments["appointments"][0]["appointment_id"] == 125
        assert appointments["appointments"][0]["mrn"] == "1000000046"
        assert appointments["appointments"][0]["slot_id"] == 125
        assert appointments["appointments"][0]["appt_type"] == "consultation"
        assert appointments["appointments"][0]["appt_status"] == "under_review"
        assert appointments["appointments"][1]["appointment_id"] == 155
        assert appointments["appointments"][1]["mrn"] == "1000000078"
        assert appointments["appointments"][1]["slot_id"] == 155
        assert appointments["appointments"][1]["appt_type"] == "urgent_care"
        assert appointments["appointments"][1]["appt_status"] == "completed"
        
    def test_provider_appointments_not_found(self, provider_service):
        with pytest.raises(ValueError, match="No appointments found for provider with ID 100"):
            provider_service.show_appointments("100")