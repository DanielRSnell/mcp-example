# Employee Creator Framework Schema Documentation

## Overview

This document provides a comprehensive guide to the Employee Creator Framework database schema, designed to create and manage virtual employees with task logging and metadata capabilities. The schema is integrated with the Project Manager module to enable employee assignment to projects and issues.

## Database Tables

### Organization Management Tables

#### `emp_organizations`
```sql
CREATE TABLE IF NOT EXISTS emp_organizations (
    organization_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```
- **Purpose**: Stores organization information
- **Key Fields**:
  - `organization_id`: Unique identifier for the organization
  - `name`: Organization name

#### `emp_users`
```sql
CREATE TABLE IF NOT EXISTS emp_users (
    user_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    organization_id UUID NOT NULL REFERENCES emp_organizations(organization_id) ON DELETE CASCADE,
    is_admin BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```
- **Purpose**: Stores user information, including admin users
- **Key Fields**:
  - `user_id`: Unique identifier for the user
  - `email`: User email
  - `name`: User name
  - `organization_id`: Reference to the organization the user belongs to
  - `is_admin`: Flag indicating if the user is an admin

#### `emp_access_controls`
```sql
CREATE TABLE IF NOT EXISTS emp_access_controls (
    access_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES emp_organizations(organization_id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(organization_id, name)
);
```
- **Purpose**: Defines access control structures for organizations
- **Key Fields**:
  - `access_id`: Unique identifier for the access control
  - `organization_id`: Reference to the organization the access control belongs to
  - `name`: Access control name
  - `description`: Access control description

### Core Tables

#### `emp_employees`
```sql
CREATE TABLE IF NOT EXISTS emp_employees (
    employee_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    organization_id UUID NOT NULL,
    access_list UUID[] NOT NULL,
    tool_access JSONB NOT NULL,
    role VARCHAR(255) NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) DEFAULT 'active'
);
```
- **Purpose**: Stores core employee information
- **Key Fields**:
  - `employee_id`: Unique identifier for the employee
  - `organization_id`: Organization the employee belongs to
  - `access_list`: Array of UUIDs representing access permissions
  - `tool_access`: JSONB array of tools the employee can access with usage instructions
  - `status`: Current employee status (active, inactive, etc.)

#### `emp_functions`
```sql
CREATE TABLE IF NOT EXISTS emp_functions (
    function_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES emp_employees(employee_id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    required_tools JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```
- **Purpose**: Defines functions that employees can perform
- **Key Fields**:
  - `function_id`: Unique identifier for the function
  - `employee_id`: Reference to the employee who can perform this function
  - `required_tools`: Tools needed to perform this function

#### `emp_sops`
```sql
CREATE TABLE IF NOT EXISTS emp_sops (
    sop_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    function_id UUID NOT NULL REFERENCES emp_functions(function_id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    tools_used JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```
- **Purpose**: Standard Operating Procedures for each function
- **Key Fields**:
  - `sop_id`: Unique identifier for the SOP
  - `function_id`: Reference to the function this SOP belongs to
  - `tools_used`: Specific tools used in this SOP with usage instructions

#### `emp_steps`
```sql
CREATE TABLE IF NOT EXISTS emp_steps (
    step_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sop_id UUID NOT NULL REFERENCES emp_sops(sop_id) ON DELETE CASCADE,
    sequence_number INTEGER NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    tools JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```
- **Purpose**: Sequential steps for each SOP
- **Key Fields**:
  - `step_id`: Unique identifier for the step
  - `sop_id`: Reference to the SOP this step belongs to
  - `sequence_number`: Order of the step within the SOP
  - `tools`: Specific tools to use during this step

### Task Logging and Metadata Tables

#### `emp_task_logs`
```sql
CREATE TABLE IF NOT EXISTS emp_task_logs (
    task_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id UUID NOT NULL REFERENCES emp_employees(employee_id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    task_name VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'in_progress',
    progress INTEGER DEFAULT 0,
    is_completed BOOLEAN DEFAULT FALSE,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```
- **Purpose**: Tracks employee tasks and progress
- **Key Fields**:
  - `task_id`: Unique identifier for the task
  - `employee_id`: Employee assigned to the task
  - `user_id`: User who created or owns the task
  - `status`: Current status of the task (in_progress, paused, etc.)
  - `progress`: Percentage completion (0-100)
  - `is_completed`: Boolean flag indicating completion

#### `emp_metadata`
```sql
CREATE TABLE IF NOT EXISTS emp_metadata (
    metadata_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID REFERENCES emp_task_logs(task_id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    context_data JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```
- **Purpose**: Stores context-specific data for tasks
- **Key Fields**:
  - `metadata_id`: Unique identifier for the metadata
  - `task_id`: Reference to the associated task
  - `user_id`: User who owns this metadata
  - `context_data`: JSONB object containing task-specific context

## Project Manager Integration Tables

#### `pm_employee_assignments`
```sql
CREATE TABLE IF NOT EXISTS pm_employee_assignments (
    assignment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES pm_projects(project_id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES emp_employees(employee_id) ON DELETE CASCADE,
    role VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```
- **Purpose**: Links employees to projects with specific roles
- **Key Fields**:
  - `assignment_id`: Unique identifier for the assignment
  - `project_id`: Project the employee is assigned to
  - `employee_id`: Employee assigned to the project
  - `role`: Role of the employee in the project

#### `pm_task_logs`
```sql
CREATE TABLE IF NOT EXISTS pm_task_logs (
    task_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    issue_id UUID NOT NULL REFERENCES pm_issues(issue_id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES emp_employees(employee_id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    task_name VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'in_progress',
    progress INTEGER DEFAULT 0,
    is_completed BOOLEAN DEFAULT FALSE,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```
- **Purpose**: Tracks employee activities on project issues
- **Key Fields**:
  - `task_id`: Unique identifier for the task
  - `issue_id`: Issue the task is related to
  - `employee_id`: Employee working on the task
  - `status`: Current status of the task

#### `pm_metadata`
```sql
CREATE TABLE IF NOT EXISTS pm_metadata (
    metadata_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID REFERENCES pm_task_logs(task_id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    context_data JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```
- **Purpose**: Stores context data for project tasks
- **Key Fields**:
  - `metadata_id`: Unique identifier for the metadata
  - `task_id`: Reference to the associated task
  - `context_data`: JSONB object containing task-specific context

## Database Functions

### Organization Management Functions

#### `emp_register_organization`
```sql
CREATE OR REPLACE FUNCTION emp_register_organization(
    p_organization_name VARCHAR(255),
    p_admin_email VARCHAR(255),
    p_admin_name VARCHAR(255)
) RETURNS UUID AS $$
```
- **Purpose**: Creates a new organization and its first admin user
- **Parameters**:
  - `p_organization_name`: Name of the organization
  - `p_admin_email`: Email of the initial admin user
  - `p_admin_name`: Name of the initial admin user
- **Returns**: The ID of the newly created organization

#### `emp_add_admin_user`
```sql
CREATE OR REPLACE FUNCTION emp_add_admin_user(
    p_organization_id UUID,
    p_email VARCHAR(255),
    p_name VARCHAR(255)
) RETURNS UUID AS $$
```
- **Purpose**: Adds an additional admin user to an existing organization
- **Parameters**:
  - `p_organization_id`: ID of the organization
  - `p_email`: Email of the new admin user
  - `p_name`: Name of the new admin user
- **Returns**: The ID of the newly created admin user

#### `emp_setup_access_controls`
```sql
CREATE OR REPLACE FUNCTION emp_setup_access_controls(
    p_organization_id UUID,
    p_access_name VARCHAR(255),
    p_description TEXT
) RETURNS UUID AS $$
```
- **Purpose**: Creates access control entries for an organization
- **Parameters**:
  - `p_organization_id`: ID of the organization
  - `p_access_name`: Name of the access control
  - `p_description`: Description of the access control
- **Returns**: The ID of the newly created access control

### Employee Management Functions

#### `emp_create_employee`
```sql
CREATE OR REPLACE FUNCTION emp_create_employee(
    p_name VARCHAR(255),
    p_organization_id UUID,
    p_access_list UUID[],
    p_tool_access JSONB,
    p_role VARCHAR(255),
    p_description TEXT DEFAULT NULL
) RETURNS UUID AS $$
```
- **Purpose**: Creates a new employee
- **Parameters**:
  - `p_name`: Employee name
  - `p_organization_id`: Organization ID
  - `p_access_list`: Array of access permissions
  - `p_tool_access`: JSONB array of tools with usage instructions
  - `p_role`: Employee role
  - `p_description`: Optional description
- **Returns**: The new employee_id

#### `emp_add_function`
```sql
CREATE OR REPLACE FUNCTION emp_add_function(
    p_employee_id UUID,
    p_name VARCHAR(255),
    p_description TEXT DEFAULT NULL,
    p_required_tools JSONB DEFAULT NULL
) RETURNS UUID AS $$
```
- **Purpose**: Adds a function to an employee
- **Parameters**:
  - `p_employee_id`: Employee ID
  - `p_name`: Function name
  - `p_description`: Optional description
  - `p_required_tools`: Tools needed for this function
- **Returns**: The new function_id

#### `emp_create_sop`
```sql
CREATE OR REPLACE FUNCTION emp_create_sop(
    p_function_id UUID,
    p_name VARCHAR(255),
    p_description TEXT DEFAULT NULL,
    p_tools_used JSONB DEFAULT NULL
) RETURNS UUID AS $$
```
- **Purpose**: Creates an SOP for a function
- **Parameters**:
  - `p_function_id`: Function ID
  - `p_name`: SOP name
  - `p_description`: Optional description
  - `p_tools_used`: Tools used in this SOP
- **Returns**: The new sop_id

#### `emp_add_step`
```sql
CREATE OR REPLACE FUNCTION emp_add_step(
    p_sop_id UUID,
    p_name VARCHAR(255),
    p_description TEXT DEFAULT NULL,
    p_tools JSONB DEFAULT NULL
) RETURNS UUID AS $$
```
- **Purpose**: Adds a step to an SOP
- **Parameters**:
  - `p_sop_id`: SOP ID
  - `p_name`: Step name
  - `p_description`: Optional description
  - `p_tools`: Tools used in this step
- **Returns**: The new step_id

### Task Logging Functions

#### `emp_create_task_log`
```sql
CREATE OR REPLACE FUNCTION emp_create_task_log(
    p_employee_id UUID,
    p_user_id UUID,
    p_task_name VARCHAR(255),
    p_description TEXT DEFAULT NULL,
    p_context_data JSONB DEFAULT '{}'::JSONB
) RETURNS UUID AS $$
```
- **Purpose**: Creates a new task log with metadata
- **Parameters**:
  - `p_employee_id`: Employee ID
  - `p_user_id`: User ID
  - `p_task_name`: Task name
  - `p_description`: Task description
  - `p_context_data`: Initial context data
- **Returns**: The new task_id

#### `emp_update_task_progress`
```sql
CREATE OR REPLACE FUNCTION emp_update_task_progress(
    p_task_id UUID,
    p_user_id UUID,
    p_status VARCHAR(50) DEFAULT NULL,
    p_progress INTEGER DEFAULT NULL,
    p_is_completed BOOLEAN DEFAULT NULL
) RETURNS BOOLEAN AS $$
```
- **Purpose**: Updates task progress
- **Parameters**:
  - `p_task_id`: Task ID
  - `p_user_id`: User ID (for access control)
  - `p_status`: New status
  - `p_progress`: New progress percentage
  - `p_is_completed`: Completion flag
- **Returns**: Success boolean

#### `emp_update_metadata`
```sql
CREATE OR REPLACE FUNCTION emp_update_metadata(
    p_task_id UUID,
    p_user_id UUID,
    p_context_data JSONB
) RETURNS BOOLEAN AS $$
```
- **Purpose**: Updates task metadata
- **Parameters**:
  - `p_task_id`: Task ID
  - `p_user_id`: User ID (for access control)
  - `p_context_data`: New context data
- **Returns**: Success boolean

### Project Integration Functions

#### `pm_assign_employee_to_project`
```sql
CREATE OR REPLACE FUNCTION pm_assign_employee_to_project(
    p_project_id UUID,
    p_employee_id UUID,
    p_role VARCHAR(255)
) RETURNS UUID AS $$
```
- **Purpose**: Assigns an employee to a project
- **Parameters**:
  - `p_project_id`: Project ID
  - `p_employee_id`: Employee ID
  - `p_role`: Role in the project
- **Returns**: The new assignment_id

#### `pm_create_task_log`
```sql
CREATE OR REPLACE FUNCTION pm_create_task_log(
    p_issue_id UUID,
    p_employee_id UUID,
    p_user_id UUID,
    p_task_name VARCHAR(255),
    p_description TEXT DEFAULT NULL,
    p_context_data JSONB DEFAULT '{}'::JSONB
) RETURNS UUID AS $$
```
- **Purpose**: Creates a task log for a project issue
- **Parameters**:
  - `p_issue_id`: Issue ID
  - `p_employee_id`: Employee ID
  - `p_user_id`: User ID
  - `p_task_name`: Task name
  - `p_description`: Task description
  - `p_context_data`: Initial context data
- **Returns**: The new task_id

## Query Examples

### Creating an Organization with Admin User

```sql
SELECT emp_register_organization(
    'Acme Corporation',
    'admin@acme.com',
    'John Doe'
);
```

### Adding an Admin User to an Organization

```sql
SELECT emp_add_admin_user(
    '123e4567-e89b-12d3-a456-426614174000',
    'jane@acme.com',
    'Jane Smith'
);
```

### Setting Up Access Controls for an Organization

```sql
SELECT emp_setup_access_controls(
    '123e4567-e89b-12d3-a456-426614174000',
    'HR_ACCESS',
    'Access to HR-related functions and data'
);
```

### Creating an Employee with Tools

```sql
SELECT emp_create_employee(
    'AI Assistant',
    '550e8400-e29b-41d4-a716-446655440000', -- organization_id
    ARRAY['550e8400-e29b-41d4-a716-446655440001'::UUID], -- access_list
    '[
        {
            "name": "code_search",
            "description": "Search for code in the codebase",
            "usage": "Use this tool to find relevant code snippets"
        },
        {
            "name": "file_editor",
            "description": "Edit files in the codebase",
            "usage": "Use this tool to modify existing files or create new ones"
        }
    ]'::JSONB, -- tool_access
    'Developer',
    'AI assistant for code development'
);
```

### Adding a Function with Required Tools

```sql
SELECT emp_add_function(
    '550e8400-e29b-41d4-a716-446655440002', -- employee_id
    'Code Review',
    'Review code for bugs and improvements',
    '[
        {
            "name": "code_search",
            "required": true
        },
        {
            "name": "static_analysis",
            "required": false
        }
    ]'::JSONB -- required_tools
);
```

### Creating a Task Log with Metadata

```sql
SELECT emp_create_task_log(
    '550e8400-e29b-41d4-a716-446655440002', -- employee_id
    '550e8400-e29b-41d4-a716-446655440003', -- user_id
    'Review Pull Request #123',
    'Comprehensive code review of PR #123',
    '{
        "pr_number": 123,
        "repository": "main-repo",
        "branch": "feature/new-api",
        "files_changed": ["api.js", "models/user.js"]
    }'::JSONB -- context_data
);
```

### Updating Task Progress

```sql
SELECT emp_update_task_progress(
    '550e8400-e29b-41d4-a716-446655440004', -- task_id
    '550e8400-e29b-41d4-a716-446655440003', -- user_id
    'in_review',
    75,
    FALSE
);
```

### Assigning an Employee to a Project

```sql
SELECT pm_assign_employee_to_project(
    '550e8400-e29b-41d4-a716-446655440005', -- project_id
    '550e8400-e29b-41d4-a716-446655440002', -- employee_id
    'Lead Developer'
);
```

### Creating a Project Task Log

```sql
SELECT pm_create_task_log(
    '550e8400-e29b-41d4-a716-446655440006', -- issue_id
    '550e8400-e29b-41d4-a716-446655440002', -- employee_id
    '550e8400-e29b-41d4-a716-446655440003', -- user_id
    'Implement API Endpoint',
    'Create new REST API endpoint for user authentication',
    '{
        "endpoint": "/api/auth",
        "method": "POST",
        "required_fields": ["username", "password"]
    }'::JSONB -- context_data
);
```

## Best Practices for LLM Interaction

### Organization Management

1. **Organization Verification**: Always verify that an organization exists before creating users, access controls, or employees for it.

   ```sql
   -- Good: Verify organization exists before creating an employee
   IF NOT EXISTS (SELECT 1 FROM emp_organizations WHERE organization_id = p_organization_id) THEN
       RAISE EXCEPTION 'Organization does not exist';
   END IF;
   ```

2. **Admin User Verification**: Verify that a user is an admin before allowing them to perform administrative actions.

   ```sql
   -- Good: Verify user is an admin
   IF NOT EXISTS (SELECT 1 FROM emp_users WHERE user_id = p_user_id AND is_admin = TRUE) THEN
       RAISE EXCEPTION 'User is not an admin';
   END IF;
   ```

3. **Access Control Validation**: Ensure that access controls belong to the correct organization.

   ```sql
   -- Good: Verify access control belongs to the organization
   IF NOT EXISTS (SELECT 1 FROM emp_access_controls 
                 WHERE access_id = ANY(p_access_list) 
                 AND organization_id = p_organization_id) THEN
       RAISE EXCEPTION 'One or more access controls do not belong to the organization';
   END IF;
   ```

### Employee Management

1. **Always check access permissions** before performing operations:

   ```sql
   SELECT emp_check_access('550e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440003');
   ```

2. **Use the full employee data function** to get complete information:

   ```sql
   SELECT * FROM emp_get_employee_full('550e8400-e29b-41d4-a716-446655440002');
   ```

3. **Update task progress incrementally** rather than jumping to completion:

   ```sql
   -- First update
   SELECT emp_update_task_progress('550e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440003', 'in_progress', 25, FALSE);
   -- Later update
   SELECT emp_update_task_progress('550e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440003', 'in_review', 75, FALSE);
   -- Final update
   SELECT emp_update_task_progress('550e8400-e29b-41d4-a716-446655440004', '550e8400-e29b-41d4-a716-446655440003', 'completed', 100, TRUE);
   ```

4. **Keep metadata context-specific** and avoid storing large amounts of unstructured data:

   ```sql
   -- Good metadata
   '{
       "key_points": ["Security issue", "Performance optimization"],
       "priority": "high",
       "estimated_time": "2 hours"
   }'::JSONB
   
   -- Bad metadata (too large and unstructured)
   '{
       "full_conversation": "very long text...",
       "entire_code_base": "..."
   }'::JSONB
   ```

5. **Verify project assignment** before creating project-related task logs:

   ```sql
   -- Check if employee is assigned to the project
   SELECT EXISTS (
       SELECT 1 FROM pm_employee_assignments 
       WHERE employee_id = '550e8400-e29b-41d4-a716-446655440002'
       AND project_id = '550e8400-e29b-41d4-a716-446655440005'
   );
   ```

6. **Use transactions** for operations that modify multiple tables:

   ```sql
   BEGIN;
   -- Create task log
   SELECT emp_create_task_log(...);
   -- Update metadata
   SELECT emp_update_metadata(...);
   COMMIT;
   ```

## Data Relationships

### Organization Management Relationships

```
emp_organizations
    ↓ 1:N
emp_users (organization_id → organization_id)
    ↓ 1:N (for admin users)
emp_employees (organization_id → organization_id)

emp_organizations
    ↓ 1:N
emp_access_controls (organization_id → organization_id)
    ↓ N:M
emp_employees (access_list → access_id[])
```

### Employee Hierarchy
```
emp_employees
    ↓
emp_functions
    ↓
emp_sops
    ↓
emp_steps
```

### Task Tracking Flow
```
emp_employees → emp_task_logs → emp_metadata
```

### Project Integration
```
pm_projects → pm_employee_assignments → emp_employees
pm_issues → pm_task_logs → pm_metadata
```

## Implementation Notes

1. All tables and functions in the Employee Creator Framework are prefixed with "emp_" to avoid naming conflicts.
2. Project Manager integration tables and functions are prefixed with "pm_" to maintain clear separation.
3. Access control is maintained through `organization_id`, `access_list`, and `user_id` fields.
4. Tool access is stored as JSONB to allow flexible definition of tools and their usage instructions.
5. Task logs and metadata provide a comprehensive system for tracking employee activities and maintaining context.
6. The integration with Project Manager allows employees to be assigned to projects and issues, with proper tracking of their contributions.

This schema documentation provides a comprehensive guide to interacting with the Employee Creator Framework database, including table structures, relationships, function usage, and best practices for LLMs.
