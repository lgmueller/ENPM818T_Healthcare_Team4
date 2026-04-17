from models.facility import Facility
from repositories.base_repository import BaseRepository


class FacilityRepository(BaseRepository):

    def find_all(self):
        rows = self._fetch_all(
            "SELECT * FROM facility ORDER BY facility_id",
            ()
        )
        return [Facility.from_row(r) for r in rows]