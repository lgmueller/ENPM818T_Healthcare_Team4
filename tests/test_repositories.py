"""
Test suite for repository classes.
pytest tests/ --cov=src --cov-report=html
"""

from datetime import date

import pytest
from config.database import DatabaseConfig

# ----------------------------------------------------------------
from repositories.patient_repo import PatientRepository
from repositories.prescription_repo import PrescriptionRepository
from repositories.appointment_repo import AppointmentRepository
from repositories.facility_repo import FacilityRepository
from repositories.insurance_repo import InsuranceRepository
from repositories.provider_repo import ProviderRepository
from repositories.medication_repo import MedicationRepository

from models.patient import Patient
from models.appointment import Appointment
from models.prescription import Prescription
from models.facility import Facility
from models.insurance import Insurance
from models.provider import Provider
from models.medication import Medication
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
def patient_repo():
    """Provide a fresh PatientRepository instance for each test."""
    return PatientRepository()


@pytest.fixture
def prescription_repo():
    """Provide a fresh PrescriptionRepository instance for each test."""
    return PrescriptionRepository()

@pytest.fixture
def appointment_repo():
    """Provide a fresh AppointmentRepository instance for each test."""
    return AppointmentRepository()

@pytest.fixture
def facility_repo():
    """Provide a fresh FacilityRepository instance for each test."""
    return FacilityRepository()

@pytest.fixture
def insurance_repo():
    """Provide a fresh InsuranceRepository instance for each test."""
    return InsuranceRepository()

@pytest.fixture
def medication_repo():
    """Provide a fresh MedicationRepository instance for each test."""
    return MedicationRepository()

@pytest.fixture
def provider_repo():
    """Provide a fresh ProviderRepository instance for each test."""
    return ProviderRepository()


# ----------------------------------------------------------------
# PatientRepository Tests
# ----------------------------------------------------------------

class TestPatientRepository:
    """Tests for PatientRepository CRUD operations."""

    def test_find_by_id_returns_entity(self, patient_repo):
        result = patient_repo.find_by_id("1000000000")
        assert result is not None
        assert result.mrn == "1000000000"
        assert result.first_name == "Xavier"
        assert result.last_name == "Martin"
        assert result.dob == date(1995, 12, 13)
        assert result.middle_name == "G"
        assert result.gender == "M"
        assert result.primary_provider_id == 35
        assert result.has_insurance == True
        assert result.registration_date == date(2025, 9, 20)

    def test_find_by_id_returns_none_for_missing(self, patient_repo):
        result = patient_repo.find_by_id("99999")
        assert result is None

    def test_find_all_returns_list_with_limit_boundary(self, patient_repo):
        results = patient_repo.find_all(limit=5, offset=0)
        assert isinstance(results, list)
        assert len(results) <= 5
        assert len(results) > 0

    def test_find_all_respects_offset(self, patient_repo):
        page1 = patient_repo.find_all(limit=5, offset=0)
        page2 = patient_repo.find_all(limit=5, offset=5)

        if len(page1) > 0 and len(page2) > 0:
            page1_ids = {p.mrn for p in page1}
            page2_ids = {p.mrn for p in page2}
            assert page1_ids.isdisjoint(page2_ids)

    def test_create_and_retrieve(self, patient_repo):
        new_patient = Patient(
            mrn="9999999999",
            first_name="Test",
            last_name="Patient",
            dob="1990-01-01",
            registration_date="2024-01-01"
        )

        created = patient_repo.create(new_patient)

        assert created.mrn is not None
        retrieved = patient_repo.find_by_id(created.mrn)
        assert retrieved is not None
        assert retrieved.mrn == "9999999999"

        patient_repo.delete(created.mrn)

    def test_update_persists_changes(self, patient_repo):
        original = patient_repo.find_by_id("1000000009")
        original.first_name = "Michael"

        patient_repo.update(original)
        updated = patient_repo.find_by_id("1000000009")

        assert updated.first_name == "Michael"

        original.first_name = "Ethan"
        patient_repo.update(original)

    def test_delete_removes_record(self, patient_repo):
        new_patient = Patient(
            mrn="9999999999",
            first_name="Test",
            last_name="Patient",
            dob="1990-01-01",
            registration_date="2024-01-01"
        )

        temp = patient_repo.create(new_patient)
        assert patient_repo.find_by_id(temp.mrn) is not None

        patient_repo.delete(temp.mrn)

        assert patient_repo.find_by_id(temp.mrn) is None

    def test_patient_count(self, patient_repo):
        result = patient_repo.count_patients()
        assert result == 110

    def test_create_duplicate_mrn_raises_error(self, patient_repo):
        existing = patient_repo.find_by_id("1000000000")
        with pytest.raises(Exception, match="already exists"):
            patient_repo.create(Patient(mrn=existing.mrn, 
                first_name="Test",
                last_name="Patient",
                dob="1990-01-01",
                registration_date="2024-01-01"))
            
    def test_create_invalid_fk_raises_error(self, prescription_repo):
        with pytest.raises(Exception, match="violates foreign key constraint"):
            prescription_repo.create(Prescription(prescription_id=99999, mrn=99999, provider_id=10, medication_id=1, date_prescribed="2024-01-01", prescription_status="active", max_num_refills=3))


# ----------------------------------------------------------------
# ProviderRepository Tests
# ----------------------------------------------------------------

class TestProviderRepository:
    """Tests for ProviderRepository operations."""

    def test_find_by_npi_returns_entity(self, provider_repo):
        result = provider_repo.find_by_npi("8000000006")
        assert result is not None
        assert result.provider_id == 6
        assert result.first_name == "James"
        assert result.last_name == "Carter"
        assert result.provider_type == "Physician"
        assert result.can_prescribe == True

    def test_find_by_npi_returns_none_for_missing(self, provider_repo):
        result = provider_repo.find_by_npi("9999999999")
        assert result is None


# ----------------------------------------------------------------
# PrescriptionRepository Tests
# ----------------------------------------------------------------

class TestPrescriptionRepository:
    """Tests for PrescriptionRepository operations."""

    def test_monthly_prescription_count(self, prescription_repo):
        result = prescription_repo.count_monthly_prescriptions()
        assert result == 2
    
    def test_find_by_id_returns_entity(self, prescription_repo):
        result = prescription_repo.find_by_id(1)
        assert result is not None
        assert result.mrn == "1000000098"
        assert result.provider_id == 12
        assert result.medication_id == 39
        assert result.date_prescribed.date() == date(2026, 1, 31)
        assert result.prescription_status == "active"
        assert result.max_num_refills == 0
        assert result.dosage == "4 mg"
        assert result.frequency == "every 8 hours as needed nausea"
        assert result.expiration_date.date() == date(2026, 3, 2)
        assert result.special_instructions == "Finish entire course"

    def test_find_by_id_returns_none_for_missing(self, prescription_repo):
        result = prescription_repo.find_by_id("99999")
        assert result is None

    def test_find_all_returns_list_with_limit_boundary(self, prescription_repo):
        results = prescription_repo.find_all(limit=5, offset=0)
        assert isinstance(results, list)
        assert len(results) <= 5
        assert len(results) > 0

    def test_find_all_respects_offset(self, prescription_repo):
        page1 = prescription_repo.find_all(limit=5, offset=0)
        page2 = prescription_repo.find_all(limit=5, offset=5)

        if len(page1) > 0 and len(page2) > 0:
            page1_ids = {p.mrn for p in page1}
            page2_ids = {p.mrn for p in page2}
            assert page1_ids.isdisjoint(page2_ids)

    # def test_create_and_retrieve(self, prescription_repo):
    #     new_prescription = Prescription(
    #         mrn="1000000022",
    #         medication_id=39,
    #         date_prescribed="2024-01-01",
    #         prescription_status="active",
    #         max_num_refills=2,
    #         provider_id=10
    #     )

    #     created = prescription_repo.create(new_prescription)

    #     assert created.mrn is not None
    #     retrieved = prescription_repo.find_by_id(created.prescription_id)
    #     assert retrieved is not None
    #     assert retrieved.mrn == "1000000022"

    #     prescription_repo.delete(created.prescription_id)

    def test_update_persists_changes(self, prescription_repo):
        original = prescription_repo.find_by_id("8")
        original.dosage = "8 mg"

        prescription_repo.update(original)
        updated = prescription_repo.find_by_id("8")

        assert updated.dosage == "8 mg"

        original.dosage = "75 mg"
        prescription_repo.update(original)

    # def test_delete_removes_record(self, prescription_repo):
    #     new_prescription = Prescription(
    #         mrn="1000000022",
    #         medication_id=39,
    #         date_prescribed="2024-01-01",
    #         prescription_status="active",
    #         max_num_refills=2,
    #         provider_id=10
    #     )

    #     temp = prescription_repo.create(new_prescription)
    #     assert prescription_repo.find_by_id(temp.prescription_id) is not None

    #     prescription_repo.delete(temp.prescription_id)

    #     assert prescription_repo.find_by_id(temp.prescription_id) is None
            
    def test_find_active_prescriptions(self, prescription_repo):
        results = prescription_repo.find_active_prescriptions("1000000022")
        assert isinstance(results, list)
        assert len(results) == 4
        assert results[0].prescription_id == 12
        assert results[0].mrn == "1000000022"
        assert results[0].provider_id == 35
        assert results[0].medication_id == 26
        assert results[0].date_prescribed.date() == date(2025, 10, 14)
        assert results[0].prescription_status == "active"
        assert results[0].max_num_refills == 2
        assert results[0].dosage == "2 sprays each nostril"
        assert results[0].frequency == "once daily"
        assert results[0].expiration_date.date() == date(2025, 11, 13)
        assert results[0].special_instructions == "Monitor blood pressure"
        assert results[1].prescription_id == 42
        assert results[2].prescription_id == 86
        assert results[3].prescription_id == 151

# ----------------------------------------------------------------
# MedicationRepository Tests
# ----------------------------------------------------------------

class TestMedicationRepository:
    """Tests for MedicationRepository operations."""

    def test_find_all_returns_list(self, medication_repo):
        results = medication_repo.find_all()
        assert isinstance(results, list)
        assert len(results) == 36
        assert results[0].medication_id == 10
        assert results[0].medication_name == "Lisinopril"
        assert results[0].schedule is None


# ----------------------------------------------------------------
# FacilityRepository Tests
# ----------------------------------------------------------------

class TestFacilityRepository:
    """Tests for FacilityRepository operations."""

    def test_find_all_returns_list(self, facility_repo):
        results = facility_repo.find_all()
        assert isinstance(results, list)
        assert len(results) == 16
        assert results[0].facility_id == 1
        assert results[0].facility_name == "Capital Regional Medical Center"
        assert results[0].facility_type == "hospital"

# ----------------------------------------------------------------
# InsuranceRepository Tests
# ----------------------------------------------------------------

class TestInsuranceRepository:
    """Tests for InsuranceRepository operations."""

    def test_find_by_id_returns_entity(self, insurance_repo):
        result = insurance_repo.find_by_id(1)
        assert result is not None
        assert result.insurance_id == 1
        assert result.mrn == "1000000000"
        assert result.policy_no == "POL000114251"
        assert result.insurance_company == "UnitedHealthcare"
        assert result.coverage == "Employee health plan"
        assert result.group_no == "G75104"
        assert result.copay_amount == 20.00
        assert result.effective_date.date() == date(2025, 8, 15)
        assert result.termination_date.date() == date(2027, 1, 24)

    def test_find_by_id_returns_none_for_missing(self, insurance_repo):
        result = insurance_repo.find_by_id(99999)
        assert result is None

    def test_find_all_returns_list_with_limit_boundary(self, insurance_repo):
        results = insurance_repo.find_all(limit=5, offset=0)
        assert isinstance(results, list)
        assert len(results) <= 5
        assert len(results) > 0

    def test_find_all_respects_offset(self, insurance_repo):
        page1 = insurance_repo.find_all(limit=5, offset=0)
        page2 = insurance_repo.find_all(limit=5, offset=5)

        if len(page1) > 0 and len(page2) > 0:
            page1_ids = {p.mrn for p in page1}
            page2_ids = {p.mrn for p in page2}
            assert page1_ids.isdisjoint(page2_ids)

    def test_find_by_mrn_returns_entity(self, insurance_repo):
        result = insurance_repo.find_by_mrn("1000000022")
        assert result is not None
        assert result.insurance_id == 25
        assert result.mrn == "1000000022"
        assert result.policy_no == "POL002311208"
        assert result.insurance_company == "Humana"
        assert result.coverage == "Dependent coverage"
        assert result.group_no == "G45535"
        assert result.copay_amount == 15.00
        assert result.effective_date.date() == date(2025, 8, 20)
        assert result.termination_date.date() == date(2026, 9, 15)


# ----------------------------------------------------------------
# AppointmentRepository Tests
# ----------------------------------------------------------------

class TestAppointmentRepository:
    """Tests for AppointmentRepository operations."""

    def test_find_by_provider(self, appointment_repo):
        result = appointment_repo.find_by_provider(12)
        assert len(result) == 2
        assert result[0].appointment_id == 31
        assert result[0].mrn == "1000000101"
        assert result[0].slot_id == 31
        assert result[0].appt_type == "follow_up"
        assert result[0].appt_status == "completed"
        assert result[1].appointment_id == 114

    def test_find_by_id_returns_entity(self, appointment_repo):
        result = appointment_repo.find_by_id(1)
        assert result is not None
        assert result.appointment_id == 1
        assert result.mrn == "1000000067"
        assert result.slot_id == 1
        assert result.appt_type == "procedure"
        assert result.appt_status == "scheduled"
        assert result.visit_reason == "Diabetes monitoring"
        
    def test_find_by_id_returns_none_for_missing(self, appointment_repo):
        result = appointment_repo.find_by_id(99999)
        assert result is None

    def test_find_all_returns_list_with_limit_boundary(self, appointment_repo):
        results = appointment_repo.find_all(limit=5, offset=0)
        assert isinstance(results, list)
        assert len(results) <= 5
        assert len(results) > 0

    def test_find_all_respects_offset(self, appointment_repo):
        page1 = appointment_repo.find_all(limit=5, offset=0)
        page2 = appointment_repo.find_all(limit=5, offset=5)

        if len(page1) > 0 and len(page2) > 0:
            page1_ids = {p.mrn for p in page1}
            page2_ids = {p.mrn for p in page2}
            assert page1_ids.isdisjoint(page2_ids)

    # def test_create_and_retrieve(self, appointment_repo):
    #     new_appointment = Appointment(
    #         mrn="1000000022",
    #         slot_id=39,
    #         appt_type="telehealth",
    #         appt_status="confirmed"
    #     )

    #     created = appointment_repo.create(new_appointment)

    #     assert created.mrn is not None
    #     retrieved = appointment_repo.find_by_id(created.appointment_id)
    #     assert retrieved is not None
    #     assert retrieved.mrn == "1000000022"

    #     appointment_repo.delete(created.appointment_id)

    def test_update_persists_changes(self, appointment_repo):
        original = appointment_repo.find_by_id(8)
        original.appt_type = "telehealth"

        appointment_repo.update(original)
        updated = appointment_repo.find_by_id(8)

        assert updated.appt_type == "telehealth"

        original.dosage = "new_patient"
        appointment_repo.update(original)

    # def test_delete_removes_record(self, appointment_repo):
    #     new_appointment = Appointment(
    #         mrn="1000000022",
    #         slot_id=39,
    #         appt_type="telehealth",
    #         appt_status="confirmed"
    #     )

    #     temp = appointment_repo.create(new_appointment)
    #     assert appointment_repo.find_by_id(temp.appointment_id) is not None

    #     appointment_repo.delete(temp.appointment_id)

    #     assert appointment_repo.find_by_id(temp.appointment_id) is None
            
    def test_find_by_patient(self, appointment_repo):
        results = appointment_repo.find_by_patient("1000000047")
        assert isinstance(results, list)
        assert len(results) == 3
        assert results[0].appointment_id == 3
        assert results[0].mrn == "1000000047"
        assert results[0].slot_id == 3
        assert results[0].appt_type == "urgent_care"
        assert results[0].appt_status == "under_review"
        assert results[0].visit_reason == "Medication management"
        assert results[1].appointment_id == 71
        assert results[2].appointment_id == 94
