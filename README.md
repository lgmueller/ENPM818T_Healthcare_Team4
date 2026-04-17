# Healthcare Management System - for GP2

This project implements a comprehensive healthcare database system using PostgreSQL and Python. It translates a conceptual healthcare design into a fully functional database with realistic synthetic data, supports clinical and administrative queries, and provides a menu-driven command-line interface for interaction.

![Python](https://img.shields.io/badge/Python-3.10+-blue)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Database-blue)
![CLI](https://img.shields.io/badge/Interface-CLI-green)

---

## 📑 Table of Contents

* [Project Scope](#-project-scope)
* [Learning Objectives](#-learning-objectives)
* [Prerequisites](#-prerequisites)
* [Setup Instructions](#️-setup-instructions)
  * [Create PostgreSQL Database](#2-create-postgresql-database)
  * [Load Schema and Data](#3-load-schema-and-data)
  * [Configure Environment Variables](#4-configure-environment-variables)
  * [Install Dependencies](#5-install-dependencies)
* [Design Overview](#-design-overview)
* [Features](#-features)
* [Project Structure](#️-project-structure)
* [Running the Application](#️-running-the-application)
* [Running Tests](#-running-unit-tests)
* [Example Run Screenshots](#-example-run-screenshots)
* [Database Design Highlights](#-database-design-highlights)
* [Final Notes](#️-final-notes)
* [Contributors](#-contributors)

---

## 🎯 Project Scope

* Implement GP1 healthcare database design in PostgreSQL
* Generate realistic synthetic healthcare data
* Write SQL queries supporting clinical and administrative operations
* Build a Python command-line application with a menu-driven interface

---

## 🎓 Learning Objectives

By completing this project, we achieved the following:

* Translate healthcare designs into physical PostgreSQL schemas
* Write DDL statements with tables, constraints, indexes, and triggers
* Generate and validate synthetic healthcare data
* Develop clinical, financial, and operational SQL queries
* Integrate PostgreSQL with Python using psycopg3
* Design repository and service layer architecture
* Build a menu-driven CLI application

---

## 📋 Prerequisites

Make sure the following are installed on your system:

* **Python 3.9+**
* **PostgreSQL 13+**
* `pip` (Python package manager)

---

## ⚙️ Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/lgmueller/ENPM818T_Healthcare_Team4
cd ENPM818T_Healthcare_Team4
```

---

### 2. Create PostgreSQL Database

Open PostgreSQL:

```sql
psql -U postgres
```

Create the database:

```sql
CREATE DATABASE healthcare_db;
```

Exit psql:

```sql
\q
```

---

### 3. Load Schema and Data

⚠️ **Important:** PostgreSQL does not automatically switch to a newly created database. You must explicitly connect to it before running the schema.

Run the schema file on the correct database:

```sql
psql -U postgres -d healthcare_db -f postgresql/schema.sql
```

(Optional) Load sample data:

```sql
psql -U postgres -d healthcare_db -f postgresql/data.sql
```

(Optional, only after loading data) Load sample queries:
```sql
psql -U postgres -d healthcare_db -f postgresql/queries.sql
```

---

### 4. Configure Environment Variables

PostgreSQL authentication depends on your local setup.

#### Option 1: Using Default System User (Recommended for Mac/Linux)

If your PostgreSQL installation uses your system username (common on Mac), you can omit `DB_USER` and `DB_PASSWORD` from the `.env` file:

```env
DB_NAME=healthcare_db
DB_HOST=localhost
DB_PORT=5432
```

In this case, the application will connect using your OS user.

---

#### Option 2: Using Explicit Credentials

If your PostgreSQL setup requires a username and password, specify them:

```env
DB_NAME=healthcare_db
DB_USER=<your_username_here>
DB_PASSWORD=<your_password_here>
DB_HOST=localhost
DB_PORT=5432
```

---

#### ⚠️ Important

* Do NOT leave `DB_USER` or `DB_PASSWORD` empty (e.g., `DB_USER=`)
* Either provide valid values or omit them entirely
* Incorrect configuration may result in errors such as:

  * `role "postgres" does not exist`
  * `role "password=" does not exist`

---

### 5. Install Dependencies

```bash
pip install -r requirements.txt
```

---

## 🧠 Design Overview

* **Models**: Represent database tables using Python dataclasses
* **Repositories**: Handle SQL queries and database interactions
* **Services**: Contain business logic and orchestrate repositories
* **CLI**: User interface for interacting with the system

This layered architecture ensures separation of concerns, maintainability, and scalability of the application.

---

## ✨ Features

- Retrieve patient records by MRN  
- View appointments for a specific provider  
- Access a dashboard with aggregated system metrics  
- Lookup provider details using NPI
- Supports modular repository-service architecture for scalability

---

## 🏗️ Project Structure

```
ENPM818T_Healthcare_Team4/
├──src/
│    ├── models/                    # Data classes for entities
│    ├── config/                    # Database connection details
│    ├── repositories/              # SQL queries and CRUD operations
│    ├── services/                  # Business logic layer
│    ├── cli/                       # CLI interface
│    └── main.py                    # Starting point of the application
│
├── postgresql/
│    ├── schema.sql                 # Database schema
│    ├── data.sql                   # Sample data
│    └── queries.sql                # Sample queries
│
├── tests/
│    ├── test_services.py           # Testing scripts for services
│    └── test_repositories.py       # Testing scripts for Repositories
├── .env.example                    # Example Environment variables store
├── requirements.txt
├── team_contributions.md           # Contributions made by each team member
└── README.md
```

---

## ▶️ Running the Application

Run the CLI interface:

```bash
python src/main.py
```

The CLI provides the following options:

* Patient lookup
* Provider appointments
* Dashboard analytics
* Provider search by NPI

---

## 🧪 Running Unit Tests

Make sure you are in the project root directory and your virtual environment is activated.

### 1. Install test dependencies

```bash
pip install pytest
```

---

### 2. Run all tests

```bash
PYTHONPATH=src pytest -v
```

---

### 3. Run a specific test file

```bash
PYTHONPATH=src pytest tests/test_repositories.py -v
```

---

### ⚠️ Notes

* Ensure PostgreSQL is running before executing tests
* The database must be initialized with `schema.sql` and `data.sql`
* Environment variables in `.env` must be correctly configured
* If you encounter import errors, ensure `PYTHONPATH=src` is set as shown above

---

### 📊 Test Coverage

The project includes a comprehensive unit test suite covering database operations and core application logic.

* **Total Coverage:** 90%
* **Repository Layer:** 100% coverage across all CRUD operations
* **Test Framework:** pytest with coverage reporting

This ensures correctness and reliability of all database interactions.

The coverage results can be reproduced by running:

```bash
PYTHONPATH=src pytest tests/ --cov=src --cov-report=html
```

This command generates an HTML coverage report in the `htmlcov/` directory.

---

## 📸 Example Run Screenshots

Screenshots demonstrating CLI interactions and system functionality are available in the [screenshots folder](./screenshots).

---

## 🏥 Database Design Highlights

- Enforced healthcare identifiers:
  - MRN (10-digit unique identifier)
  - NPI (10-digit provider identifier)
  - DEA numbers (2 letters + 7 digits for prescribing providers)

- Appointment scheduling system:
  - Provider availability stored separately
  - One-to-one booking enforced via UNIQUE(slot_id)

- Data integrity:
  - CHECK constraints for SSN, phone numbers, ZIP codes
  - Foreign key relationships across all major entities

- Triggers:
  - Automatic `updated_at` timestamp updates for key tables

- Controlled substances:
  - Identified via medication.schedule
  - DEA linkage handled via provider DEA records
  - Cross-table enforcement documented (PostgreSQL limitation)

---

## 🧪 Synthetic Data

All data in this project is fully synthetic and generated to simulate realistic healthcare scenarios.

- No real patient or provider data is used
- MRNs, NPIs, DEA numbers follow valid formats
- Data distributions mimic real-world usage:
  - Appointment statuses (completed, scheduled, no-show)
  - Insurance coverage patterns
  - Prescription usage and controlled substances
  - Lab results including abnormal values
  
⚠️ Note: SSNs are stored as 9-digit numeric strings to satisfy schema constraints.

---

## 📊 SQL Queries

The project includes 15 SQL queries covering:

- Clinical workflows (patient care coordination, medication safety)
- Operational insights (provider workload, appointment breakdown)
- Financial analysis (insurance coverage, prescription costs)

Each query includes:
- Clinical or business context
- Tables used
- Complexity features (joins, aggregates, filtering)
- Sample outputs based on synthetic data

⚠️ Note: Queries were adjusted to reflect the synthetic dataset.

---

## ⚠️ Final Notes

* Ensure PostgreSQL is running before starting the application
* Do not include empty values for `DB_USER` or `DB_PASSWORD` in `.env`; omit them entirely if not used
* Always connect to the correct database (`healthcare_db`) before running `schema.sql`
* If connection errors occur (e.g., `role "None" does not exist`), verify environment variables and connection configuration
* The application uses connection pooling via psycopg, so database settings must allow multiple connections

---

## 👩‍💻 Contributors

* Lillian Mueller (UID: )
* Nishtha Gupta (UID: 122031197)
* Rozan Sonnadara (UID: 122359826)
* Simran Mohapatra (UID: 121957467)

To check individual contributions, please check [Team Contributions File](./team_contributions.md)
