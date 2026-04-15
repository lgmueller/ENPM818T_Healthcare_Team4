from models.provider import Provider
from repositories.base_repository import BaseRepository


class ProviderRepository(BaseRepository):

    def find_by_id(self, provider_id):
        row = self._fetch_one(
            "SELECT provider_id, first_name, last_name, provider_type, npi, can_prescribe FROM provider WHERE provider_id = %s",
            (provider_id,)
        )
        return Provider.from_row(row) if row else None

    def find_all(self, limit=20, offset=0):
        rows = self._fetch_all(
            """
            SELECT provider_id, first_name, last_name, provider_type, npi, can_prescribe
            FROM provider
            ORDER BY provider_id
            LIMIT %s OFFSET %s
            """,
            (limit, offset)
        )
        return [Provider.from_row(r) for r in rows]