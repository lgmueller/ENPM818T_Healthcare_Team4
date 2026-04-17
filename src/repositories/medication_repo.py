from src.models.medication import Medication
from src.repositories.base_repository import BaseRepository


class MedicationRepository(BaseRepository):

    def find_all(self):
        rows = self._fetch_all(
            "SELECT * FROM medication ORDER BY medication_id",
            ()
        )
        return [Medication.from_row(r) for r in rows]