# Employee Onboarding Guide

This document outlines the process for onboarding within the Employee Creator Framework. The process is divided into two main parts: (1) Organization Setup and (2) Employee Creation.

## Part 1: Organization Setup

Before creating virtual employees, you must first register your organization and set up an admin user.

### 1. Organization Registration

#### Creating a New Organization
```sql
CREATE OR REPLACE FUNCTION emp_register_organization(
    p_organization_name VARCHAR(255),
    p_admin_email VARCHAR(255),
    p_admin_name VARCHAR(255)
) RETURNS UUID AS $$
DECLARE
    v_organization_id UUID;
    v_admin_user_id UUID;
BEGIN
    -- Create organization
    INSERT INTO emp_organizations (
        name,
        created_at,
        updated_at
    ) VALUES (
        p_organization_name,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    ) RETURNING organization_id INTO v_organization_id;
    
    -- Create admin user
    INSERT INTO emp_users (
        email,
        name,
        organization_id,
        is_admin,
        created_at,
        updated_at
    ) VALUES (
        p_admin_email,
        p_admin_name,
        v_organization_id,
        TRUE,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    ) RETURNING user_id INTO v_admin_user_id;
    
    RETURN v_organization_id;
END;
$$ LANGUAGE plpgsql;
```

#### Verifying Organization Exists
Before proceeding, always verify that the organization exists:

```sql
SELECT EXISTS (
    SELECT 1 FROM emp_organizations 
    WHERE organization_id = 'organization-uuid'
);
```

### 2. Admin User Setup

#### Creating Additional Admin Users
If needed, create additional admin users for the organization:

```sql
CREATE OR REPLACE FUNCTION emp_add_admin_user(
    p_organization_id UUID,
    p_email VARCHAR(255),
    p_name VARCHAR(255)
) RETURNS UUID AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Verify organization exists
    IF NOT EXISTS (SELECT 1 FROM emp_organizations WHERE organization_id = p_organization_id) THEN
        RAISE EXCEPTION 'Organization does not exist';
    END IF;
    
    -- Create admin user
    INSERT INTO emp_users (
        email,
        name,
        organization_id,
        is_admin,
        created_at,
        updated_at
    ) VALUES (
        p_email,
        p_name,
        p_organization_id,
        TRUE,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    ) RETURNING user_id INTO v_user_id;
    
    RETURN v_user_id;
END;
$$ LANGUAGE plpgsql;
```

#### Setting Up Access Controls
Define the initial access control structure for your organization:

```sql
CREATE OR REPLACE FUNCTION emp_setup_access_controls(
    p_organization_id UUID,
    p_access_name VARCHAR(255),
    p_description TEXT
) RETURNS UUID AS $$
DECLARE
    v_access_id UUID;
BEGIN
    -- Create access control
    INSERT INTO emp_access_controls (
        organization_id,
        name,
        description,
        created_at,
        updated_at
    ) VALUES (
        p_organization_id,
        p_access_name,
        p_description,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    ) RETURNING access_id INTO v_access_id;
    
    RETURN v_access_id;
END;
$$ LANGUAGE plpgsql;
```

## Part 2: Employee Creation

After setting up your organization and admin users, you can proceed with creating virtual employees.

## Onboarding Process

### 1. Initial Setup

#### Employee Creation
```sql
SELECT emp_create_employee(
    'Employee Name',                                   -- name
    'your-organization-uuid',                          -- organization_id
    ARRAY['access-uuid-1', 'access-uuid-2']::UUID[],  -- access_list
    '[
        {
            "name": "tool_name",
            "description": "Tool description",
            "usage": "How to use this tool"
        }
    ]'::JSONB,                                         -- tool_access
    'Employee Role',                                   -- role
    'Detailed description of employee purpose'         -- description
);
```

#### Access Verification
```sql
SELECT emp_check_access('employee-uuid', 'user-uuid');
```

### 2. Function Configuration

#### Adding Core Functions
For each primary function the employee will perform:

```sql
SELECT emp_add_function(
    'employee-uuid',                                  -- employee_id
    'Function Name',                                  -- name
    'Detailed description of what this function does', -- description
    '[
        {
            "name": "required_tool",
            "required": true
        }
    ]'::JSONB                                         -- required_tools
);
```

### 3. SOP Development

#### Creating Standard Operating Procedures
For each function, create at least one SOP:

```sql
SELECT emp_create_sop(
    'function-uuid',                                  -- function_id
    'SOP Name',                                       -- name
    'Detailed description of this procedure',         -- description
    '[
        {
            "name": "tool_name",
            "usage": "Specific usage in this SOP"
        }
    ]'::JSONB                                         -- tools_used
);
```

#### Adding Sequential Steps
Break down each SOP into clear, sequential steps:

```sql
SELECT emp_add_step(
    'sop-uuid',                                       -- sop_id
    'Step Name',                                      -- name
    'Detailed instructions for this step',            -- description
    '[
        {
            "name": "tool_name",
            "usage": "How to use the tool in this step"
        }
    ]'::JSONB                                         -- tools
);
```

### 4. Initial Task Setup

#### Creating First Task Log
Set up an initial task to test the employee's functionality:

```sql
SELECT emp_create_task_log(
    'employee-uuid',                                  -- employee_id
    'user-uuid',                                      -- user_id
    'Initial Test Task',                              -- task_name
    'Testing basic functionality of the employee',    -- description
    '{
        "test_parameters": {
            "complexity": "simple",
            "expected_outcome": "confirmation of functionality"
        }
    }'::JSONB                                         -- context_data
);
```

### 5. Project Integration (if applicable)

#### Assigning to Project
If the employee will work on specific projects:

```sql
SELECT pm_assign_employee_to_project(
    'project-uuid',                                   -- project_id
    'employee-uuid',                                  -- employee_id
    'Project Role'                                    -- role
);
```

#### Setting Up Project Task
Create an initial project-related task:

```sql
SELECT pm_create_task_log(
    'issue-uuid',                                     -- issue_id
    'employee-uuid',                                  -- employee_id
    'user-uuid',                                      -- user_id
    'Initial Project Task',                           -- task_name
    'First task related to the project',              -- description
    '{
        "project_context": {
            "priority": "medium",
            "deadline": "2025-04-01"
        }
    }'::JSONB                                         -- context_data
);
```

## Complete Onboarding Checklist

### Organization Setup
- [ ] Organization registered with unique organization_id
- [ ] Admin user created and linked to organization
- [ ] Additional admin users added (if needed)
- [ ] Access control structure defined
- [ ] Organization verified before proceeding with employee creation

### Employee Setup
- [ ] Employee created with proper organization_id and access_list
- [ ] Tool access configured with clear usage instructions
- [ ] At least one function added with required tools
- [ ] At least one SOP created for each function
- [ ] Sequential steps added to each SOP
- [ ] Initial task created to test functionality
- [ ] Metadata structure established for context continuity
- [ ] Project assignment completed (if applicable)
- [ ] Initial project task created (if applicable)
- [ ] Access permissions verified

## Best Practices for New Employees

1. **Start Simple**: Begin with well-defined, narrow functions before expanding capabilities
2. **Document Thoroughly**: Ensure all SOPs and steps have clear, detailed descriptions
3. **Test Incrementally**: Verify each function works before adding new ones
4. **Monitor Early Tasks**: Closely track the first few tasks to ensure proper functioning
5. **Update Regularly**: Refine functions and SOPs based on performance feedback
6. **Maintain Context**: Use metadata effectively to ensure task continuity
7. **Follow Access Controls**: Ensure proper organization_id and access_list settings
8. **Define Tool Usage**: Provide clear instructions for each tool the employee can access
9. **Structure Hierarchically**: Maintain the employee → function → SOP → step hierarchy
10. **Integrate Gradually**: Start with standalone tasks before integrating with projects

## Troubleshooting Common Issues

### Access Problems
If the employee cannot access resources:
```sql
-- Update access list
UPDATE emp_employees 
SET access_list = access_list || ARRAY['new-access-uuid']::UUID[]
WHERE employee_id = 'employee-uuid';
```

### Missing Tools
If the employee needs additional tools:
```sql
-- Update tool access
UPDATE emp_employees
SET tool_access = tool_access || '[{"name": "new_tool", "description": "New tool description", "usage": "How to use"}]'::JSONB
WHERE employee_id = 'employee-uuid';
```

### Task Progress Issues
If tasks are not updating correctly:
```sql
-- Reset task progress
SELECT emp_update_task_progress(
    'task-uuid',
    'user-uuid',
    'in_progress',
    0,
    FALSE
);
```

### Metadata Corruption
If metadata becomes inconsistent:
```sql
-- Reset metadata to clean state
SELECT emp_update_metadata(
    'task-uuid',
    'user-uuid',
    '{}'::JSONB
);
```

By following this onboarding guide, you'll ensure that your new virtual employee is properly configured, tested, and ready to perform their designated functions within your organization.
