-- Project Management Database Schema with Employee Creator Framework Integration
-- 
-- This schema creates a complete project management system with clients, projects, cycles, and issues
-- while integrating with the Employee Creator Framework for virtual employee management.
--
-- The schema includes proper relationships:
-- - Projects belong to Clients (many-to-one)
-- - Issues belong to Projects (many-to-one)
-- - Issues can belong to Cycles (many-to-one)
-- - Issues can have many Tags (many-to-many)
-- - Employees can be assigned to Projects and Issues
-- - Task logs track employee activities on issues
--
-- Usage:
-- 1. Run this script against a PostgreSQL database to set up the schema
-- 2. The script will first drop any existing tables and types (reset)
-- 3. Then it will create all tables with proper relationships
-- 4. Finally, it will populate the instructions table with query examples

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Reset section - Drop all tables and types if they exist
DROP TABLE IF EXISTS issue_tags CASCADE;
DROP TABLE IF EXISTS comments CASCADE;
DROP TABLE IF EXISTS issues CASCADE;
DROP TABLE IF EXISTS cycles CASCADE;
DROP TABLE IF EXISTS projects CASCADE;
DROP TABLE IF EXISTS clients CASCADE;
DROP TABLE IF EXISTS tags CASCADE;
DROP TABLE IF EXISTS instructions CASCADE;
DROP TABLE IF EXISTS pm_task_logs CASCADE;
DROP TABLE IF EXISTS pm_metadata CASCADE;
DROP TABLE IF EXISTS pm_employee_assignments CASCADE;

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
    organization_id UUID, -- Link to organization in Employee Creator Framework
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
    employee_id UUID, -- Reference to an employee in the Employee Creator Framework
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

-- Employee Assignments (linking employees to projects)
CREATE TABLE pm_employee_assignments (
    assignment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL, -- Reference to emp_employees
    project_id INTEGER REFERENCES projects(id) ON DELETE CASCADE,
    role VARCHAR(100),
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Project Metadata Table (for storing context-specific data)
CREATE TABLE pm_metadata (
    metadata_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id INTEGER REFERENCES projects(id) ON DELETE CASCADE,
    issue_id INTEGER REFERENCES issues(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    content JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT project_or_issue_required CHECK (
        (project_id IS NOT NULL AND issue_id IS NULL) OR
        (project_id IS NULL AND issue_id IS NOT NULL)
    )
);

-- Task Logs Table (for tracking employee activities)
CREATE TABLE pm_task_logs (
    log_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID NOT NULL,
    employee_id UUID NOT NULL, -- Reference to emp_employees
    user_id UUID NOT NULL,
    issue_id INTEGER REFERENCES issues(id) ON DELETE CASCADE,
    function_id UUID, -- Reference to emp_functions
    sop_id UUID, -- Reference to emp_sops
    current_step_id UUID, -- Reference to emp_steps
    status VARCHAR(50) NOT NULL DEFAULT 'started',
    completion_flag BOOLEAN NOT NULL DEFAULT FALSE,
    progress_percentage INTEGER NOT NULL DEFAULT 0,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    metadata_id UUID REFERENCES pm_metadata(metadata_id),
    CONSTRAINT progress_percentage_range CHECK (progress_percentage >= 0 AND progress_percentage <= 100),
    CONSTRAINT valid_status CHECK (status IN ('started', 'in_progress', 'completed', 'paused', 'cancelled'))
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

-- Create a function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers to automatically update the updated_at column
CREATE TRIGGER update_clients_updated_at
BEFORE UPDATE ON clients
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_projects_updated_at
BEFORE UPDATE ON projects
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_cycles_updated_at
BEFORE UPDATE ON cycles
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_issues_updated_at
BEFORE UPDATE ON issues
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pm_employee_assignments_updated_at
BEFORE UPDATE ON pm_employee_assignments
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pm_metadata_updated_at
BEFORE UPDATE ON pm_metadata
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pm_task_logs_updated_at
BEFORE UPDATE ON pm_task_logs
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Function to assign an employee to a project
CREATE OR REPLACE FUNCTION pm_assign_employee_to_project(
    p_employee_id UUID,
    p_project_id INTEGER,
    p_role VARCHAR(100)
) RETURNS UUID AS $$
DECLARE
    v_assignment_id UUID;
BEGIN
    INSERT INTO pm_employee_assignments (
        employee_id,
        project_id,
        role
    ) VALUES (
        p_employee_id,
        p_project_id,
        p_role
    ) RETURNING assignment_id INTO v_assignment_id;
    
    RETURN v_assignment_id;
END;
$$ LANGUAGE plpgsql;

-- Function to create a task log for an issue
CREATE OR REPLACE FUNCTION pm_create_task_log(
    p_task_id UUID,
    p_employee_id UUID,
    p_user_id UUID,
    p_issue_id INTEGER,
    p_function_id UUID,
    p_notes TEXT DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    v_log_id UUID;
    v_metadata_id UUID;
    v_has_access BOOLEAN;
BEGIN
    -- Check if the employee is assigned to the project containing this issue
    SELECT EXISTS (
        SELECT 1 
        FROM pm_employee_assignments ea
        JOIN issues i ON i.project_id = ea.project_id
        WHERE ea.employee_id = p_employee_id
        AND i.id = p_issue_id
    ) INTO v_has_access;
    
    IF NOT v_has_access THEN
        RAISE EXCEPTION 'Employee is not assigned to the project containing this issue';
    END IF;
    
    -- Create metadata record
    INSERT INTO pm_metadata (
        issue_id,
        user_id,
        content
    ) VALUES (
        p_issue_id,
        p_user_id,
        '{}'::jsonb
    ) RETURNING metadata_id INTO v_metadata_id;
    
    -- Create task log
    INSERT INTO pm_task_logs (
        task_id,
        employee_id,
        user_id,
        issue_id,
        function_id,
        status,
        notes,
        metadata_id
    ) VALUES (
        p_task_id,
        p_employee_id,
        p_user_id,
        p_issue_id,
        p_function_id,
        'started',
        p_notes,
        v_metadata_id
    ) RETURNING log_id INTO v_log_id;
    
    RETURN v_log_id;
END;
$$ LANGUAGE plpgsql;

-- Function to update task progress
CREATE OR REPLACE FUNCTION pm_update_task_progress(
    p_task_id UUID,
    p_user_id UUID,
    p_current_step_id UUID DEFAULT NULL,
    p_status VARCHAR(50) DEFAULT NULL,
    p_progress_percentage INTEGER DEFAULT NULL,
    p_notes TEXT DEFAULT NULL,
    p_completion_flag BOOLEAN DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    v_task_log_id UUID;
    v_completed_at TIMESTAMP WITH TIME ZONE;
    v_issue_id INTEGER;
BEGIN
    -- Get the task log ID
    SELECT log_id, issue_id INTO v_task_log_id, v_issue_id
    FROM pm_task_logs
    WHERE task_id = p_task_id AND user_id = p_user_id;
    
    IF v_task_log_id IS NULL THEN
        RAISE EXCEPTION 'Task log not found for task_id % and user_id %', p_task_id, p_user_id;
    END IF;
    
    -- Set completed_at if task is being marked as complete
    IF p_completion_flag IS TRUE THEN
        v_completed_at := CURRENT_TIMESTAMP;
        
        -- If task is completed, update the issue status to 'done' if it's not already
        IF v_issue_id IS NOT NULL THEN
            UPDATE issues
            SET status = 'done'
            WHERE id = v_issue_id AND status != 'done';
        END IF;
    END IF;
    
    -- Update the task log
    UPDATE pm_task_logs
    SET 
        current_step_id = COALESCE(p_current_step_id, current_step_id),
        status = COALESCE(p_status, status),
        progress_percentage = COALESCE(p_progress_percentage, progress_percentage),
        notes = CASE WHEN p_notes IS NOT NULL THEN 
                    CASE WHEN notes IS NULL THEN p_notes 
                    ELSE notes || E'\n' || p_notes END
                ELSE notes END,
        completion_flag = COALESCE(p_completion_flag, completion_flag),
        completed_at = COALESCE(v_completed_at, completed_at)
    WHERE log_id = v_task_log_id;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- Function to update task metadata
CREATE OR REPLACE FUNCTION pm_update_metadata(
    p_metadata_id UUID,
    p_content JSONB
) RETURNS BOOLEAN AS $$
BEGIN
    -- Update the metadata
    UPDATE pm_metadata
    SET content = p_content
    WHERE metadata_id = p_metadata_id;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- Function to get task metadata
CREATE OR REPLACE FUNCTION pm_get_metadata(
    p_metadata_id UUID
) RETURNS JSONB AS $$
DECLARE
    v_content JSONB;
BEGIN
    SELECT content INTO v_content
    FROM pm_metadata
    WHERE metadata_id = p_metadata_id;
    
    RETURN v_content;
END;
$$ LANGUAGE plpgsql;

-- Function to get active tasks for a user
CREATE OR REPLACE FUNCTION pm_get_user_tasks(
    p_user_id UUID,
    p_include_completed BOOLEAN DEFAULT FALSE
) RETURNS JSONB AS $$
DECLARE
    v_result JSONB;
BEGIN
    WITH task_data AS (
        SELECT 
            tl.task_id,
            tl.log_id,
            tl.employee_id,
            tl.issue_id,
            i.title AS issue_title,
            i.status AS issue_status,
            p.id AS project_id,
            p.title AS project_title,
            tl.status,
            tl.completion_flag,
            tl.progress_percentage,
            tl.started_at,
            tl.updated_at,
            tl.completed_at,
            tl.notes,
            tl.metadata_id,
            m.content AS metadata
        FROM pm_task_logs tl
        JOIN issues i ON tl.issue_id = i.id
        JOIN projects p ON i.project_id = p.id
        LEFT JOIN pm_metadata m ON tl.metadata_id = m.metadata_id
        WHERE tl.user_id = p_user_id
        AND (p_include_completed OR tl.completion_flag = FALSE)
    )
    SELECT jsonb_agg(
        jsonb_build_object(
            'task_id', td.task_id,
            'log_id', td.log_id,
            'issue', jsonb_build_object(
                'issue_id', td.issue_id,
                'title', td.issue_title,
                'status', td.issue_status
            ),
            'project', jsonb_build_object(
                'project_id', td.project_id,
                'title', td.project_title
            ),
            'status', td.status,
            'completion_flag', td.completion_flag,
            'progress_percentage', td.progress_percentage,
            'started_at', td.started_at,
            'updated_at', td.updated_at,
            'completed_at', td.completed_at,
            'notes', td.notes,
            'metadata', td.metadata
        )
    ) INTO v_result
    FROM task_data td;
    
    RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$ LANGUAGE plpgsql;

-- Function to get all employees assigned to a project
CREATE OR REPLACE FUNCTION pm_get_project_employees(
    p_project_id INTEGER
) RETURNS JSONB AS $$
DECLARE
    v_result JSONB;
BEGIN
    SELECT jsonb_agg(
        jsonb_build_object(
            'assignment_id', ea.assignment_id,
            'employee_id', ea.employee_id,
            'role', ea.role,
            'assigned_at', ea.assigned_at
        )
    ) INTO v_result
    FROM pm_employee_assignments ea
    WHERE ea.project_id = p_project_id;
    
    RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$ LANGUAGE plpgsql;

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
'INSERT INTO issues (title, description, status, priority, estimate, due_date, project_id, cycle_id, employee_id)
 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
 RETURNING id;',
'title (varchar): Issue title
description (text): Issue description
status (issue_status): Issue status
priority (issue_priority): Issue priority
estimate (float): Time estimate
due_date (date): Due date
project_id (integer): Associated project ID
cycle_id (integer): Associated cycle ID (optional)
employee_id (uuid): Associated employee ID (optional)');

INSERT INTO instructions (operation, description, query_example, parameters) VALUES
('ASSIGN_EMPLOYEE_TO_PROJECT', 
'Assigns an employee to a project.', 
'SELECT pm_assign_employee_to_project($1, $2, $3);',
'employee_id (uuid): The employee ID to assign
project_id (integer): The project ID to assign to
role (varchar): The role of the employee in the project');

INSERT INTO instructions (operation, description, query_example, parameters) VALUES
('CREATE_TASK_LOG', 
'Creates a task log for an issue.', 
'SELECT pm_create_task_log($1, $2, $3, $4, $5, $6);',
'task_id (uuid): Unique identifier for the task
employee_id (uuid): The employee performing the task
user_id (uuid): The user the task is being performed for
issue_id (integer): The issue ID for the task
function_id (uuid): The function being performed
notes (text): Additional notes about the task (optional)');

-- Indexes for performance
CREATE INDEX idx_issues_project_id ON issues(project_id);
CREATE INDEX idx_issues_cycle_id ON issues(cycle_id);
CREATE INDEX idx_issues_status ON issues(status);
CREATE INDEX idx_issues_employee_id ON issues(employee_id);
CREATE INDEX idx_projects_client_id ON projects(client_id);
CREATE INDEX idx_projects_organization_id ON projects(organization_id);
CREATE INDEX idx_pm_employee_assignments_employee_id ON pm_employee_assignments(employee_id);
CREATE INDEX idx_pm_employee_assignments_project_id ON pm_employee_assignments(project_id);
CREATE INDEX idx_pm_task_logs_task_id ON pm_task_logs(task_id);
CREATE INDEX idx_pm_task_logs_user_id ON pm_task_logs(user_id);
CREATE INDEX idx_pm_task_logs_employee_id ON pm_task_logs(employee_id);
CREATE INDEX idx_pm_task_logs_issue_id ON pm_task_logs(issue_id);
CREATE INDEX idx_pm_metadata_project_id ON pm_metadata(project_id);
CREATE INDEX idx_pm_metadata_issue_id ON pm_metadata(issue_id);
CREATE INDEX idx_pm_metadata_user_id ON pm_metadata(user_id);
