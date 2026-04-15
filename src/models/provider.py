from dataclasses import dataclass

@dataclass
class Provider:
    provider_id: int
    first_name: str
    last_name: str
    provider_type: str
    npi: str | None = None
    can_prescribe: bool = False

    @classmethod
    def from_row(cls, row: dict | None):
        if not row:
            return None
        return cls(
            provider_id=row["provider_id"],
            first_name=row["first_name"],
            last_name=row["last_name"],
            provider_type=row["provider_type"],
            npi=row.get("npi"),
            can_prescribe=row.get("can_prescribe", False)
        )