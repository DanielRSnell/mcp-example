-- Drop all existing tables and types (if they exist)
DROP TABLE IF EXISTS sqt_execution_steps CASCADE;
DROP TABLE IF EXISTS sqt_execution_plans CASCADE;
DROP TABLE IF EXISTS sqt_thoughts CASCADE;
DROP TABLE IF EXISTS sqt_branches CASCADE;
DROP TABLE IF EXISTS sqt_sessions CASCADE;

-- Drop any tables from previous version that might exist
DROP TABLE IF EXISTS execution_steps CASCADE;
DROP TABLE IF EXISTS execution_plans CASCADE;
DROP TABLE IF EXISTS thoughts CASCADE;
DROP TABLE IF EXISTS branches CASCADE;
DROP TABLE IF EXISTS sessions CASCADE;
DROP TABLE IF EXISTS thinking_sessions CASCADE;

-- Drop existing types with CASCADE to handle dependencies
DROP TYPE IF EXISTS sqt_execution_plan_status CASCADE;
DROP TYPE IF EXISTS sqt_thought_status CASCADE;
DROP TYPE IF EXISTS sqt_session_status CASCADE;
DROP TYPE IF EXISTS execution_plan_status CASCADE;
DROP TYPE IF EXISTS thought_status CASCADE;
DROP TYPE IF EXISTS session_status CASCADE;

-- Create enum types for session and thought status
CREATE TYPE sqt_session_status AS ENUM ('active', 'completed', 'abandoned');
CREATE TYPE sqt_thought_status AS ENUM ('active', 'completed', 'paused', 'abandoned');
CREATE TYPE sqt_execution_plan_status AS ENUM ('draft', 'ready', 'in_progress', 'completed', 'abandoned');

-- Create a sessions table to track different thinking sessions
CREATE TABLE IF NOT EXISTS sqt_sessions (
    session_id VARCHAR(100) PRIMARY KEY,  -- Increased length to handle longer IDs
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status sqt_session_status DEFAULT 'active',
    title VARCHAR(255) NULL,
    description TEXT NULL
);

-- Create a thoughts table to store individual thoughts
CREATE TABLE IF NOT EXISTS sqt_thoughts (
    thought_id SERIAL PRIMARY KEY,
    session_id VARCHAR(100) NOT NULL,  -- Match with sessions table
    thought_number INT NOT NULL,
    total_thoughts INT NOT NULL,
    thought TEXT NOT NULL,
    next_thought_needed BOOLEAN DEFAULT TRUE,
    is_revision BOOLEAN DEFAULT FALSE,
    revises_thought_id INT NULL,
    branch_from_thought_id INT NULL,
    branch_id VARCHAR(100) NULL,  -- Increased length
    needs_more_thoughts BOOLEAN DEFAULT FALSE,
    status sqt_thought_status DEFAULT 'active',
    user_paused BOOLEAN DEFAULT FALSE,
    execution_state JSONB DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (session_id) REFERENCES sqt_sessions(session_id) ON DELETE CASCADE,
    FOREIGN KEY (revises_thought_id) REFERENCES sqt_thoughts(thought_id) ON DELETE SET NULL,
    FOREIGN KEY (branch_from_thought_id) REFERENCES sqt_thoughts(thought_id) ON DELETE SET NULL
);

-- Create a branches table to track thought branches
CREATE TABLE IF NOT EXISTS sqt_branches (
    branch_id VARCHAR(100) PRIMARY KEY,  -- Increased length
    session_id VARCHAR(100) NOT NULL,   -- Match with sessions table
    parent_branch_id VARCHAR(100) NULL,  -- Increased length
    branch_name VARCHAR(255) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (session_id) REFERENCES sqt_sessions(session_id) ON DELETE CASCADE,
    FOREIGN KEY (parent_branch_id) REFERENCES sqt_branches(branch_id) ON DELETE SET NULL
);

-- Create execution plans table
CREATE TABLE IF NOT EXISTS sqt_execution_plans (
    plan_id SERIAL PRIMARY KEY,
    session_id VARCHAR(100) NOT NULL,  -- Match with sessions table
    thought_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NULL,
    status sqt_execution_plan_status DEFAULT 'draft',
    user_notified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (session_id) REFERENCES sqt_sessions(session_id) ON DELETE CASCADE,
    FOREIGN KEY (thought_id) REFERENCES sqt_thoughts(thought_id) ON DELETE CASCADE
);

-- Create execution steps table
CREATE TABLE IF NOT EXISTS sqt_execution_steps (
    step_id SERIAL PRIMARY KEY,
    plan_id INT NOT NULL,
    step_number INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    estimated_time VARCHAR(50) NULL,
    status VARCHAR(20) DEFAULT 'pending',
    is_completed BOOLEAN DEFAULT FALSE,
    depends_on_step_ids INT[] NULL,
    assigned_to VARCHAR(100) NULL,
    priority VARCHAR(20) DEFAULT 'medium',
    metadata JSONB NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (plan_id) REFERENCES sqt_execution_plans(plan_id) ON DELETE CASCADE
);

-- Create index for efficient queries
CREATE INDEX idx_sqt_thoughts_session_id ON sqt_thoughts(session_id);
CREATE INDEX idx_sqt_thoughts_branch_id ON sqt_thoughts(branch_id);
CREATE INDEX idx_sqt_branches_session_id ON sqt_branches(session_id);

-- Create a function to update updated_at timestamp automatically
CREATE OR REPLACE FUNCTION sqt_update_timestamp_column()
RETURNS TRIGGER 
LANGUAGE plpgsql
AS $function$
BEGIN
   NEW.updated_at = NOW(); 
   RETURN NEW;
END;
$function$;

-- Create triggers to update the updated_at column
CREATE TRIGGER update_sqt_sessions_timestamp 
BEFORE UPDATE ON sqt_sessions
FOR EACH ROW EXECUTE FUNCTION sqt_update_timestamp_column();

CREATE TRIGGER update_sqt_thoughts_timestamp 
BEFORE UPDATE ON sqt_thoughts
FOR EACH ROW EXECUTE FUNCTION sqt_update_timestamp_column();

CREATE TRIGGER update_sqt_execution_plans_timestamp 
BEFORE UPDATE ON sqt_execution_plans
FOR EACH ROW EXECUTE FUNCTION sqt_update_timestamp_column();

CREATE TRIGGER update_sqt_execution_steps_timestamp 
BEFORE UPDATE ON sqt_execution_steps
FOR EACH ROW EXECUTE FUNCTION sqt_update_timestamp_column();

-- Create a new session
CREATE OR REPLACE FUNCTION sqt_create_session(
    p_session_id VARCHAR(100),  -- Increased length
    p_title VARCHAR(255),
    p_description TEXT
) 
RETURNS TABLE (session_id VARCHAR(100), created_at TIMESTAMP)  -- Increased length
LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO sqt_sessions (session_id, title, description)
    VALUES (p_session_id, p_title, p_description);
    
    RETURN QUERY
    SELECT s.session_id, s.created_at 
    FROM sqt_sessions s 
    WHERE s.session_id = p_session_id;
END;
$function$;

-- Add a thought to a session
CREATE OR REPLACE FUNCTION sqt_add_thought(
    p_session_id VARCHAR(100),  -- Increased length
    p_thought_number INT,
    p_total_thoughts INT,
    p_thought TEXT,
    p_next_thought_needed BOOLEAN,
    p_is_revision BOOLEAN,
    p_revises_thought_id INT,
    p_branch_from_thought_id INT,
    p_branch_id VARCHAR(100),  -- Increased length
    p_needs_more_thoughts BOOLEAN
) 
RETURNS TABLE (
    thought_id INT,
    session_id VARCHAR(100),  -- Increased length
    thought_number INT,
    total_thoughts INT,
    next_thought_needed BOOLEAN,
    branch_id VARCHAR(100)  -- Increased length
)
LANGUAGE plpgsql
AS $function$
DECLARE
    v_branch_exists INT;
    v_new_thought_id INT;
BEGIN
    -- Check if session exists
    IF NOT EXISTS (SELECT 1 FROM sqt_sessions WHERE session_id = p_session_id) THEN
        RAISE EXCEPTION 'Session does not exist';
    END IF;
    
    -- Check if branch exists if it's provided
    IF p_branch_id IS NOT NULL THEN
        SELECT COUNT(*) INTO v_branch_exists FROM sqt_branches WHERE branch_id = p_branch_id;
        
        IF v_branch_exists = 0 THEN
            -- Create the branch if it doesn't exist
            INSERT INTO sqt_branches (branch_id, session_id, parent_branch_id)
            VALUES (p_branch_id, p_session_id, NULL);
        END IF;
    END IF;
    
    -- Insert the thought
    INSERT INTO sqt_thoughts (
        session_id, 
        thought_number, 
        total_thoughts, 
        thought, 
        next_thought_needed, 
        is_revision, 
        revises_thought_id, 
        branch_from_thought_id, 
        branch_id, 
        needs_more_thoughts
    )
    VALUES (
        p_session_id, 
        p_thought_number, 
        p_total_thoughts, 
        p_thought, 
        p_next_thought_needed, 
        p_is_revision, 
        p_revises_thought_id, 
        p_branch_from_thought_id, 
        p_branch_id, 
        p_needs_more_thoughts
    )
    RETURNING thought_id INTO v_new_thought_id;
    
    -- Update the session's updated_at timestamp
    UPDATE sqt_sessions SET updated_at = CURRENT_TIMESTAMP WHERE session_id = p_session_id;
    
    -- Return the inserted thought
    RETURN QUERY
    SELECT 
        t.thought_id, 
        t.session_id, 
        t.thought_number, 
        t.total_thoughts,
        t.next_thought_needed,
        t.branch_id
    FROM sqt_thoughts t
    WHERE t.thought_id = v_new_thought_id;
END;
$function$;

-- Get all thoughts for a session
CREATE OR REPLACE FUNCTION sqt_get_session_thoughts(
    p_session_id VARCHAR(100)  -- Increased length
) 
RETURNS TABLE (
    thought_id INT,
    thought_number INT,
    total_thoughts INT,
    thought TEXT,
    next_thought_needed BOOLEAN,
    is_revision BOOLEAN,
    revises_thought_id INT,
    branch_from_thought_id INT,
    branch_id VARCHAR(100),  -- Increased length
    needs_more_thoughts BOOLEAN,
    created_at TIMESTAMP
)
LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        t.thought_id, 
        t.thought_number, 
        t.total_thoughts, 
        t.thought, 
        t.next_thought_needed, 
        t.is_revision, 
        t.revises_thought_id, 
        t.branch_from_thought_id, 
        t.branch_id, 
        t.needs_more_thoughts,
        t.created_at
    FROM sqt_thoughts t
    WHERE t.session_id = p_session_id
    ORDER BY t.created_at ASC;
END;
$function$;

-- Get branch information for a session
CREATE OR REPLACE FUNCTION sqt_get_session_branches(
    p_session_id VARCHAR(100)  -- Increased length
) 
RETURNS TABLE (
    branch_id VARCHAR(100),  -- Increased length
    parent_branch_id VARCHAR(100),  -- Increased length
    branch_name VARCHAR(255),
    created_at TIMESTAMP,
    thought_count BIGINT
)
LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        b.branch_id, 
        b.parent_branch_id, 
        b.branch_name,
        b.created_at,
        COUNT(t.thought_id) AS thought_count
    FROM sqt_branches b
    LEFT JOIN sqt_thoughts t ON b.branch_id = t.branch_id
    WHERE b.session_id = p_session_id
    GROUP BY b.branch_id, b.parent_branch_id, b.branch_name, b.created_at
    ORDER BY b.created_at ASC;
END;
$function$;

-- Complete a session
CREATE OR REPLACE FUNCTION sqt_complete_session(
    p_session_id VARCHAR(100)  -- Increased length
) 
RETURNS TABLE (
    session_id VARCHAR(100),  -- Increased length
    status sqt_session_status,
    updated_at TIMESTAMP
)
LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE sqt_sessions 
    SET status = 'completed', updated_at = CURRENT_TIMESTAMP 
    WHERE session_id = p_session_id;
    
    -- Also mark all thoughts as completed
    UPDATE sqt_thoughts
    SET status = 'completed'
    WHERE session_id = p_session_id AND status = 'active';
    
    RETURN QUERY
    SELECT s.session_id, s.status, s.updated_at 
    FROM sqt_sessions s
    WHERE s.session_id = p_session_id;
END;
$function$;

-- Pause a thought (user initiated)
CREATE OR REPLACE FUNCTION sqt_pause_thought(
    p_thought_id INT,
    p_execution_state JSONB DEFAULT NULL
) 
RETURNS TABLE (
    thought_id INT,
    status sqt_thought_status,
    user_paused BOOLEAN,
    updated_at TIMESTAMP
)
LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE sqt_thoughts 
    SET status = 'paused', 
        user_paused = TRUE,
        execution_state = p_execution_state
    WHERE thought_id = p_thought_id;
    
    RETURN QUERY
    SELECT t.thought_id, t.status, t.user_paused, t.updated_at
    FROM sqt_thoughts t
    WHERE t.thought_id = p_thought_id;
END;
$function$;

-- Resume a thought
CREATE OR REPLACE FUNCTION sqt_resume_thought(
    p_thought_id INT
) 
RETURNS TABLE (
    thought_id INT,
    status sqt_thought_status,
    user_paused BOOLEAN,
    updated_at TIMESTAMP,
    execution_state JSONB
)
LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE sqt_thoughts 
    SET status = 'active', 
        user_paused = FALSE
    WHERE thought_id = p_thought_id;
    
    RETURN QUERY
    SELECT t.thought_id, t.status, t.user_paused, t.updated_at, t.execution_state
    FROM sqt_thoughts t
    WHERE t.thought_id = p_thought_id;
END;
$function$;

-- Get the active thought (or most recent thought) for a session
CREATE OR REPLACE FUNCTION sqt_get_active_thought(
    p_session_id VARCHAR(100)  -- Increased length
) 
RETURNS TABLE (
    thought_id INT,
    thought_number INT,
    total_thoughts INT,
    thought TEXT,
    status sqt_thought_status,
    user_paused BOOLEAN,
    next_thought_needed BOOLEAN,
    execution_state JSONB,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
)
LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        t.thought_id, 
        t.thought_number, 
        t.total_thoughts, 
        t.thought, 
        t.status,
        t.user_paused,
        t.next_thought_needed,
        t.execution_state,
        t.created_at,
        t.updated_at
    FROM sqt_thoughts t
    WHERE t.session_id = p_session_id
    AND (t.status = 'active' OR t.status = 'paused')
    ORDER BY 
        CASE WHEN t.status = 'active' THEN 0 ELSE 1 END,  -- Active thoughts first
        t.updated_at DESC  -- Most recently updated
    LIMIT 1;
END;
$function$;

-- Check if session needs to continue thinking
CREATE OR REPLACE FUNCTION sqt_needs_continued_thinking(
    p_session_id VARCHAR(100)  -- Increased length
) 
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $function$
DECLARE
    needs_more BOOLEAN;
BEGIN
    SELECT 
        EXISTS (
            SELECT 1 
            FROM sqt_thoughts t
            WHERE t.session_id = p_session_id
            AND t.next_thought_needed = TRUE
            AND t.status IN ('active', 'paused')
            AND (t.user_paused = FALSE OR t.user_paused IS NULL)
        )
    INTO needs_more;
    
    RETURN needs_more;
END;
$function$;

-- Create a function to generate an execution plan
CREATE OR REPLACE FUNCTION sqt_create_execution_plan(
    p_session_id VARCHAR(100),  -- Increased length
    p_thought_id INT,
    p_title VARCHAR(255),
    p_description TEXT
) 
RETURNS INT
LANGUAGE plpgsql
AS $function$
DECLARE
    v_plan_id INT;
BEGIN
    -- Insert the execution plan
    INSERT INTO sqt_execution_plans (
        session_id,
        thought_id,
        title,
        description,
        status
    )
    VALUES (
        p_session_id,
        p_thought_id,
        p_title,
        p_description,
        'draft'
    )
    RETURNING plan_id INTO v_plan_id;
    
    RETURN v_plan_id;
END;
$function$;

-- Add a step to an execution plan
CREATE OR REPLACE FUNCTION sqt_add_execution_step(
    p_plan_id INT,
    p_step_number INT,
    p_title VARCHAR(255),
    p_description TEXT,
    p_estimated_time VARCHAR(50) DEFAULT NULL,
    p_depends_on_step_ids INT[] DEFAULT NULL,
    p_assigned_to VARCHAR(100) DEFAULT NULL,
    p_priority VARCHAR(20) DEFAULT 'medium',
    p_metadata JSONB DEFAULT NULL
) 
RETURNS INT
LANGUAGE plpgsql
AS $function$
DECLARE
    v_step_id INT;
BEGIN
    -- Insert the execution step
    INSERT INTO sqt_execution_steps (
        plan_id,
        step_number,
        title,
        description,
        estimated_time,
        depends_on_step_ids,
        assigned_to,
        priority,
        metadata
    )
    VALUES (
        p_plan_id,
        p_step_number,
        p_title,
        p_description,
        p_estimated_time,
        p_depends_on_step_ids,
        p_assigned_to,
        p_priority,
        p_metadata
    )
    RETURNING step_id INTO v_step_id;
    
    RETURN v_step_id;
END;
$function$;

-- Mark an execution plan as ready
CREATE OR REPLACE FUNCTION sqt_finalize_execution_plan(
    p_plan_id INT
) 
RETURNS TABLE (
    plan_id INT,
    session_id VARCHAR(100),  -- Increased length
    thought_id INT,
    title VARCHAR(255),
    status sqt_execution_plan_status,
    user_notified BOOLEAN
)
LANGUAGE plpgsql
AS $function$
BEGIN
    -- Update the plan status
    UPDATE sqt_execution_plans
    SET status = 'ready',
        user_notified = FALSE
    WHERE plan_id = p_plan_id;
    
    -- Return the updated plan
    RETURN QUERY
    SELECT 
        ep.plan_id,
        ep.session_id,
        ep.thought_id,
        ep.title,
        ep.status,
        ep.user_notified
    FROM sqt_execution_plans ep
    WHERE ep.plan_id = p_plan_id;
END;
$function$;

-- Get plans that need user notification
CREATE OR REPLACE FUNCTION sqt_get_ready_plans_for_notification(
    p_session_id VARCHAR(100)  -- Increased length
) 
RETURNS TABLE (
    plan_id INT,
    thought_id INT,
    title VARCHAR(255),
    description TEXT,
    created_at TIMESTAMP
)
LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        ep.plan_id,
        ep.thought_id,
        ep.title,
        ep.description,
        ep.created_at
    FROM sqt_execution_plans ep
    WHERE ep.session_id = p_session_id
    AND ep.status = 'ready'
    AND ep.user_notified = FALSE
    ORDER BY ep.created_at DESC;
END;
$function$;

-- Mark a plan as notified
CREATE OR REPLACE FUNCTION sqt_mark_plan_as_notified(
    p_plan_id INT
) 
RETURNS VOID
LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE sqt_execution_plans
    SET user_notified = TRUE
    WHERE plan_id = p_plan_id;
END;
$function$;

-- Get full execution plan with steps
CREATE OR REPLACE FUNCTION sqt_get_execution_plan_with_steps(
    p_plan_id INT
) 
RETURNS TABLE (
    plan_id INT,
    session_id VARCHAR(100),  -- Increased length
    thought_id INT,
    plan_title VARCHAR(255),
    plan_description TEXT,
    plan_status sqt_execution_plan_status,
    step_id INT,
    step_number INT,
    step_title VARCHAR(255),
    step_description TEXT,
    step_status VARCHAR(20),
    is_completed BOOLEAN,
    estimated_time VARCHAR(50),
    depends_on_step_ids INT[],
    assigned_to VARCHAR(100),
    priority VARCHAR(20)
)
LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        ep.plan_id,
        ep.session_id,
        ep.thought_id,
        ep.title AS plan_title,
        ep.description AS plan_description,
        ep.status AS plan_status,
        es.step_id,
        es.step_number,
        es.title AS step_title,
        es.description AS step_description,
        es.status AS step_status,
        es.is_completed,
        es.estimated_time,
        es.depends_on_step_ids,
        es.assigned_to,
        es.priority
    FROM sqt_execution_plans ep
    JOIN sqt_execution_steps es ON ep.plan_id = es.plan_id
    WHERE ep.plan_id = p_plan_id
    ORDER BY es.step_number;
END;
$function$;

-- Update step completion status
CREATE OR REPLACE FUNCTION sqt_update_step_completion(
    p_step_id INT,
    p_is_completed BOOLEAN
) 
RETURNS VOID
LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE sqt_execution_steps
    SET 
        is_completed = p_is_completed,
        status = CASE WHEN p_is_completed THEN 'completed' ELSE 'in_progress' END
    WHERE step_id = p_step_id;
    
    -- Check if all steps are completed
    IF p_is_completed THEN
        -- Get the plan_id for this step
        WITH step_plan AS (
            SELECT plan_id FROM sqt_execution_steps WHERE step_id = p_step_id
        ),
        plan_completion AS (
            SELECT 
                sp.plan_id,
                CASE WHEN COUNT(*) = COUNT(CASE WHEN es.is_completed THEN 1 END) 
                     THEN TRUE 
                     ELSE FALSE 
                END AS all_completed
            FROM step_plan sp
            JOIN sqt_execution_steps es ON sp.plan_id = es.plan_id
            GROUP BY sp.plan_id
        )
        UPDATE sqt_execution_plans ep
        SET status = CASE WHEN pc.all_completed THEN 'completed' ELSE 'in_progress' END
        FROM plan_completion pc
        WHERE ep.plan_id = pc.plan_id
        AND pc.all_completed;
    END IF;
END;
$function$;