from dataclasses import dataclass

@dataclass
class Provider:
    provider_id: int
    first_name: str
    last_name: str

    @classmethod
    def from_row(cls, row: dict | None):
        if not row:
            return None
        return cls(
            provider_id=row["provider_id"],
            first_name=row["first_name"],
            last_name=row["last_name"]
        )