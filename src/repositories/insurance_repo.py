from models.insurance import Insurance
from repositories.base_repository import BaseRepository


class InsuranceRepository(BaseRepository):

    def find_by_id(self, insurance_id):
        row = self._fetch_one(
            """
            SELECT 
                insurance_id, mrn, policy_no, insurance_company, 
                coverage, group_no, copay_amount, effective_date, 
                termination_date 
            FROM insurance
            WHERE insurance_id = %s
            """,
            (insurance_id,)
        )
        return Insurance.from_row(row) if row else None

    def find_all(self, limit=20, offset=0):
        rows = self._fetch_all(
            """
            SELECT 
                insurance_id, mrn, policy_no, insurance_company, 
                coverage, group_no, copay_amount, effective_date, 
                termination_date 
            FROM insurance
            ORDER BY insurance_id
            LIMIT %s OFFSET %s
            """,
            (limit, offset)
        )
        return [Insurance.from_row(r) for r in rows]
    
    def find_by_mrn(self, mrn):
        row = self._fetch_one(
            """
            SELECT 
                insurance_id, mrn, policy_no, insurance_company, 
                coverage, group_no, copay_amount, effective_date, 
                termination_date 
            FROM insurance
            WHERE mrn = %s
            """,
            (mrn,)
        )
        return Insurance.from_row(row) if row else None