# Sequential Thinking Database API Instructions

> **Schema Update**: This version includes enhanced support for tracking thought states, pausing/resuming the thinking process, and storing execution state between thinking sessions.

This document explains how to use the Sequential Thinking Database API to store and retrieve your thought processes. The API allows you to maintain persistent thinking sessions across interactions with PostgreSQL.

## Getting Started

### Starting a New Session

To begin a new thinking session, generate a unique session ID and create a session:

```sql
-- Generate a unique session ID in PostgreSQL
SELECT 'session_' || extract(epoch from now()) || '_' || md5(random()::text) AS session_id;

-- Create the session in the database
SELECT * FROM create_session(
    'your_generated_session_id',
    'Problem Solving Session for [Problem Name]',
    'Thinking through the solution to [Problem Description]'
);
```

### Adding Thoughts

To add a thought to your session:

```sql
-- Add a thought
SELECT * FROM add_thought(
    'your_session_id',       -- Your session ID
    1,                       -- Current thought number (e.g., 1)
    5,                       -- Estimated total thoughts (e.g., 5)
    'This is my first thought about the problem...',  -- The actual thought content
    TRUE,                    -- Boolean: is another thought needed?
    FALSE,                   -- Boolean: is this revising an earlier thought?
    NULL,                    -- If revising, which thought ID (null if not)
    NULL,                    -- If branching, from which thought ID (null if not)
    NULL,                    -- Branch identifier (null if main branch)
    FALSE                    -- Boolean: realizing more thoughts are needed
);
```

### Retrieving Session Thoughts

To retrieve all thoughts in a session:

```sql
-- Retrieve all thoughts for a session
SELECT * FROM get_session_thoughts('your_session_id');
```

### Managing Branches

To get information about branches in a session:

```sql
-- Retrieve branch information for a session
SELECT * FROM get_session_branches('your_session_id');
```

### Completing a Session

When you've reached a satisfactory conclusion:

```sql
-- Mark a session as complete
SELECT * FROM complete_session('your_session_id');
```

## Thought Patterns

### Regular Thought Progression

For a standard thought in the main sequence:

```sql
-- Adding a standard sequential thought
SELECT * FROM add_thought(
    'your_session_id',      -- Your session ID
    2,                      -- Thought number 2
    5,                      -- Estimating 5 total thoughts
    'This is my second step in reasoning about the problem...',
    TRUE,                   -- Another thought is needed
    FALSE,                  -- Not a revision
    NULL,                   -- Not revising any thought
    NULL,                   -- Not branching
    NULL,                   -- No branch ID
    FALSE                   -- Not needing more thoughts than expected
);
```

### Revising a Previous Thought

To revise a previous thought:

```sql
-- First, find the thought ID you want to revise
SELECT thought_id FROM thoughts
WHERE session_id = 'your_session_id' AND thought_number = 1;

-- Now add a revision thought
SELECT * FROM add_thought(
    'your_session_id',
    3,                      -- Thought number 3
    5,                      -- Still estimating 5 total thoughts
    'On second thought, my first point needs refinement because...',
    TRUE,                   -- Another thought is needed
    TRUE,                   -- This is a revision
    1,                      -- Revising thought ID 1 (use the actual ID from the query above)
    NULL,                   -- Not branching
    NULL,                   -- No branch ID
    FALSE                   -- Not needing more thoughts than expected
);
```

### Creating a Branch

To explore an alternative path:

```sql
-- First, find the thought ID you want to branch from
SELECT thought_id FROM thoughts
WHERE session_id = 'your_session_id' AND thought_number = 2;

-- Generate a unique branch ID
SELECT 'branch_' || extract(epoch from now()) || '_' || md5(random()::text) AS branch_id;

-- Now add a branching thought
SELECT * FROM add_thought(
    'your_session_id',
    4,                      -- Thought number 4
    6,                      -- Now estimating 6 total thoughts
    'Let''s explore an alternative approach...',
    TRUE,                   -- Another thought is needed
    FALSE,                  -- Not a revision
    NULL,                   -- Not revising any thought
    2,                      -- Branching from thought ID 2 (use the actual ID from the query above)
    'your_generated_branch_id',  -- New branch identifier from above
    FALSE                   -- Not needing more thoughts than expected
);
```

### Realizing More Thoughts Are Needed

When you initially thought you were done but need to continue:

```sql
SELECT * FROM add_thought(
    'your_session_id',
    5,                      -- Thought number 5 (what we thought was the last)
    7,                      -- Now estimating 7 total thoughts
    'I realize we need to consider one more aspect...',
    TRUE,                   -- Another thought is needed
    FALSE,                  -- Not a revision
    NULL,                   -- Not revising any thought
    NULL,                   -- Not branching
    NULL,                   -- No branch ID
    TRUE                    -- Realizing more thoughts are needed
);
```

### Final Thought with Conclusion

When reaching a satisfactory conclusion:

```sql
-- Add the final thought
SELECT * FROM add_thought(
    'your_session_id',
    7,                      -- Final thought number
    7,                      -- Total thoughts
    'After considering all aspects, the solution is...',
    FALSE,                  -- No more thoughts needed
    FALSE,                  -- Not a revision
    NULL,                   -- Not revising any thought
    NULL,                   -- Not branching
    NULL,                   -- No branch ID
    FALSE                   -- Not needing more thoughts
);

-- Mark the session as complete
SELECT * FROM complete_session('your_session_id');
```

## Error Handling

PostgreSQL will raise exceptions for errors. You can handle them using exception blocks in PL/pgSQL or in your application code:

```sql
-- Example of error handling in a PL/pgSQL function
CREATE OR REPLACE FUNCTION safe_add_thought(
    p_session_id VARCHAR(50),
    p_thought_number INT,
    p_total_thoughts INT,
    p_thought TEXT,
    p_next_thought_needed BOOLEAN
) RETURNS TEXT AS $$
BEGIN
    -- Try to add the thought with minimal parameters
    PERFORM add_thought(
        p_session_id,
        p_thought_number,
        p_total_thoughts,
        p_thought,
        p_next_thought_needed,
        FALSE, NULL, NULL, NULL, FALSE
    );

    RETURN 'Thought added successfully';
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'Error adding thought: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Usage
SELECT safe_add_thought(
    'your_session_id',
    1,
    5,
    'This is my first thought',
    TRUE
);
```

## Database Connection Management

When connecting to the PostgreSQL database, ensure you're using the correct connection parameters:

```sql
-- Example connection string format
-- postgresql://username:password@hostname:port/database

-- To connect using psql CLI:
psql -h hostname -p port -U username -d sequential_thinking
```

If you're using a programming language or application:

```python
# Python example with psycopg2
import psycopg2

conn = psycopg2.connect(
    host="localhost",
    database="sequential_thinking",
    user="your_username",
    password="your_password"
)

cur = conn.cursor()

# Example: Create a session
session_id = "session_123456"
cur.execute(
    "SELECT * FROM create_session(%s, %s, %s)",
    (session_id, "Test Session", "A test session description")
)
result = cur.fetchone()
print(f"Created session: {result}")

# Don't forget to commit and close
conn.commit()
cur.close()
conn.close()
```

## Managing Thought Execution States

### Checking If Thinking Should Continue

Before generating the next thought, check if the session needs to continue thinking:

```sql
-- Check if the session needs more thoughts
SELECT needs_continued_thinking('your_session_id');
```

This function will return `TRUE` if:

- There's at least one thought that has `next_thought_needed = TRUE`
- That thought is either `active` or `paused`
- The thought is not paused by the user (`user_paused = FALSE` or NULL)

### Getting the Current Active Thought

To retrieve the current active thought (or most recently paused thought) for a session:

```sql
-- Get the current active or most recently paused thought
SELECT * FROM get_active_thought('your_session_id');
```

This will return the active thought or the most recently paused thought, which helps determine where to resume the thinking process.

### Pausing Thought Execution

When a user wants to temporarily pause the thinking process or the AI needs to pause execution to await further input:

```sql
-- Pause a thought and store the execution state
SELECT * FROM pause_thought(
    123,  -- thought_id to pause
    '{"step": 3, "context": {"variables": {"x": 10}}, "progress": 0.7}'  -- Optional execution state as JSON
);
```

The execution state field allows storing arbitrary JSON data that represents the AI's internal state, which can be used to resume execution later.

### Resuming Thought Execution

When ready to continue a paused thought:

```sql
-- Resume a paused thought
SELECT * FROM resume_thought(123);  -- thought_id to resume
```

This will mark the thought as `active` again and return the stored execution state so the AI can continue from where it left off.

## Execution Planning

> **NEW FEATURE**: The system now supports creating executable plans from your sequential thoughts!

Once you've completed the thinking process and have a solid plan, you can convert it into an actionable execution plan with specific steps. This creates a task queue that users can work through systematically.

### Creating an Execution Plan

After finalizing your thoughts, create an execution plan:

```sql
-- Create a new execution plan
SELECT create_execution_plan(
    'your_session_id',                -- Session ID
    42,                               -- The thought ID that generated this plan
    'Implementation Plan for Project X', -- Plan title
    'Step-by-step guide to implement the features discussed in the thinking process'  -- Plan description
);
```

### Adding Execution Steps

Once you have a plan, add specific steps:

```sql
-- Add execution steps
SELECT add_execution_step(
    1,                              -- Plan ID
    1,                              -- Step number
    'Set up development environment', -- Step title
    'Install Node.js, PostgreSQL, and clone the repository',  -- Description
    '2 hours',                      -- Estimated time
    NULL,                           -- Dependencies (no prior steps)
    'Developer Team',               -- Assigned to
    'high',                         -- Priority
    '{"tools": ["git", "npm"]}'     -- Additional metadata as JSON
);

SELECT add_execution_step(
    1,                              -- Plan ID
    2,                              -- Step number
    'Database schema setup',        -- Step title
    'Create tables and relationships according to the design',  -- Description
    '4 hours',                      -- Estimated time
    ARRAY[1],                       -- Depends on step 1
    'Database Admin',               -- Assigned to
    'high',                         -- Priority
    NULL                            -- No additional metadata
);
```

### Finalizing the Plan

When all steps are added, mark the plan as ready for execution:

```sql
-- Mark the plan as ready for execution
SELECT * FROM finalize_execution_plan(1);  -- Plan ID
```

### Notifying Users of Ready Plans

When a user connects to the session, check if there are plans ready for notification:

```sql
-- Check for plans ready for user notification
SELECT * FROM get_ready_plans_for_notification('your_session_id');
```

If this returns results, notify the user that execution plans are ready, then mark them as notified:

```sql
-- Mark the plan as notified
SELECT mark_plan_as_notified(1);  -- Plan ID
```

### Retrieving Full Plan with Steps

To get the complete execution plan with all steps:

```sql
-- Get the full plan with all steps
SELECT * FROM get_execution_plan_with_steps(1);  -- Plan ID
```

### Tracking Execution Progress

As steps are completed, update their status:

```sql
-- Mark a step as completed
SELECT update_step_completion(2, TRUE);  -- Step ID, is_completed

-- Mark a step as incomplete (if needs revision)
SELECT update_step_completion(2, FALSE);  -- Step ID, is_completed=false
```

The system will automatically update the plan status to 'completed' when all steps are marked complete.

### Execution Plan Workflow

1. Complete sequential thinking process
2. Create an execution plan based on final thoughts
3. Add detailed steps with dependencies, assignments, and timeframes
4. Finalize the plan to mark it ready
5. Notify the user of ready plans
6. Track progress as steps are completed
7. System automatically updates overall plan status

This execution planning feature bridges the gap between thinking and doing, providing a clear path from ideation to implementation.

## Advanced Queries

### Getting the Latest Thought in a Session

```sql
-- Get the most recent thought in a session
SELECT * FROM thoughts
WHERE session_id = 'your_session_id'
ORDER BY created_at DESC
LIMIT 1;
```

### Finding Revision Chains

```sql
-- Find all revisions of a specific thought
WITH RECURSIVE revision_chain AS (
    -- Start with the original thought
    SELECT thought_id, thought_number, thought, 0 AS revision_level
    FROM thoughts
    WHERE thought_id = 1  -- The original thought ID

    UNION

    -- Add all thoughts that revise this one
    SELECT t.thought_id, t.thought_number, t.thought, rc.revision_level + 1
    FROM thoughts t
    JOIN revision_chain rc ON t.revises_thought_id = rc.thought_id
)
SELECT * FROM revision_chain
ORDER BY revision_level;
```

### Branch Analysis

```sql
-- Get all thoughts in a specific branch ordered by thought number
SELECT *
FROM thoughts
WHERE branch_id = 'your_branch_id'
ORDER BY thought_number;

-- Get counts of thoughts per branch in a session
SELECT branch_id, COUNT(*) AS thought_count
FROM thoughts
WHERE session_id = 'your_session_id' AND branch_id IS NOT NULL
GROUP BY branch_id
ORDER BY thought_count DESC;
```

Remember to maintain session continuity by preserving and reusing the session ID across interactions that are part of the same reasoning process.
