# Project Management Database Schema Documentation

## Overview

This document provides comprehensive information about the database schema for the Project Management Control Protocol (PMCP) system. The schema is designed to support a complete project management workflow with clients, projects, cycles, and issues.

## Entity Relationship Diagram

```
┌─────────────┐       ┌─────────────┐       ┌─────────────┐       ┌─────────────┐
│   Clients   │       │   Projects  │       │    Cycles   │       │    Issues   │
├─────────────┤       ├─────────────┤       ├─────────────┤       ├─────────────┤
│ id          │       │ id          │       │ id          │       │ id          │
│ name        │◄──┐   │ title       │◄──┐   │ name        │◄──┐   │ title       │
│ logo        │   │   │ client_id   │   │   │ project_id  │   │   │ description │
│ created_at  │   │   │ description │   │   │ start_date  │   │   │ status      │
│ updated_at  │   │   │ created_at  │   │   │ end_date    │   │   │ priority    │
└─────────────┘   │   │ updated_at  │   │   │ status      │   │   │ estimate    │
                  │   └─────────────┘   │   │ created_at  │   │   │ due_date    │
                  │                     │   │ updated_at  │   │   │ project_id  │
                  │                     │   └─────────────┘   │   │ cycle_id    │
                  │                     │                     │   │ assignee_id  │
                  │                     │                     │   │ created_at   │
                  │                     │                     │   │ updated_at   │
                  └─────────────────────┘─────────────────────┘   └─────────────┘
                                                                        │
                                                                        │
                  ┌─────────────┐                               ┌───────┴───────┐
                  │     Tags    │                               │  Issue Tags   │
                  ├─────────────┤                               ├───────────────┤
                  │ id          │◄──────────────────────────────┤ issue_id      │
                  │ name        │                               │ tag_id        │
                  │ color       │                               └───────────────┘
                  └─────────────┘                                       ▲
                                                                        │
                                                                        │
                  ┌─────────────┐                                       │
                  │   Comments  │                                       │
                  ├─────────────┤                                       │
                  │ id          │                                       │
                  │ issue_id    │───────────────────────────────────────┘
                  │ user_id     │
                  │ content     │
                  │ created_at  │
                  └─────────────┘
```

## Tables

### Clients

Stores information about clients who own projects.

| Column      | Type                          | Description                           |
|-------------|-------------------------------|---------------------------------------|
| id          | SERIAL                        | Primary key                           |
| name        | VARCHAR(255)                  | Client name (required)                |
| logo        | TEXT                          | URL or path to client logo            |
| created_at  | TIMESTAMP WITH TIME ZONE      | Creation timestamp                    |
| updated_at  | TIMESTAMP WITH TIME ZONE      | Last update timestamp                 |

### Projects

Represents projects that belong to clients and contain issues.

| Column      | Type                          | Description                           |
|-------------|-------------------------------|---------------------------------------|
| id          | SERIAL                        | Primary key                           |
| title       | VARCHAR(255)                  | Project title (required)              |
| client_id   | INTEGER                       | Foreign key to clients.id             |
| description | TEXT                          | Project description                   |
| created_at  | TIMESTAMP WITH TIME ZONE      | Creation timestamp                    |
| updated_at  | TIMESTAMP WITH TIME ZONE      | Last update timestamp                 |

**Relationships:**
- `client_id` references `clients(id)` with `ON DELETE SET NULL` - If a client is deleted, projects remain but without client association

### Cycles

Represents time-boxed periods for organizing issues (e.g., sprints, milestones).

| Column      | Type                          | Description                           |
|-------------|-------------------------------|---------------------------------------|
| id          | SERIAL                        | Primary key                           |
| name        | VARCHAR(255)                  | Cycle name (required)                 |
| project_id  | INTEGER                       | Foreign key to projects.id            |
| start_date  | DATE                          | Cycle start date                      |
| end_date    | DATE                          | Cycle end date                        |
| status      | VARCHAR(50)                   | Status (planned, active, completed)   |
| created_at  | TIMESTAMP WITH TIME ZONE      | Creation timestamp                    |
| updated_at  | TIMESTAMP WITH TIME ZONE      | Last update timestamp                 |

**Relationships:**
- `project_id` references `projects(id)` with `ON DELETE CASCADE` - If a project is deleted, all its cycles are deleted

### Issues

The core entity representing tasks, bugs, features, etc.

| Column      | Type                          | Description                           |
|-------------|-------------------------------|---------------------------------------|
| id          | SERIAL                        | Primary key                           |
| title       | VARCHAR(255)                  | Issue title (required)                |
| description | TEXT                          | Issue description                     |
| status      | issue_status                  | Status enum (backlog, todo, etc.)     |
| priority    | issue_priority                | Priority enum (low, medium, etc.)     |
| estimate    | FLOAT                         | Time estimate (hours or story points) |
| due_date    | DATE                          | Issue due date                        |
| project_id  | INTEGER                       | Foreign key to projects.id            |
| cycle_id    | INTEGER                       | Foreign key to cycles.id              |
| assignee_id | INTEGER                       | Assignee ID (for future user table)   |
| created_at  | TIMESTAMP WITH TIME ZONE      | Creation timestamp                    |
| updated_at  | TIMESTAMP WITH TIME ZONE      | Last update timestamp                 |

**Relationships:**
- `project_id` references `projects(id)` with `ON DELETE CASCADE` - If a project is deleted, all its issues are deleted
- `cycle_id` references `cycles(id)` with `ON DELETE SET NULL` - If a cycle is deleted, issues remain but are no longer associated with that cycle

**Enums:**
- `issue_status`: 'backlog', 'todo', 'in_progress', 'review', 'done'
- `issue_priority`: 'low', 'medium', 'high', 'urgent'

### Tags

Allows categorization of issues.

| Column      | Type                          | Description                           |
|-------------|-------------------------------|---------------------------------------|
| id          | SERIAL                        | Primary key                           |
| name        | VARCHAR(100)                  | Tag name (required, unique)           |
| color       | VARCHAR(7)                    | Hex color code (default: #CCCCCC)     |

### Issue Tags

Junction table for the many-to-many relationship between issues and tags.

| Column      | Type                          | Description                           |
|-------------|-------------------------------|---------------------------------------|
| issue_id    | INTEGER                       | Foreign key to issues.id              |
| tag_id      | INTEGER                       | Foreign key to tags.id                |

**Relationships:**
- `issue_id` references `issues(id)` with `ON DELETE CASCADE`
- `tag_id` references `tags(id)` with `ON DELETE CASCADE`
- Primary key is the combination of (issue_id, tag_id)

### Comments

Stores comments on issues.

| Column      | Type                          | Description                           |
|-------------|-------------------------------|---------------------------------------|
| id          | SERIAL                        | Primary key                           |
| issue_id    | INTEGER                       | Foreign key to issues.id              |
| user_id     | INTEGER                       | User ID (for future user table)       |
| content     | TEXT                          | Comment content (required)            |
| created_at  | TIMESTAMP WITH TIME ZONE      | Creation timestamp                    |

**Relationships:**
- `issue_id` references `issues(id)` with `ON DELETE CASCADE` - If an issue is deleted, all its comments are deleted

### Instructions

Documentation table for database operations.

| Column         | Type                          | Description                           |
|----------------|-------------------------------|---------------------------------------|
| id             | SERIAL                        | Primary key                           |
| operation      | VARCHAR(100)                  | Operation name (required)             |
| description    | TEXT                          | Operation description (required)      |
| query_example  | TEXT                          | Example SQL query (required)          |
| parameters     | TEXT                          | Parameter descriptions                |
| created_at     | TIMESTAMP WITH TIME ZONE      | Creation timestamp                    |

## Indexes

The schema includes the following indexes for performance optimization:

| Index Name              | Table     | Column(s)    | Purpose                                   |
|-------------------------|-----------|--------------|-------------------------------------------|
| idx_issues_project_id   | issues    | project_id   | Optimize queries filtering by project     |
| idx_issues_cycle_id     | issues    | cycle_id     | Optimize queries filtering by cycle       |
| idx_issues_status       | issues    | status       | Optimize queries filtering by status      |
| idx_projects_client_id  | projects  | client_id    | Optimize queries filtering by client      |

## Relationships

The schema establishes the following relationships:

1. **One-to-Many**:
   - One client can have many projects
   - One project can have many cycles
   - One project can have many issues
   - One cycle can have many issues
   - One issue can have many comments

2. **Many-to-Many**:
   - Issues can have many tags, and tags can be applied to many issues (via issue_tags junction table)

## Data Flow

The typical data flow in this schema is:

1. Create a client
2. Create projects for the client
3. Create cycles for projects
4. Create issues within projects and optionally assign them to cycles
5. Add tags to issues for categorization
6. Add comments to issues for discussion

## Usage Examples

For detailed examples of how to interact with this schema, refer to the `instructions.sql` file, which contains queries for common operations such as:

- Creating and retrieving clients, projects, cycles, and issues
- Filtering issues by various criteria
- Updating issue status and other properties
- Managing tags and comments
- Generating reports and summaries

## Schema Maintenance

The schema includes a reset section at the top of the SQL file that drops all tables and types before recreating them. This allows for easy schema updates and clean installations.

```sql
-- Reset section
DROP TABLE IF EXISTS issue_tags CASCADE;
DROP TABLE IF EXISTS comments CASCADE;
DROP TABLE IF EXISTS issues CASCADE;
DROP TABLE IF EXISTS cycles CASCADE;
DROP TABLE IF EXISTS projects CASCADE;
DROP TABLE IF EXISTS clients CASCADE;
DROP TABLE IF EXISTS tags CASCADE;
DROP TABLE IF EXISTS instructions CASCADE;

-- Drop custom types
DROP TYPE IF EXISTS issue_status CASCADE;
DROP TYPE IF EXISTS issue_priority CASCADE;
```

To apply the schema to a PostgreSQL database, run:

```bash
psql -U username -d database_name -f project_management_schema.sql