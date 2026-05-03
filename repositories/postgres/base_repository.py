from psycopg.rows import dict_row
from config.database import DatabaseConfig

class BaseRepository:

    def _fetch_one(self, query, params):
        with DatabaseConfig.get_connection() as conn:
            with conn.cursor(row_factory=dict_row) as cur:
                cur.execute(query, params)
                return cur.fetchone()

    def _fetch_all(self, query, params):
        with DatabaseConfig.get_connection() as conn:
            with conn.cursor(row_factory=dict_row) as cur:
                cur.execute(query, params)
                return cur.fetchall()

    def _execute(self, query, params):
        with DatabaseConfig.get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute(query, params)
            conn.commit()