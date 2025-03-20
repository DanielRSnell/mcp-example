-- Query to retrieve all instructions from the database
-- This file provides a simple way to view all available database operations
-- and their corresponding SQL examples

-- Basic query to get all instructions
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

-- Alternative query with formatted output for better readability
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

-- Query to find instructions by keyword
-- Usage: Replace 'issue' with your search term
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

-- Query to get instructions for a specific operation type
-- Common categories: CREATE_, GET_, UPDATE_, DELETE_
SELECT 
    operation,
    description
FROM 
    instructions
WHERE 
    operation LIKE 'GET_%'
ORDER BY 
    operation;
