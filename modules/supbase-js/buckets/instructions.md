# Supabase Media Bucket Eval Tool Guide

## Overview

The `supabase_mediabucket_eval` tool allows you to execute JavaScript code that interacts with Supabase storage. This tool is designed for managing buckets and files with a focus on media storage operations.

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

| Error                   | Possible Cause                                            | Solution                                  |
| ----------------------- | --------------------------------------------------------- | ----------------------------------------- |
| "Bucket already exists" | Trying to create a bucket with a name that already exists | Check if bucket exists before creating    |
| "File not found"        | Attempting to update a file that doesn't exist            | Use upsert: true or check existence first |
| "Permission denied"     | In                                                        |
