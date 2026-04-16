"""
ENPM818T_Healthcare_Team4/main.py
Entry point. Responsibilities:
  1. Initialize the connection pool (once at startup).
  2. Start the CLI loop.
  3. Close the pool on exit.
"""

from config.database import DatabaseConfig
from cli import main as cli_main


def main() -> None:
    try:
        DatabaseConfig.initialize()
    except Exception as e:
        print(f"Failed to connect to the database: {e}")
        raise SystemExit(1)
    try:
        cli_main.main()
    finally:
        DatabaseConfig.close()



if __name__ == "__main__":
    main()