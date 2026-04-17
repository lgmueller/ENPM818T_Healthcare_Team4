"""
ENPM818T_Healthcare_Team4/src/config/database.py
Defines DatabaseConfig class to manage PostgreSQL connection pool using psycopg_pool.
"""

import os
import psycopg_pool
from dotenv import load_dotenv

load_dotenv()

class DatabaseConfig:
    _pool: psycopg_pool.ConnectionPool | None = None

    @classmethod
    def _conninfo(cls) -> str:
        parts = [
            f"host={os.getenv('DB_HOST', 'localhost')}",
            f"port={os.getenv('DB_PORT', '5432')}",
            f"dbname={os.getenv('DB_NAME', 'healthcare_db')}",
        ]

        # Optionally include user and password if they are set in the environment variables
        user = os.getenv("DB_USER")
        password = os.getenv("DB_PASSWORD")

        # Only include user and password in the connection string if they are provided
        if user:
            parts.append(f"user={user}")

        if password:
            parts.append(f"password={password}")

        return " ".join(parts)

    @classmethod
    def initialize(cls) -> None:
        """Open the pool. Call once at application startup in main.py."""
        cls._pool = psycopg_pool.ConnectionPool(
            conninfo=cls._conninfo(),
            min_size=2,
            max_size=10,
            open=True,
        )

    @classmethod
    def get_connection(cls):
        """
        Borrow a connection from the pool.
        """
        if cls._pool is None:
            cls.initialize()
        return cls._pool.connection()

    @classmethod
    def close(cls) -> None:
        """Shut down the pool. Call once at application exit in main.py."""
        if cls._pool is not None:
            cls._pool.close()
            cls._pool = None