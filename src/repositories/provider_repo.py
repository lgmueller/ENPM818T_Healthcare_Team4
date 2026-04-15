from models.provider import Provider
from repositories.base_repository import BaseRepository


class ProviderRepository(BaseRepository):


    # For Fourth CLI menu: "Lookup provider by NPI"
    def find_by_npi(self, npi):
        row = self._fetch_one(
            """
            SELECT provider_id, first_name, middle_name, last_name,
                provider_type, npi, can_prescribe
            FROM provider
            WHERE npi = %s
            """,
            (npi,)
        )
        return Provider.from_row(row) if row else None
    