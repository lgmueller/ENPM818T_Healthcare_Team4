from models.provider import Provider
from repositories.base_repository import BaseRepository


class ProviderRepository(BaseRepository):

    # For Fourth CLI menu: "Lookup provider by NPI"
    def find_by_npi(self, npi):
        row = self._fetch_one(
            """
            SELECT provider_id, first_name, last_name,
                provider_type, npi, can_prescribe
            FROM provider
            WHERE npi = %s
            """,
            (npi,)
        )
        return Provider.from_row(row) if row else None
    
    
    # EXTRA methods for completeness - not used in CLI but useful for future extensions

    def find_by_id(self, provider_id):
        row = self._fetch_one(
            """
            SELECT provider_id, first_name, last_name,
                provider_type, npi, can_prescribe
            FROM provider
            WHERE provider_id = %s
            """,
            (provider_id,)
        )
        return Provider.from_row(row) if row else None
    
    def find_all(self, limit=20, offset=0):
        rows = self._fetch_all(
            """
            SELECT provider_id, first_name, last_name,
                provider_type, npi, can_prescribe
            FROM provider
            LIMIT %s OFFSET %s
            """,
            (limit, offset)
        )
        return [Provider.from_row(row) for row in rows]
    