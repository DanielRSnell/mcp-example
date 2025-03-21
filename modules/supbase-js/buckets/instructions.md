# Supabase Media Bucket Eval Tool Guide

## Overview

The `supabase_mediabucket_eval` tool allows you to execute JavaScript code that interacts with Supabase storage. This tool is designed for managing buckets and files with a focus on media storage operations.

## How the Tool Works Internally

The tool uses the following code to execute your JavaScript via a Function constructor:

```javascript
// Import the required modules
const { createClient } = require("@supabase/supabase-js");
// Create a Supabase client with your URL and SERVICE ROLE key
const supabase = createClient(
  "https://wpefpfebiyopiagmwrgm.supabase.co",
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndwZWZwZmViaXlvcGlhZ213cmdtIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0MjQyMjQ4OSwiZXhwIjoyMDU3OTk4NDg5fQ.f7SPDEHTgHrLaCFPvUqM93UUcLVyaw0q8BjBVyTFtIU"
);
const input = query; // Your code goes here as a string
// This function creates a bucket and returns the result
async function executeSupabaseEval() {
  // Create a new function with the supabase variable explicitly passed as an argument
  const supabaseFunctions = new Function("supabase", input);
  // Execute the function with the supabase client as an argument and await the result
  try {
    const result = await supabaseFunctions(supabase);
    console.log("Bucket creation result:", result);
    return result;
  } catch (err) {
    console.error("Error creating bucket:", err);
    return {
      success: false,
      message: "Error creating bucket",
      error: err.message || String(err),
    };
  }
}
// Execute and immediately return the result
return executeSupabaseEval();
```

**Understanding this execution context is important:**

- Your code is executed as a string via the `Function` constructor
- The `supabase` client is passed as an argument to your function
- Your function must return a value that the tool can process
- Your code should be crafted specifically for this execution environment

## Important: Execution Context

**Your code will be executed within an `eval()` statement in Node.js**. This means:

- You must structure your code to be evaluated safely
- Your code must be completely self-contained
- All operations must be within an async immediately-invoked function expression (IIFE)
- You must return a string value as the final result ("completed", "failed", etc.)

## Usage Requirements

When using this tool, you must structure your code according to the following pattern:

```javascript
return (async () => {
  try {
    // Your Supabase storage operations go here

    // You must return a STRING at the end
    return "completed"; // or "failed", "partial", etc.
  } catch (err) {
    // Return a string for errors as well
    return "failed: " + (err.message || String(err));
  }
})();
```

This pattern works because:

1. The tool passes your code to a Function constructor
2. It injects the supabase client as an argument
3. The async IIFE allows for awaiting Supabase operations
4. The string return value is passed back through the Function execution

**Important:** Do not try to initialize a new Supabase client or export modules. The environment is already set up, and your code should focus solely on the operations you want to perform.

## Key Features

- ✅ Create and manage storage buckets
- ✅ Upload and update markdown files
- ✅ Check if buckets and files exist
- ✅ Manage file permissions and metadata

## Important Notes

- The Supabase client is **already initialized** as `supabase` - do not attempt to create or initialize it
- Your code will be executed within an **eval statement**
- All Supabase operations must use **async/await** pattern
- Always handle errors explicitly with try/catch
- Return values must be simple strings, not objects

## Common Operations Examples

### 1. Check if a Bucket Exists

```javascript
// List all buckets
const { data: buckets, error: listError } =
  await supabase.storage.listBuckets();

if (listError) {
  throw new Error(`Failed to list buckets: ${listError.message}`);
}

// Check if our target bucket exists
const bucketExists = buckets.some((bucket) => bucket.name === "media");
console.log(`Media bucket exists: ${bucketExists}`);
```

### 2. Create a New Bucket

```javascript
// Only create if it doesn't exist
if (!bucketExists) {
  const { data, error: createError } = await supabase.storage.createBucket(
    "media",
    {
      public: true, // Make files publicly accessible
      fileSizeLimit: 1024 * 1024 * 50, // 50MB file size limit
    }
  );

  if (createError) {
    throw new Error(`Failed to create bucket: ${createError.message}`);
  }

  console.log("Media bucket created successfully");
}
```

### 3. Upload a New Markdown File

```javascript
const filePath = "blog/welcome.md";
const fileContent = `# Welcome\n\nThis is a sample markdown file created on ${new Date().toISOString()}`;

const { data, error: uploadError } = await supabase.storage
  .from("media")
  .upload(filePath, fileContent, {
    contentType: "text/markdown",
    upsert: false, // Set to false to prevent overwriting existing files
  });

if (uploadError) {
  throw new Error(`Failed to upload file: ${uploadError.message}`);
}

console.log(`File uploaded successfully to ${filePath}`);
```

### 4. Update an Existing File

```javascript
// Update existing file or create if it doesn't exist
const { data, error: updateError } = await supabase.storage
  .from("media")
  .upload(filePath, updatedContent, {
    contentType: "text/markdown",
    upsert: true, // Set to true to overwrite if the file exists
  });

if (updateError) {
  throw new Error(`Failed to update file: ${updateError.message}`);
}

console.log(`File updated successfully at ${filePath}`);
```

### 5. Check if a File Exists

```javascript
const { data, error: listError } = await supabase.storage
  .from("media")
  .list("blog"); // List files in the 'blog' folder

if (listError) {
  throw new Error(`Failed to list files: ${listError.message}`);
}

const fileExists = data.some((file) => file.name === "welcome.md");
console.log(`File exists: ${fileExists}`);
```

## Complete Example

Here's the example code you provided, modified to return a string result:

```javascript
return (async () => {
  try {
    // Define bucket name
    const bucketName = "test-bucket-" + Date.now();

    console.log(`Attempting to create bucket: ${bucketName}`);

    // Create the bucket
    const { data, error } = await supabase.storage.createBucket(bucketName, {
      public: true, // Makes the bucket public
      fileSizeLimit: 1024 * 1024 * 10, // 10MB file size limit
    });

    if (error) {
      console.error("Failed to create bucket:", error.message);
      return "failed";
    }

    console.log(`Successfully created bucket: ${bucketName}`);
    return "completed";
  } catch (err) {
    console.error("Error creating bucket:", err.message || String(err));
    return "failed";
  }
})();
```

## Another Example: Creating a Media Bucket with Markdown File

Here's a more comprehensive example that follows the same pattern:

```javascript
return (async () => {
  try {
    // Step 1: Check if media bucket exists
    const { data: buckets, error: listError } =
      await supabase.storage.listBuckets();

    if (listError) {
      console.error("Failed to list buckets:", listError.message);
      return "failed";
    }

    const bucketName = "media";
    const bucketExists = buckets.some((bucket) => bucket.name === bucketName);

    // Step 2: Create bucket if it doesn't exist
    if (!bucketExists) {
      console.log(`Bucket '${bucketName}' does not exist. Creating it...`);

      const { error: createError } = await supabase.storage.createBucket(
        bucketName,
        {
          public: true,
          fileSizeLimit: 1024 * 1024 * 50, // 50MB file size limit
        }
      );

      if (createError) {
        console.error("Failed to create media bucket:", createError.message);
        return "failed";
      }

      console.log(`Successfully created bucket '${bucketName}'`);
    } else {
      console.log(`Bucket '${bucketName}' already exists`);
    }

    // Step 3: Create a markdown file
    const filePath = "docs/readme.md";
    const content = `# Media Repository\n\nThis repository contains media files.\n\nLast updated: ${new Date().toISOString()}`;

    const { error: uploadError } = await supabase.storage
      .from(bucketName)
      .upload(filePath, content, {
        contentType: "text/markdown",
        upsert: true,
      });

    if (uploadError) {
      console.error(`Failed to upload markdown file:`, uploadError.message);
      return "failed";
    }

    console.log(
      `Successfully ${
        bucketExists ? "updated" : "created"
      } markdown file at ${filePath}`
    );

    // All operations completed successfully
    return "completed";
  } catch (err) {
    console.error("Unexpected error:", err.message || String(err));
    return "failed";
  }
})();
```

## Troubleshooting

Common errors you might encounter:

| Error                      | Possible Cause                                            | Solution                                                |
| -------------------------- | --------------------------------------------------------- | ------------------------------------------------------- |
| "Bucket already exists"    | Trying to create a bucket with a name that already exists | Check if bucket exists before creating                  |
| "File not found"           | Attempting to update a file that doesn't exist            | Use upsert: true or check existence first               |
| "Permission denied"        | Insufficient permissions for the operation                | Check your Supabase service role permissions            |
| "Invalid content type"     | Incorrect file type specification                         | Ensure content type matches file (e.g., text/markdown)  |
| "Illegal return statement" | Using return at the top level of your code                | Make sure return is inside the async IIFE               |
| "... is not defined"       | Referencing variables not in scope                        | Remember only `supabase` is injected into your function |

## Best Practices

- ✅ Always check if resources exist before creating them
- ✅ Use console.log for debugging (these will be visible in the execution logs)
- ✅ Properly structure directories for better organization
- ✅ Use upsert carefully based on your use case
- ✅ Return simple string values: "completed", "failed", "partial", etc.
- ✅ Follow the async/await pattern for all operations
- ✅ Keep all code inside the async IIFE function
- ✅ Don't import modules or create new Supabase clients inside your function
