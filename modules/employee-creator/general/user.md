# User Instructions for Employee Creator Framework

Welcome to the Employee Creator Framework! This system allows you to create and manage virtual employees that can perform specific functions within your organization. This guide will help you understand how to interact with the system effectively.

## Getting Started

### Creating a Virtual Employee

To create a new virtual employee, you'll need to provide:

1. **Name**: A descriptive name for the employee
2. **Organization ID**: Your organization's unique identifier
3. **Access List**: Permissions the employee should have
4. **Tool Access**: Tools the employee can use with usage instructions
5. **Role**: The employee's role in your organization
6. **Description**: (Optional) A detailed description of the employee

Example:
```
I'd like to create a new virtual employee named "Code Reviewer" with access to code analysis tools.
```

### Adding Functions to an Employee

After creating an employee, you can add functions they can perform:

1. **Function Name**: What the function does
2. **Description**: Details about the function
3. **Required Tools**: Tools needed to perform this function

Example:
```
Please add a "Pull Request Review" function to my Code Reviewer employee that requires code_search and static_analysis tools.
```

### Creating SOPs for Functions

Standard Operating Procedures (SOPs) define how functions are performed:

1. **SOP Name**: Name of the procedure
2. **Description**: What the procedure accomplishes
3. **Tools Used**: Specific tools used in this SOP

Example:
```
I need an SOP for the Pull Request Review function that outlines the code review process.
```

### Adding Steps to SOPs

Break down SOPs into sequential steps:

1. **Step Name**: Name of the step
2. **Description**: What happens in this step
3. **Tools**: Tools used in this specific step

Example:
```
Add a step to the Pull Request Review SOP called "Security Check" that uses the security_scanner tool.
```

## Task Management

### Creating Task Logs

Track employee activities with task logs:

1. **Task Name**: What the task is
2. **Description**: Details about the task
3. **Context Data**: Specific information needed for the task

Example:
```
Create a task for my Code Reviewer to review PR #123 with context data about the repository and branch.
```

### Updating Task Progress

Monitor and update task progress:

1. **Status**: Current state of the task
2. **Progress**: Percentage completion (0-100%)
3. **Completion**: Whether the task is complete

Example:
```
Update the PR #123 review task to 75% progress with status "in_review".
```

### Managing Metadata

Store and retrieve context-specific data:

1. **Context Data**: Information needed for task continuity

Example:
```
Update the metadata for PR #123 review to include findings about security issues.
```

## Project Integration

### Assigning Employees to Projects

Link employees to specific projects:

1. **Project ID**: The project to assign to
2. **Employee ID**: The employee to assign
3. **Role**: The employee's role in the project

Example:
```
Assign my Code Reviewer employee to the Mobile App project as a Quality Assurance Specialist.
```

### Creating Project Task Logs

Track employee activities on project issues:

1. **Issue ID**: The issue to work on
2. **Task Name**: What the task is
3. **Context Data**: Specific information for the task

Example:
```
Create a task log for issue #45 in the Mobile App project for my Code Reviewer to analyze performance issues.
```

## Best Practices

1. **Be Specific**: Provide clear details when creating employees, functions, and tasks.

2. **Update Progress Regularly**: Keep task progress updated to track completion accurately.

3. **Use Meaningful Metadata**: Store relevant context data that helps with task continuity.

4. **Follow Proper Structure**: Maintain the hierarchy of employees → functions → SOPs → steps.

5. **Verify Project Assignment**: Ensure employees are assigned to projects before creating project-specific tasks.

6. **Use Descriptive Names**: Choose clear names for employees, functions, SOPs, and tasks.

By following these guidelines, you'll be able to effectively utilize the Employee Creator Framework to manage virtual employees and their activities within your organization.
