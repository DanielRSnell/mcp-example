# Project Management Control Protocol - Instructions

## Overview

This document provides a comprehensive guide on how to interact with the Project Management database using the operations defined in the `instructions` table. The PMCP system follows a sequential, approval-based workflow for executing database operations.

## Workflow Process

The PMCP system follows a structured workflow for database operations:

1. **Plan Operations**: Identify which instructions are needed from the `INSTRUCTIONS` table
2. **Sequence Operations**: Determine the optimal order of execution
3. **Craft Response**: Prepare a detailed plan to present to the user
4. **Wait for Approval**: Present the plan and wait for explicit user approval
5. **Execute Operations**: Run approved operations in sequence

## Querying the Instructions Table

The `instructions` table serves as a repository of query templates and documentation. You can retrieve operations from this table using various queries:

### Basic Query

```sql
SELECT 
    id,
    operation,
    description,
    query_example,
    parameters
FROM 
    instructions
ORDER BY 
    operation;
```

### Formatted Output Query

```sql
SELECT 
    operation AS "Operation",
    description AS "Description",
    '-- Example Query:
' || query_example AS "Query Example",
    '-- Parameters:
' || parameters AS "Parameters"
FROM 
    instructions
ORDER BY 
    operation;
```

### Find Instructions by Keyword

```sql
SELECT 
    operation,
    description
FROM 
    instructions
WHERE 
    operation ILIKE '%issue%'
    OR description ILIKE '%issue%'
ORDER BY 
    operation;
```

### Get Instructions by Operation Type

```sql
SELECT 
    operation,
    description
FROM 
    instructions
WHERE 
    operation LIKE 'GET_%'
ORDER BY 
    operation;
```

## Common Operations

### Client Management

#### CREATE_CLIENT
Creates a new client in the system.

```sql
INSERT INTO clients (name, logo)
VALUES ($1, $2)
RETURNING id, name;
```

**Parameters:**
- name (varchar): Client name
- logo (text): URL or path to client logo image

#### GET_ALL_CLIENTS
Retrieves all clients with project counts.

```sql
SELECT c.id, c.name, c.logo, COUNT(p.id) as project_count
FROM clients c
LEFT JOIN projects p ON c.id = p.client_id
GROUP BY c.id, c.name, c.logo
ORDER BY c.name;
```

**Parameters:** None required

### Project Management

#### CREATE_PROJECT
Creates a new project associated with a client.

```sql
INSERT INTO projects (title, description, client_id)
VALUES ($1, $2, $3)
RETURNING id, title;
```

**Parameters:**
- title (varchar): Project title
- description (text): Project description
- client_id (integer): Associated client ID

#### GET_CLIENT_PROJECTS
Retrieves all projects for a specific client.

```sql
SELECT p.id, p.title, p.description, 
       COUNT(i.id) as issue_count,
       SUM(CASE WHEN i.status = 'done' THEN 1 ELSE 0 END) as completed_issues
FROM projects p
LEFT JOIN issues i ON p.id = i.project_id
WHERE p.client_id = $1
GROUP BY p.id, p.title, p.description
ORDER BY p.title;
```

**Parameters:**
- client_id (integer): The client ID to filter by

#### GET_PROJECT_SUMMARY
Gets a summary of a project with issue counts by status.

```sql
SELECT p.id, p.title, c.name as client_name,
       COUNT(i.id) as total_issues,
       SUM(CASE WHEN i.status = 'backlog' THEN 1 ELSE 0 END) as backlog_count,
       SUM(CASE WHEN i.status = 'todo' THEN 1 ELSE 0 END) as todo_count,
       SUM(CASE WHEN i.status = 'in_progress' THEN 1 ELSE 0 END) as in_progress_count,
       SUM(CASE WHEN i.status = 'review' THEN 1 ELSE 0 END) as review_count,
       SUM(CASE WHEN i.status = 'done' THEN 1 ELSE 0 END) as done_count
FROM projects p
LEFT JOIN clients c ON p.client_id = c.id
LEFT JOIN issues i ON i.project_id = p.id
WHERE p.id = $1
GROUP BY p.id, p.title, c.name;
```

**Parameters:**
- project_id (integer): The project ID to summarize

#### GET_PROJECT_PROGRESS
Gets the overall progress of a project based on completed vs total issues.

```sql
SELECT p.id, p.title,
       COUNT(i.id) as total_issues,
       SUM(CASE WHEN i.status = 'done' THEN 1 ELSE 0 END) as completed_issues,
       CASE 
           WHEN COUNT(i.id) > 0 THEN 
               ROUND((SUM(CASE WHEN i.status = 'done' THEN 1 ELSE 0 END)::numeric / COUNT(i.id)::numeric) * 100, 2)
           ELSE 0
       END as completion_percentage
FROM projects p
LEFT JOIN issues i ON p.id = i.project_id
WHERE p.id = $1
GROUP BY p.id, p.title;
```

**Parameters:**
- project_id (integer): The project ID to get progress for

### Cycle Management

#### CREATE_CYCLE
Creates a new cycle for a project.

```sql
INSERT INTO cycles (name, project_id, start_date, end_date, status)
VALUES ($1, $2, $3, $4, $5)
RETURNING id, name;
```

**Parameters:**
- name (varchar): Cycle name
- project_id (integer): Associated project ID
- start_date (date): Cycle start date
- end_date (date): Cycle end date
- status (varchar): Cycle status (planned, active, completed)

#### GET_PROJECT_CYCLES
Retrieves all cycles for a specific project.

```sql
SELECT c.id, c.name, c.start_date, c.end_date, c.status,
       COUNT(i.id) as issue_count
FROM cycles c
LEFT JOIN issues i ON c.id = i.cycle_id
WHERE c.project_id = $1
GROUP BY c.id, c.name, c.start_date, c.end_date, c.status
ORDER BY c.start_date;
```

**Parameters:**
- project_id (integer): The project ID to filter by

#### GET_CYCLE_ISSUES
Gets all issues for a specific cycle.

```sql
SELECT i.id, i.title, i.status, i.priority, i.estimate, i.due_date
FROM issues i
WHERE i.cycle_id = $1
ORDER BY i.priority DESC, i.due_date ASC;
```

**Parameters:**
- cycle_id (integer): The cycle ID to query

#### MOVE_ISSUES_TO_CYCLE
Moves multiple issues to a specific cycle.

```sql
UPDATE issues
SET cycle_id = $1, updated_at = CURRENT_TIMESTAMP
WHERE id = ANY($2::int[])
RETURNING id, title;
```

**Parameters:**
- cycle_id (integer): The cycle ID to move issues to
- issue_ids (integer[]): Array of issue IDs to move

### Issue Management

#### CREATE_ISSUE
Creates a new issue in the system.

```sql
INSERT INTO issues (title, description, status, priority, estimate, due_date, project_id, cycle_id)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
RETURNING id;
```

**Parameters:**
- title (varchar): Issue title
- description (text): Issue description
- status (issue_status): Issue status
- priority (issue_priority): Issue priority
- estimate (float): Time estimate
- due_date (date): Due date
- project_id (integer): Associated project ID
- cycle_id (integer): Associated cycle ID (optional)

#### GET_ISSUES
Retrieves issues based on specified filters.

```sql
SELECT i.id, i.title, i.description, i.status, i.priority, i.estimate, i.due_date, 
       p.title as project_title, c.name as client_name
FROM issues i
JOIN projects p ON i.project_id = p.id
JOIN clients c ON p.client_id = c.id
WHERE i.status = $1 AND p.id = $2
ORDER BY i.priority DESC, i.due_date ASC;
```

**Parameters:**
- status (issue_status): The status to filter by
- project_id (integer): The project ID to filter by

#### UPDATE_ISSUE_STATUS
Updates the status of an issue.

```sql
UPDATE issues
SET status = $1, updated_at = CURRENT_TIMESTAMP
WHERE id = $2
RETURNING id, title, status;
```

**Parameters:**
- status (issue_status): The new status
- issue_id (integer): The issue ID to update

#### UPDATE_ISSUE
Updates an existing issue with new values.

```sql
UPDATE issues
SET title = $1, 
    description = $2,
    status = $3,
    priority = $4,
    estimate = $5,
    due_date = $6,
    cycle_id = $7,
    updated_at = CURRENT_TIMESTAMP
WHERE id = $8
RETURNING id, title;
```

**Parameters:**
- title (varchar): Issue title
- description (text): Issue description
- status (issue_status): Issue status
- priority (issue_priority): Issue priority
- estimate (float): Time estimate
- due_date (date): Due date
- cycle_id (integer): Associated cycle ID
- issue_id (integer): The issue ID to update

#### DELETE_ISSUE
Deletes an issue from the system.

```sql
DELETE FROM issues
WHERE id = $1
RETURNING id;
```

**Parameters:**
- issue_id (integer): The issue ID to delete

#### GET_ISSUE_DETAILS
Retrieves detailed information about an issue including project, client, and tags.

```sql
SELECT i.id, i.title, i.description, i.status, i.priority, i.estimate, i.due_date,
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
         i.created_at, i.updated_at, p.id, p.title, c.id, c.name, cy.id, cy.name;
```

**Parameters:**
- issue_id (integer): The issue ID to get details for

#### GET_ISSUES_BY_PRIORITY
Retrieves issues filtered by priority level.

```sql
SELECT i.id, i.title, i.status, i.priority, i.due_date,
       p.title as project_title
FROM issues i
JOIN projects p ON i.project_id = p.id
WHERE i.priority = $1
ORDER BY i.due_date ASC;
```

**Parameters:**
- priority (issue_priority): The priority level to filter by

#### GET_OVERDUE_ISSUES
Retrieves all issues that are past their due date and not completed.

```sql
SELECT i.id, i.title, i.status, i.priority, i.due_date,
       p.title as project_title, c.name as client_name
FROM issues i
JOIN projects p ON i.project_id = p.id
JOIN clients c ON p.client_id = c.id
WHERE i.due_date < CURRENT_DATE
  AND i.status != 'done'
ORDER BY i.due_date ASC, i.priority DESC;
```

**Parameters:** None required

### Tag Management

#### ADD_TAG_TO_ISSUE
Adds a tag to an issue.

```sql
INSERT INTO issue_tags (issue_id, tag_id)
VALUES ($1, $2)
ON CONFLICT (issue_id, tag_id) DO NOTHING
RETURNING issue_id, tag_id;
```

**Parameters:**
- issue_id (integer): The issue ID
- tag_id (integer): The tag ID

#### REMOVE_TAG_FROM_ISSUE
Removes a tag from an issue.

```sql
DELETE FROM issue_tags
WHERE issue_id = $1 AND tag_id = $2
RETURNING issue_id, tag_id;
```

**Parameters:**
- issue_id (integer): The issue ID
- tag_id (integer): The tag ID

### Comment Management

#### ADD_COMMENT_TO_ISSUE
Adds a comment to an issue.

```sql
INSERT INTO comments (issue_id, user_id, content)
VALUES ($1, $2, $3)
RETURNING id, content;
```

**Parameters:**
- issue_id (integer): The issue ID
- user_id (integer): The user ID making the comment
- content (text): The comment text

#### GET_ISSUE_COMMENTS
Retrieves all comments for a specific issue.

```sql
SELECT c.id, c.content, c.created_at, c.user_id
FROM comments c
WHERE c.issue_id = $1
ORDER BY c.created_at;
```

**Parameters:**
- issue_id (integer): The issue ID to get comments for

## Best Practices

1. **Use Transactions**: When multiple related operations need to be performed, use database transactions to ensure atomicity.

2. **Validate Inputs**: Validate all user inputs before constructing queries.

3. **Handle Errors Gracefully**: Provide clear error messages and recovery options when operations fail.

4. **Minimize Operations**: Use the minimum number of operations needed to fulfill the request.

5. **Communicate Clearly**: Explain what operations will be performed and why in non-technical terms.

6. **Use Rich Markdown**: Format descriptions and responses using rich markdown to improve readability and organization.

## Example Workflow

### User Request
"Create a new project called 'Website Redesign' for client 'Acme Corp'"

### System Response
```
# Proposed Database Operations

## Summary of Request
I'll help you create a new project for an existing client. This will require two operations: first checking if the client exists, then creating the project.

## Operations to Execute
1. **GET_ALL_CLIENTS**
   - Purpose: Check if 'Acme Corp' already exists in the database
   - Parameters: None

2. **CREATE_CLIENT** (Conditional)
   - Purpose: Create the client if it doesn't exist
   - Parameters:
     - name: 'Acme Corp'
     - logo: null
   - Note: Only if client doesn't exist

3. **CREATE_PROJECT**
   - Purpose: Create the new project
   - Parameters:
     - title: 'Website Redesign'
     - description: null
     - client_id: [ID from previous operations]

## Expected Outcome
A new project 'Website Redesign' will be created and associated with client 'Acme Corp'

## Approval Request
Would you like me to proceed with these operations?
```

### User Approval
"Yes, go ahead"

### Execution Response
```
# Operation Results

## Operations Executed
1. **GET_ALL_CLIENTS**
   - Status: Success
   - Result: Found client 'Acme Corp' with ID 5

2. **CREATE_PROJECT**
   - Status: Success
   - Result: Created project 'Website Redesign' with ID 12 for client 'Acme Corp' (ID: 5)

## Summary
Successfully created project 'Website Redesign' for existing client 'Acme Corp'
```

## Conclusion

This document provides a comprehensive guide to interacting with the Project Management database using the operations defined in the `instructions` table. By following the sequential, approval-based workflow and utilizing the provided operations, you can effectively manage clients, projects, cycles, issues, tags, and comments in the system.