# Supabase Media Bucket Eval Tool Guide

## Overview

The `supabase_mediabucket_eval` tool allows you to execute JavaScript code that interacts with Supabase storage. This tool is designed for managing buckets and files with a focus on media storage operations.

## ⚠️ MANDATORY RULE: QUERY Parameter Required ⚠️

**THE QUERY PARAMETER IS STRICTLY REQUIRED WHEN USING THIS TOOL.**

- You MUST pass a valid JavaScript code string as the QUERY parameter
- The tool will FAIL if the QUERY parameter is missing or empty
- The QUERY parameter contains the actual JavaScript code to be executed
- No default code will be executed if QUERY is omitted

Example of correct usage:
```
supabase_mediabucket_eval(QUERY: "return await supabase.storage.listBuckets();")
```

Failure to include the QUERY parameter will result in execution errors and no operations will be performed.

## ⚠️ MANDATORY RULE: Return URL to Bucket Items ⚠️

**YOUR RESPONSE MUST INCLUDE A PUBLIC URL TO ANY CREATED OR MODIFIED BUCKET ITEM.**

- When uploading or modifying files, you MUST return a public URL to access the item
- The response object MUST include a `publicURL` property with the complete URL
- For operations that create multiple items, include URLs for ALL created items
- No operation is considered complete without returning the appropriate URL(s)

Example of correct return format:
```javascript
return {
  success: true,
  message: "File uploaded successfully",
  data: {
    path: "folder/file.ext",
    bucket: "media",
    publicURL: "https://wpefpfebiyopiagmwrgm.supabase.co/storage/v1/object/public/media/folder/file.ext"
  }
};
```

The URL format should be:
`https://[PROJECT_ID].supabase.co/storage/v1/object/public/[BUCKET_NAME]/[FILE_PATH]`

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

## Examples of Common Operations

### 1. Creating a Bucket

```javascript
return (async () => {
  try {
    const bucketName = "media";
    const { data, error } = await supabase.storage.createBucket(bucketName, {
      public: true,
      fileSizeLimit: 1024 * 1024 * 10, // 10MB
    });

    if (error) throw error;

    return {
      success: true,
      message: `Bucket '${bucketName}' created successfully`,
      data: {
        bucket: bucketName,
        publicURL: `https://wpefpfebiyopiagmwrgm.supabase.co/storage/v1/object/public/${bucketName}`
      }
    };
  } catch (err) {
    return {
      success: false,
      message: "Error creating bucket",
      error: err.message || String(err),
    };
  }
})();
```

### 2. Uploading a File

```javascript
return (async () => {
  try {
    const bucketName = "media";
    const filePath = "docs/example.md";
    const fileContent = "# Example Document\n\nThis is an example markdown file.";

    const { data, error: uploadError } = await supabase.storage
      .from(bucketName)
      .upload(filePath, fileContent, {
        contentType: "text/markdown",
        upsert: false,
      });

    if (uploadError) throw uploadError;

    // REQUIRED: Generate and return the public URL
    const publicURL = `https://wpefpfebiyopiagmwrgm.supabase.co/storage/v1/object/public/${bucketName}/${filePath}`;
    
    return {
      success: true,
      message: "File uploaded successfully",
      data: {
        path: filePath,
        bucket: bucketName,
        publicURL: publicURL
      }
    };
  } catch (err) {
    return {
      success: false,
      message: "Error uploading file",
      error: err.message || String(err),
    };
  }
})();
```

### 3. Listing Files in a Bucket

```javascript
return (async () => {
  try {
    const bucketName = "media";
    const { data, error } = await supabase.storage.from(bucketName).list();

    if (error) throw error;

    // REQUIRED: Generate public URLs for all files
    const filesWithURLs = data.map(file => ({
      ...file,
      publicURL: `https://wpefpfebiyopiagmwrgm.supabase.co/storage/v1/object/public/${bucketName}/${file.name}`
    }));

    return {
      success: true,
      message: `Successfully listed files in '${bucketName}' bucket`,
      data: {
        bucket: bucketName,
        files: filesWithURLs,
        bucketURL: `https://wpefpfebiyopiagmwrgm.supabase.co/storage/v1/object/public/${bucketName}`
      }
    };
  } catch (err) {
    return {
      success: false,
      message: "Error listing files",
      error: err.message || String(err),
    };
  }
})();
```

### 4. Moving/Renaming a File

```javascript
return (async () => {
  try {
    const bucketName = "media";
    const originalPath = "docs/old-name.md";
    const newPath = "docs/new-name.md";

    const { data, error } = await supabase.storage
      .from(bucketName)
      .move(originalPath, newPath);

    if (error) throw error;

    // REQUIRED: Generate and return the new public URL
    const publicURL = `https://wpefpfebiyopiagmwrgm.supabase.co/storage/v1/object/public/${bucketName}/${newPath}`;
    
    return {
      success: true,
      message: "File moved/renamed successfully",
      data: {
        originalPath: originalPath,
        newPath: newPath,
        bucket: bucketName,
        publicURL: publicURL
      }
    };
  } catch (err) {
    return {
      success: false,
      message: "Error moving/renaming file",
      error: err.message || String(err),
    };
  }
})();
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

    const { data, error: uploadError } = await supabase.storage
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

    // Return the public URL to the uploaded file
    const publicURL = `https://wpefpfebiyopiagmwrgm.supabase.co/storage/v1/object/public/${bucketName}/${filePath}`;
    return {
      success: true,
      message: "File uploaded successfully",
      data: {
        path: filePath,
        bucket: bucketName,
        publicURL,
      },
    };
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
