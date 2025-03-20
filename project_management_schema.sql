-- Project Management Database Schema
-- 
-- This schema creates a complete project management system with clients, projects, cycles, and issues.
-- The schema includes proper relationships:
-- - Projects belong to Clients (many-to-one)
-- - Issues belong to Projects (many-to-one)
-- - Issues can belong to Cycles (many-to-one)
-- - Issues can have many Tags (many-to-many)
--
-- Usage:
-- 1. Run this script against a PostgreSQL database to set up the schema
-- 2. The script will first drop any existing tables and types (reset)
-- 3. Then it will create all tables with proper relationships
-- 4. Finally, it will populate the instructions table with query examples
--
-- Example: psql -U username -d database_name -f project_management_schema.sql

-- Reset section - Drop all tables and types if they exist
DROP TABLE IF EXISTS issue_tags CASCADE;
DROP TABLE IF EXISTS comments CASCADE;
DROP TABLE IF EXISTS issues CASCADE;
DROP TABLE IF EXISTS cycles CASCADE;
DROP TABLE IF EXISTS projects CASCADE;
DROP TABLE IF EXISTS clients CASCADE;
DROP TABLE IF EXISTS tags CASCADE;
DROP TABLE IF EXISTS instructions CASCADE;

-- Drop custom types if they exist
DROP TYPE IF EXISTS issue_status CASCADE;
DROP TYPE IF EXISTS issue_priority CASCADE;

-- Clients Table
CREATE TABLE clients (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    logo TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Projects Table
CREATE TABLE projects (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    client_id INTEGER REFERENCES clients(id) ON DELETE SET NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Cycles Table
CREATE TABLE cycles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    project_id INTEGER REFERENCES projects(id) ON DELETE CASCADE,
    start_date DATE,
    end_date DATE,
    status VARCHAR(50) DEFAULT 'planned', -- planned, active, completed
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Issue Status Enum
CREATE TYPE issue_status AS ENUM ('backlog', 'todo', 'in_progress', 'review', 'done');

-- Issue Priority Enum
CREATE TYPE issue_priority AS ENUM ('low', 'medium', 'high', 'urgent');

-- Issues Table
CREATE TABLE issues (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    status issue_status DEFAULT 'backlog',
    priority issue_priority DEFAULT 'medium',
    estimate FLOAT, -- Estimated hours or story points
    due_date DATE,
    project_id INTEGER REFERENCES projects(id) ON DELETE CASCADE,
    cycle_id INTEGER REFERENCES cycles(id) ON DELETE SET NULL,
    assignee_id INTEGER, -- This would reference a users table if you add one
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tags Table (for tagging issues)
CREATE TABLE tags (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    color VARCHAR(7) DEFAULT '#CCCCCC'
);

-- Issue Tags (Many-to-Many relationship)
CREATE TABLE issue_tags (
    issue_id INTEGER REFERENCES issues(id) ON DELETE CASCADE,
    tag_id INTEGER REFERENCES tags(id) ON DELETE CASCADE,
    PRIMARY KEY (issue_id, tag_id)
);

-- Comments Table (for issue discussions)
CREATE TABLE comments (
    id SERIAL PRIMARY KEY,
    issue_id INTEGER REFERENCES issues(id) ON DELETE CASCADE,
    user_id INTEGER, -- This would reference a users table if you add one
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Instructions Table (for documentation on how to use the database)
CREATE TABLE instructions (
    id SERIAL PRIMARY KEY,
    operation VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    query_example TEXT NOT NULL,
    parameters TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample instructions
INSERT INTO instructions (operation, description, query_example, parameters) VALUES
('GET_ISSUES', 
'Retrieves issues based on specified filters.', 
'SELECT i.id, i.title, i.description, i.status, i.priority, i.estimate, i.due_date, 
        p.title as project_title, c.name as client_name
 FROM issues i
 JOIN projects p ON i.project_id = p.id
 JOIN clients c ON p.client_id = c.id
 WHERE i.status = $1 AND p.id = $2
 ORDER BY i.priority DESC, i.due_date ASC;',
'status (issue_status): The status to filter by
project_id (integer): The project ID to filter by');

INSERT INTO instructions (operation, description, query_example, parameters) VALUES
('CREATE_ISSUE', 
'Creates a new issue in the system.', 
'INSERT INTO issues (title, description, status, priority, estimate, due_date, project_id, cycle_id)
 VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
 RETURNING id;',
'title (varchar): Issue title
description (text): Issue description
status (issue_status): Issue status
priority (issue_priority): Issue priority
estimate (float): Time estimate
due_date (date): Due date
project_id (integer): Associated project ID
cycle_id (integer): Associated cycle ID (optional)');

INSERT INTO instructions (operation, description, query_example, parameters) VALUES
('GET_PROJECT_SUMMARY', 
'Gets a summary of a project with issue counts by status.', 
'SELECT p.id, p.title, c.name as client_name,
        COUNT(i.id) as total_issues,
        SUM(CASE WHEN i.status = ''backlog'' THEN 1 ELSE 0 END) as backlog_count,
        SUM(CASE WHEN i.status = ''todo'' THEN 1 ELSE 0 END) as todo_count,
        SUM(CASE WHEN i.status = ''in_progress'' THEN 1 ELSE 0 END) as in_progress_count,
        SUM(CASE WHEN i.status = ''review'' THEN 1 ELSE 0 END) as review_count,
        SUM(CASE WHEN i.status = ''done'' THEN 1 ELSE 0 END) as done_count
 FROM projects p
 LEFT JOIN clients c ON p.client_id = c.id
 LEFT JOIN issues i ON i.project_id = p.id
 WHERE p.id = $1
 GROUP BY p.id, p.title, c.name;',
'project_id (integer): The project ID to summarize');

INSERT INTO instructions (operation, description, query_example, parameters) VALUES
('GET_CYCLE_ISSUES', 
'Gets all issues for a specific cycle.', 
'SELECT i.id, i.title, i.status, i.priority, i.estimate, i.due_date
 FROM issues i
 WHERE i.cycle_id = $1
 ORDER BY i.priority DESC, i.due_date ASC;',
'cycle_id (integer): The cycle ID to query');

INSERT INTO instructions (operation, description, query_example, parameters) VALUES
('UPDATE_ISSUE_STATUS', 
'Updates the status of an issue.', 
'UPDATE issues
 SET status = $1, updated_at = CURRENT_TIMESTAMP
 WHERE id = $2
 RETURNING id, title, status;',
'status (issue_status): The new status
issue_id (integer): The issue ID to update');

-- Additional comprehensive instructions

INSERT INTO instructions (operation, description, query_example, parameters) VALUES
('CREATE_CLIENT', 
'Creates a new client in the system.', 
'INSERT INTO clients (name, logo)
 VALUES ($1, $2)
 RETURNING id, name;',
'name (varchar): Client name
logo (text): URL or path to client logo image');

INSERT INTO instructions (operation, description, query_example, parameters) VALUES
('CREATE_PROJECT', 
'Creates a new project associated with a client.', 
'INSERT INTO projects (title, description, client_id)
 VALUES ($1, $2, $3)
 RETURNING id, title;',
'title (varchar): Project title
description (text): Project description
client_id (integer): Associated client ID');

INSERT INTO instructions (operation, description, query_example, parameters) VALUES
('CREATE_CYCLE', 
'Creates a new cycle for a project.', 
'INSERT INTO cycles (name, project_id, start_date, end_date, status)
 VALUES ($1, $2, $3, $4, $5)
 RETURNING id, name;',
'name (varchar): Cycle name
project_id (integer): Associated project ID
start_date (date): Cycle start date
end_date (date): Cycle end date
status (varchar): Cycle status (planned, active, completed)');

INSERT INTO instructions (operation, description, query_example, parameters) VALUES
('GET_ALL_CLIENTS', 
'Retrieves all clients with project counts.', 
'SELECT c.id, c.name, c.logo, COUNT(p.id) as project_count
 FROM clients c
 LEFT JOIN projects p ON c.id = p.client_id
 GROUP BY c.id, c.name, c.logo
 ORDER BY c.name;',
'No parameters required');

INSERT INTO instructions (operation, description, query_example, parameters) VALUES
('GET_CLIENT_PROJECTS', 
'Retrieves all projects for a specific client.', 
'SELECT p.id, p.title, p.description, 
        COUNT(i.id) as issue_count,
        SUM(CASE WHEN i.status = ''done'' THEN 1 ELSE 0 END) as completed_issues
 FROM projects p
 LEFT JOIN issues i ON p.id = i.project_id
 WHERE p.client_id = $1
 GROUP BY p.id, p.title, p.description
 ORDER BY p.title;',
'client_id (integer): The client ID to filter by');

INSERT INTO instructions (operation, description, query_example, parameters) VALUES
('GET_PROJECT_CYCLES', 
'Retrieves all cycles for a specific project.', 
'SELECT c.id, c.name, c.start_date, c.end_date, c.status,
        COUNT(i.id) as issue_count
 FROM cycles c
 LEFT JOIN issues i ON c.id = i.cycle_id
 WHERE c.project_id = $1
 GROUP BY c.id, c.name, c.start_date, c.end_date, c.status
 ORDER BY c.start_date;',
'project_id (integer): The project ID to filter by');

INSERT INTO instructions (operation, description, query_example, parameters) VALUES
('UPDATE_ISSUE', 
'Updates an existing issue with new values.', 
'UPDATE issues
 SET title = $1, 
     description = $2,
     status = $3,
     priority = $4,
     estimate = $5,
     due_date = $6,
     cycle_id = $7,
     updated_at = CURRENT_TIMESTAMP
 WHERE id = $8
 RETURNING id, title;',
'title (varchar): Issue title
description (text): Issue description
status (issue_status): Issue status
priority (issue_priority): Issue priority
estimate (float): Time estimate
due_date (date): Due date
cycle_id (integer): Associated cycle ID
issue_id (integer): The issue ID to update');

INSERT INTO instructions (operation, description, query_example, parameters) VALUES
('DELETE_ISSUE', 
'Deletes an issue from the system.', 
'DELETE FROM issues
 WHERE id = $1
 RETURNING id;',
'issue_id (integer): The issue ID to delete');

INSERT INTO instructions (operation, description, query_example, parameters) VALUES
('ADD_TAG_TO_ISSUE', 
'Adds a tag to an issue.', 
'INSERT INTO issue_tags (issue_id, tag_id)
 VALUES ($1, $2)
 ON CONFLICT (issue_id, tag_id) DO NOTHING
 RETURNING issue_id, tag_id;',
'issue_id (integer): The issue ID
tag_id (integer): The tag ID');

INSERT INTO instructions (operation, description, query_example, parameters) VALUES
('REMOVE_TAG_FROM_ISSUE', 
'Removes a tag from an issue.', 
'DELETE FROM issue_tags
 WHERE issue_id = $1 AND tag_id = $2
 RETURNING issue_id, tag_id;',
'issue_id (integer): The issue ID
tag_id (integer): The tag ID');

INSERT INTO instructions (operation, description, query_example, parameters) VALUES
('ADD_COMMENT_TO_ISSUE', 
'Adds a comment to an issue.', 
'INSERT INTO comments (issue_id, user_id, content)
 VALUES ($1, $2, $3)
 RETURNING id, content;',
'issue_id (integer): The issue ID
user_id (integer): The user ID making the comment
content (text): The comment text');

INSERT INTO instructions (operation, description, query_example, parameters) VALUES
('GET_ISSUE_COMMENTS', 
'Retrieves all comments for a specific issue.', 
'SELECT c.id, c.content, c.created_at, c.user_id
 FROM comments c
 WHERE c.issue_id = $1
 ORDER BY c.created_at;',
'issue_id (integer): The issue ID to get comments for');

INSERT INTO instructions (operation, description, query_example, parameters) VALUES
('GET_ISSUE_DETAILS', 
'Retrieves detailed information about an issue including project, client, and tags.', 
'SELECT i.id, i.title, i.description, i.status, i.priority, i.estimate, i.due_date,
        i.created_at, i.updated_at,
        p.id as project_id, p.title as project_title,
        c.id as client_id, c.name as client_name,
        cy.id as cycle_id, cy.name as cycle_name,
        ARRAY_AGG(DISTINCT t.name) FILTER (WHERE t.id IS NOT NULL) as tags
 FROM issues i
 JOIN projects p ON i.project_id = p.id
 JOIN clients c ON p.client_id = c.id
 LEFT JOIN cycles cy ON i.cycle_id = cy.id
 LEFT JOIN issue_tags it ON i.id = it.issue_id
 LEFT JOIN tags t ON it.tag_id = t.id
 WHERE i.id = $1
 GROUP BY i.id, i.title, i.description, i.status, i.priority, i.estimate, i.due_date,
          i.created_at, i.updated_at, p.id, p.title, c.id, c.name, cy.id, cy.name;',
'issue_id (integer): The issue ID to get details for');

INSERT INTO instructions (operation, description, query_example, parameters) VALUES
('GET_ISSUES_BY_PRIORITY', 
'Retrieves issues filtered by priority level.', 
'SELECT i.id, i.title, i.status, i.priority, i.due_date,
        p.title as project_title
 FROM issues i
 JOIN projects p ON i.project_id = p.id
 WHERE i.priority = $1
 ORDER BY i.due_date ASC;',
'priority (issue_priority): The priority level to filter by');

INSERT INTO instructions (operation, description, query_example, parameters) VALUES
('GET_OVERDUE_ISSUES', 
'Retrieves all issues that are past their due date and not completed.', 
'SELECT i.id, i.title, i.status, i.priority, i.due_date,
        p.title as project_title, c.name as client_name
 FROM issues i
 JOIN projects p ON i.project_id = p.id
 JOIN clients c ON p.client_id = c.id
 WHERE i.due_date < CURRENT_DATE
   AND i.status != ''done''
 ORDER BY i.due_date ASC, i.priority DESC;',
'No parameters required');

INSERT INTO instructions (operation, description, query_example, parameters) VALUES
('MOVE_ISSUES_TO_CYCLE', 
'Moves multiple issues to a specific cycle.', 
'UPDATE issues
 SET cycle_id = $1, updated_at = CURRENT_TIMESTAMP
 WHERE id = ANY($2::int[])
 RETURNING id, title;',
'cycle_id (integer): The cycle ID to move issues to
issue_ids (integer[]): Array of issue IDs to move');

INSERT INTO instructions (operation, description, query_example, parameters) VALUES
('GET_PROJECT_PROGRESS', 
'Gets the overall progress of a project based on completed vs total issues.', 
'SELECT p.id, p.title,
        COUNT(i.id) as total_issues,
        SUM(CASE WHEN i.status = ''done'' THEN 1 ELSE 0 END) as completed_issues,
        CASE 
            WHEN COUNT(i.id) > 0 THEN 
                ROUND((SUM(CASE WHEN i.status = ''done'' THEN 1 ELSE 0 END)::numeric / COUNT(i.id)::numeric) * 100, 2)
            ELSE 0
        END as completion_percentage
 FROM projects p
 LEFT JOIN issues i ON p.id = i.project_id
 WHERE p.id = $1
 GROUP BY p.id, p.title;',
'project_id (integer): The project ID to get progress for');

-- Indexes for performance
CREATE INDEX idx_issues_project_id ON issues(project_id);
CREATE INDEX idx_issues_cycle_id ON issues(cycle_id);
CREATE INDEX idx_issues_status ON issues(status);
CREATE INDEX idx_projects_client_id ON projects(client_id);
