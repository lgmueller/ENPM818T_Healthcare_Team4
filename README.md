# Healthcare Management System - for GP2

This project implements a comprehensive healthcare database system using PostgreSQL and Python. It translates a conceptual healthcare design into a fully functional database with realistic synthetic data, supports clinical and administrative queries, and provides a menu-driven command-line interface for interaction.

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

⚠️ **Important:** PostgreSQL does not automatically switch to the newly created database. You must explicitly connect to it before running the schema.


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

## ▶️ Running the Application

Run the CLI interface:

```bash
python src/main.py
```

You will see a menu-driven interface for:

* Patient lookup
* Provider appointments
* Dashboard analytics
* Provider search by NPI

---

## 🧪 Running Unit Tests

```bash
pytest
```

---

## 🏗️ Project Structure

```
ENPM818T_Healthcare_Team4/
├──src/
│    ├── config/             # Database connection details
│    ├── models/             # Dataclass for entities
│    ├── repositories/       # SQL queries and CRUD operations
│    ├── services/           # Business logic layer
│    ├── cli/                # CLI interface
│    ├── main.py             # Starting point of the application
│
├── postgresql/
│    ├── schema.sql          # Database schema
│    ├── data.sql            # Sample data
│    ├── queries.sql         # Sample queries
│
├── tests/
├── .env.example              # Environment variables store
├── requirements.txt
├── team_contributions.md   # Contributions made by each team member
└── README.md
```

---

## 🧠 Design Overview

* **Models**: Represent database tables using Python dataclasses
* **Repositories**: Handle SQL queries and database interactions
* **Services**: Contain business logic and orchestrate repositories
* **CLI**: User interface for interacting with the system

---

## ⚠️ Notes

* Ensure PostgreSQL is running before starting the application
* Database credentials must match your `.env` configuration
* The application uses connection pooling via psycopg

---

## 👩‍💻 Contributors

* Lily
* Nishtha
* Rozan
* Simran

---
