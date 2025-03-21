-- Employee Creator Framework Database Setup
-- Prefix: emp_

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create employees table
CREATE TABLE IF NOT EXISTS emp_employees (
    employee_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    organization_id UUID NOT NULL,
    access_list UUID[] NOT NULL,
    tool_access JSONB NOT NULL,
    role VARCHAR(255) NOT NULL,
    description TEXT,
    functions JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) DEFAULT 'active'
);

-- Create functions table
CREATE TABLE IF NOT EXISTS emp_functions (
    function_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES emp_employees(employee_id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    required_tools JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create SOPs table
CREATE TABLE IF NOT EXISTS emp_sops (
    sop_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    function_id UUID NOT NULL REFERENCES emp_functions(function_id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    tools_used JSONB,
    version VARCHAR(50) DEFAULT '1.0',
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create steps table
CREATE TABLE IF NOT EXISTS emp_steps (
    step_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sop_id UUID NOT NULL REFERENCES emp_sops(sop_id) ON DELETE CASCADE,
    step_number INTEGER NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    questions JSONB,
    actions JSONB,
    tools JSONB,
    expected_outcome TEXT,
    next_step UUID REFERENCES emp_steps(step_id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create metadata table
CREATE TABLE IF NOT EXISTS emp_metadata (
    metadata_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID NOT NULL,
    user_id UUID NOT NULL,
    content JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create task logs table
CREATE TABLE IF NOT EXISTS emp_task_logs (
    log_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID NOT NULL,
    employee_id UUID NOT NULL REFERENCES emp_employees(employee_id),
    user_id UUID NOT NULL,
    function_id UUID NOT NULL REFERENCES emp_functions(function_id),
    sop_id UUID REFERENCES emp_sops(sop_id),
    current_step_id UUID REFERENCES emp_steps(step_id),
    status VARCHAR(50) NOT NULL DEFAULT 'started',
    completion_flag BOOLEAN NOT NULL DEFAULT FALSE,
    progress_percentage INTEGER NOT NULL DEFAULT 0,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    metadata_id UUID REFERENCES emp_metadata(metadata_id),
    CONSTRAINT progress_percentage_range CHECK (progress_percentage >= 0 AND progress_percentage <= 100),
    CONSTRAINT valid_status CHECK (status IN ('started', 'in_progress', 'completed', 'paused', 'cancelled'))
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_emp_employees_organization_id ON emp_employees(organization_id);
CREATE INDEX IF NOT EXISTS idx_emp_functions_employee_id ON emp_functions(employee_id);
CREATE INDEX IF NOT EXISTS idx_emp_sops_function_id ON emp_sops(function_id);
CREATE INDEX IF NOT EXISTS idx_emp_steps_sop_id ON emp_steps(sop_id);
CREATE INDEX IF NOT EXISTS idx_emp_steps_next_step ON emp_steps(next_step);
CREATE INDEX IF NOT EXISTS idx_emp_task_logs_task_id ON emp_task_logs(task_id);
CREATE INDEX IF NOT EXISTS idx_emp_task_logs_user_id ON emp_task_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_emp_task_logs_employee_id ON emp_task_logs(employee_id);
CREATE INDEX IF NOT EXISTS idx_emp_metadata_task_id ON emp_metadata(task_id);
CREATE INDEX IF NOT EXISTS idx_emp_metadata_user_id ON emp_metadata(user_id);

-- Create a function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers to automatically update the updated_at column
CREATE TRIGGER update_emp_employees_updated_at
BEFORE UPDATE ON emp_employees
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_emp_functions_updated_at
BEFORE UPDATE ON emp_functions
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_emp_steps_updated_at
BEFORE UPDATE ON emp_steps
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_emp_task_logs_updated_at
BEFORE UPDATE ON emp_task_logs
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_emp_metadata_updated_at
BEFORE UPDATE ON emp_metadata
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Function to create a new employee
CREATE OR REPLACE FUNCTION emp_create_employee(
    p_name VARCHAR(255),
    p_organization_id UUID,
    p_access_list UUID[],
    p_tool_access JSONB,
    p_role VARCHAR(255),
    p_description TEXT DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    v_employee_id UUID;
BEGIN
    INSERT INTO emp_employees (
        name,
        organization_id,
        access_list,
        tool_access,
        role,
        description
    ) VALUES (
        p_name,
        p_organization_id,
        p_access_list,
        p_tool_access,
        p_role,
        p_description
    ) RETURNING employee_id INTO v_employee_id;
    
    RETURN v_employee_id;
END;
$$ LANGUAGE plpgsql;

-- Function to add a function to an employee
CREATE OR REPLACE FUNCTION emp_add_function(
    p_employee_id UUID,
    p_name VARCHAR(255),
    p_description TEXT DEFAULT NULL,
    p_required_tools JSONB DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    v_function_id UUID;
BEGIN
    INSERT INTO emp_functions (
        employee_id,
        name,
        description,
        required_tools
    ) VALUES (
        p_employee_id,
        p_name,
        p_description,
        p_required_tools
    ) RETURNING function_id INTO v_function_id;
    
    RETURN v_function_id;
END;
$$ LANGUAGE plpgsql;

-- Function to create an SOP for a function
CREATE OR REPLACE FUNCTION emp_create_sop(
    p_function_id UUID,
    p_title VARCHAR(255),
    p_description TEXT DEFAULT NULL,
    p_tools_used JSONB DEFAULT NULL,
    p_version VARCHAR(50) DEFAULT '1.0'
) RETURNS UUID AS $$
DECLARE
    v_sop_id UUID;
BEGIN
    INSERT INTO emp_sops (
        function_id,
        title,
        description,
        tools_used,
        version
    ) VALUES (
        p_function_id,
        p_title,
        p_description,
        p_tools_used,
        p_version
    ) RETURNING sop_id INTO v_sop_id;
    
    RETURN v_sop_id;
END;
$$ LANGUAGE plpgsql;

-- Function to add a step to an SOP
CREATE OR REPLACE FUNCTION emp_add_step(
    p_sop_id UUID,
    p_step_number INTEGER,
    p_title VARCHAR(255),
    p_description TEXT DEFAULT NULL,
    p_questions JSONB DEFAULT NULL,
    p_actions JSONB DEFAULT NULL,
    p_tools JSONB DEFAULT NULL,
    p_expected_outcome TEXT DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    v_step_id UUID;
    v_prev_step_id UUID;
BEGIN
    -- Get the ID of the previous step (if any)
    SELECT step_id INTO v_prev_step_id
    FROM emp_steps
    WHERE sop_id = p_sop_id AND step_number = p_step_number - 1;
    
    -- Insert the new step
    INSERT INTO emp_steps (
        sop_id,
        step_number,
        title,
        description,
        questions,
        actions,
        tools,
        expected_outcome
    ) VALUES (
        p_sop_id,
        p_step_number,
        p_title,
        p_description,
        p_questions,
        p_actions,
        p_tools,
        p_expected_outcome
    ) RETURNING step_id INTO v_step_id;
    
    -- Update the next_step of the previous step (if any)
    IF v_prev_step_id IS NOT NULL THEN
        UPDATE emp_steps
        SET next_step = v_step_id
        WHERE step_id = v_prev_step_id;
    END IF;
    
    RETURN v_step_id;
END;
$$ LANGUAGE plpgsql;

-- Function to create a new task log
CREATE OR REPLACE FUNCTION emp_create_task_log(
    p_task_id UUID,
    p_employee_id UUID,
    p_user_id UUID,
    p_function_id UUID,
    p_sop_id UUID DEFAULT NULL,
    p_notes TEXT DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    v_log_id UUID;
    v_metadata_id UUID;
    v_has_access BOOLEAN;
BEGIN
    -- Check if the user has access to the employee
    SELECT emp_check_access(p_employee_id, p_user_id) INTO v_has_access;
    
    IF NOT v_has_access THEN
        RAISE EXCEPTION 'User does not have access to this employee';
    END IF;
    
    -- Create metadata record
    INSERT INTO emp_metadata (
        task_id,
        user_id,
        content
    ) VALUES (
        p_task_id,
        p_user_id,
        '{}'::jsonb
    ) RETURNING metadata_id INTO v_metadata_id;
    
    -- Create task log
    INSERT INTO emp_task_logs (
        task_id,
        employee_id,
        user_id,
        function_id,
        sop_id,
        status,
        notes,
        metadata_id
    ) VALUES (
        p_task_id,
        p_employee_id,
        p_user_id,
        p_function_id,
        p_sop_id,
        'started',
        p_notes,
        v_metadata_id
    ) RETURNING log_id INTO v_log_id;
    
    RETURN v_log_id;
END;
$$ LANGUAGE plpgsql;

-- Function to update task progress
CREATE OR REPLACE FUNCTION emp_update_task_progress(
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
BEGIN
    -- Get the task log ID
    SELECT log_id INTO v_task_log_id
    FROM emp_task_logs
    WHERE task_id = p_task_id AND user_id = p_user_id;
    
    IF v_task_log_id IS NULL THEN
        RAISE EXCEPTION 'Task log not found for task_id % and user_id %', p_task_id, p_user_id;
    END IF;
    
    -- Set completed_at if task is being marked as complete
    IF p_completion_flag IS TRUE THEN
        v_completed_at := CURRENT_TIMESTAMP;
    END IF;
    
    -- Update the task log
    UPDATE emp_task_logs
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
CREATE OR REPLACE FUNCTION emp_update_metadata(
    p_task_id UUID,
    p_user_id UUID,
    p_content JSONB
) RETURNS BOOLEAN AS $$
DECLARE
    v_metadata_id UUID;
BEGIN
    -- Get the metadata ID
    SELECT metadata_id INTO v_metadata_id
    FROM emp_metadata
    WHERE task_id = p_task_id AND user_id = p_user_id;
    
    IF v_metadata_id IS NULL THEN
        RAISE EXCEPTION 'Metadata not found for task_id % and user_id %', p_task_id, p_user_id;
    END IF;
    
    -- Update the metadata
    UPDATE emp_metadata
    SET content = p_content
    WHERE metadata_id = v_metadata_id;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- Function to get task metadata
CREATE OR REPLACE FUNCTION emp_get_metadata(
    p_task_id UUID,
    p_user_id UUID
) RETURNS JSONB AS $$
DECLARE
    v_content JSONB;
BEGIN
    SELECT content INTO v_content
    FROM emp_metadata
    WHERE task_id = p_task_id AND user_id = p_user_id;
    
    RETURN v_content;
END;
$$ LANGUAGE plpgsql;

-- Function to get active tasks for a user
CREATE OR REPLACE FUNCTION emp_get_user_tasks(
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
            e.name AS employee_name,
            tl.function_id,
            f.name AS function_name,
            tl.sop_id,
            s.title AS sop_title,
            tl.current_step_id,
            st.title AS current_step_title,
            st.step_number AS current_step_number,
            tl.status,
            tl.completion_flag,
            tl.progress_percentage,
            tl.started_at,
            tl.updated_at,
            tl.completed_at,
            tl.notes,
            tl.metadata_id,
            m.content AS metadata
        FROM emp_task_logs tl
        JOIN emp_employees e ON tl.employee_id = e.employee_id
        JOIN emp_functions f ON tl.function_id = f.function_id
        LEFT JOIN emp_sops s ON tl.sop_id = s.sop_id
        LEFT JOIN emp_steps st ON tl.current_step_id = st.step_id
        LEFT JOIN emp_metadata m ON tl.metadata_id = m.metadata_id
        WHERE tl.user_id = p_user_id
        AND (p_include_completed OR tl.completion_flag = FALSE)
    )
    SELECT jsonb_agg(
        jsonb_build_object(
            'task_id', td.task_id,
            'log_id', td.log_id,
            'employee', jsonb_build_object(
                'employee_id', td.employee_id,
                'name', td.employee_name
            ),
            'function', jsonb_build_object(
                'function_id', td.function_id,
                'name', td.function_name
            ),
            'sop', CASE WHEN td.sop_id IS NOT NULL THEN
                jsonb_build_object(
                    'sop_id', td.sop_id,
                    'title', td.sop_title
                )
            ELSE NULL END,
            'current_step', CASE WHEN td.current_step_id IS NOT NULL THEN
                jsonb_build_object(
                    'step_id', td.current_step_id,
                    'title', td.current_step_title,
                    'step_number', td.current_step_number
                )
            ELSE NULL END,
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

-- Function to check if a user has access to an employee
CREATE OR REPLACE FUNCTION emp_check_access(
    p_employee_id UUID,
    p_user_id UUID
) RETURNS BOOLEAN AS $$
DECLARE
    v_has_access BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 
        FROM emp_employees 
        WHERE employee_id = p_employee_id 
        AND p_user_id = ANY(access_list)
    ) INTO v_has_access;
    
    RETURN v_has_access;
END;
$$ LANGUAGE plpgsql;

-- Function to get an employee with all related data
CREATE OR REPLACE FUNCTION emp_get_employee_full(
    p_employee_id UUID,
    p_user_id UUID
) RETURNS JSONB AS $$
DECLARE
    v_result JSONB;
    v_has_access BOOLEAN;
BEGIN
    -- Check if the user has access
    SELECT emp_check_access(p_employee_id, p_user_id) INTO v_has_access;
    
    IF NOT v_has_access THEN
        RETURN jsonb_build_object('error', 'Access denied');
    END IF;
    
    -- Get the employee data with functions, SOPs, and steps
    WITH employee_data AS (
        SELECT 
            e.employee_id,
            e.name,
            e.organization_id,
            e.access_list,
            e.tool_access,
            e.role,
            e.description,
            e.status,
            e.created_at,
            e.updated_at,
            jsonb_agg(
                jsonb_build_object(
                    'function_id', f.function_id,
                    'name', f.name,
                    'description', f.description,
                    'required_tools', f.required_tools,
                    'sops', (
                        SELECT jsonb_agg(
                            jsonb_build_object(
                                'sop_id', s.sop_id,
                                'title', s.title,
                                'description', s.description,
                                'tools_used', s.tools_used,
                                'version', s.version,
                                'last_updated', s.last_updated,
                                'steps', (
                                    SELECT jsonb_agg(
                                        jsonb_build_object(
                                            'step_id', st.step_id,
                                            'step_number', st.step_number,
                                            'title', st.title,
                                            'description', st.description,
                                            'questions', st.questions,
                                            'actions', st.actions,
                                            'tools', st.tools,
                                            'expected_outcome', st.expected_outcome,
                                            'next_step', st.next_step
                                        ) ORDER BY st.step_number
                                    )
                                    FROM emp_steps st
                                    WHERE st.sop_id = s.sop_id
                                )
                            )
                        )
                        FROM emp_sops s
                        WHERE s.function_id = f.function_id
                    )
                )
            ) FILTER (WHERE f.function_id IS NOT NULL) AS functions
        FROM emp_employees e
        LEFT JOIN emp_functions f ON e.employee_id = f.employee_id
        WHERE e.employee_id = p_employee_id
        GROUP BY e.employee_id
    )
    SELECT jsonb_build_object(
        'employee_id', ed.employee_id,
        'name', ed.name,
        'organization_id', ed.organization_id,
        'access_list', ed.access_list,
        'tool_access', ed.tool_access,
        'role', ed.role,
        'description', ed.description,
        'status', ed.status,
        'created_at', ed.created_at,
        'updated_at', ed.updated_at,
        'functions', COALESCE(ed.functions, '[]'::jsonb)
    ) INTO v_result
    FROM employee_data ed;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- Function to update an employee's status
CREATE OR REPLACE FUNCTION emp_update_employee_status(
    p_employee_id UUID,
    p_status VARCHAR(50)
) RETURNS BOOLEAN AS $$
BEGIN
    UPDATE emp_employees
    SET status = p_status
    WHERE employee_id = p_employee_id;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- Function to update an employee's tool access
CREATE OR REPLACE FUNCTION emp_update_tool_access(
    p_employee_id UUID,
    p_tool_access JSONB
) RETURNS BOOLEAN AS $$
BEGIN
    UPDATE emp_employees
    SET tool_access = p_tool_access
    WHERE employee_id = p_employee_id;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;

-- Function to update an employee's access list
CREATE OR REPLACE FUNCTION emp_update_access_list(
    p_employee_id UUID,
    p_access_list UUID[]
) RETURNS BOOLEAN AS $$
BEGIN
    UPDATE emp_employees
    SET access_list = p_access_list
    WHERE employee_id = p_employee_id;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql;