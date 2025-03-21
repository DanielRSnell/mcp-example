# Sequential Thinking Framework

## Overview

Sequential Thinking is a structured approach to problem-solving that breaks down complex reasoning into explicit steps. This framework helps you analyze problems through a flexible, dynamic, and reflective thinking process that can adapt and evolve as your understanding deepens. The system bridges the gap between ideation and implementation by supporting both the thinking process and its translation into executable action plans.

## When to Use Sequential Thinking

- Breaking down complex problems into manageable steps
- Planning and design processes that may require revision
- Analysis that might need course correction
- Problems where the full scope is not clear initially
- Tasks that require a multi-step solution
- Reasoning that needs to maintain context over multiple sessions
- Situations where irrelevant information needs to be filtered out
- Projects that need structured execution plans after the thinking phase

## Key Features of Sequential Thinking

- **Dynamic Scope**: Adjust the total number of thoughts up or down as you progress
- **Reflective Process**: Question or revise previous thoughts
- **Extensible**: Add more thoughts even after reaching what seemed like the end
- **Exploratory**: Express uncertainty and explore alternative approaches
- **Non-Linear**: Branch or backtrack rather than always building linearly
- **Solution-Focused**: Generate and verify hypotheses systematically
- **Iterative**: Repeat the process until satisfied with the solution
- **Action-Oriented**: Convert completed thought sequences into actionable execution plans
- **Persistent**: Store and resume complex reasoning across multiple sessions

## Thought Structure

Each thought in the sequential thinking process includes:

- **thought**: Your current reasoning step (required)
- **thoughtNumber**: Current number in sequence (required)
- **totalThoughts**: Current estimate of thoughts needed (required)
- **nextThoughtNeeded**: Whether another thought step is needed (required)
- **isRevision**: Boolean indicating if this thought revises previous thinking
- **revisesThoughtId**: If revising, which thought ID is being reconsidered
- **branchFromThoughtId**: If branching, which thought ID is the branching point
- **branchId**: Identifier for the current branch (up to 100 characters)
- **needsMoreThoughts**: Boolean indicating if more thoughts are needed
- **status**: Current state of the thought (active, completed, paused, abandoned)
- **userPaused**: Boolean indicating if the user requested a pause
- **executionState**: JSON data storing progress within a thought for resumption
- **chatId**: Identifier for the session this thought belongs to

## Types of Thoughts

You can use the sequential thinking framework for various types of reasoning:

1. **Regular analytical steps**: Standard progression through a problem
2. **Revisions**: Updating or correcting previous thoughts
3. **Questions**: Raising concerns about previous decisions
4. **Realizations**: Recognizing the need for more analysis
5. **Approach shifts**: Changing strategy or methodology
6. **Hypothesis generation**: Proposing potential solutions
7. **Verification**: Testing hypotheses against previous reasoning
8. **Conclusion**: Summarizing the analysis and preparing for execution

## Thought Limits and User Interaction

The sequential thinking process is designed to be interactive with appropriate pauses for user feedback:

- **Thought Limits**: There may be a limit to the number of consecutive thoughts before requiring user input (typically 5-10 thoughts)
- **User Checkpoints**: After reaching the thought limit, the system will pause and wait for user confirmation before continuing
- **Break Clauses**: Users can interrupt the thinking process at any point to provide additional input or redirect the analysis
- **State Preservation**: When paused, the current execution state is saved so thinking can resume exactly where it left off
- **User Overrides**: Users can manually override thought direction, branch into new paths, or adjust the total thoughts needed
- **Continuation Requests**: The system can explicitly ask if more thinking is needed when nearing completion

These interaction points help maintain user control over the thinking process while ensuring the reasoning remains on track with the user's goals.

## Execution Plans

Once the thinking process is complete, you can create detailed execution plans with:

- **Steps**: Ordered tasks derived from your sequential thoughts
- **Dependencies**: Relationships between steps (which must be completed first)
- **Assignments**: Who is responsible for each step
- **Timeframes**: Estimated duration for each step
- **Priorities**: Importance levels for each step
- **Status Tracking**: Monitor progress as steps are completed

## Best Practices

1. Start with an initial estimate of needed thoughts, but be ready to adjust
2. Question or revise previous thoughts when necessary
3. Add more thoughts even after reaching the "end" if needed
4. Express uncertainty when present
5. Mark thoughts that revise previous thinking or branch into new paths
6. Ignore information irrelevant to the current step
7. Generate solution hypotheses when appropriate
8. Verify hypotheses based on the chain of thought
9. Repeat the thinking process until satisfied with the solution
10. Create an execution plan once the thinking process is complete
11. Break down the execution plan into specific, actionable steps
12. Track progress through the execution phase
13. Only mark a session as complete when both thinking and execution are finished

## Persistence and Continuity

Your thoughts and execution plans are stored in a database with chat IDs (up to 100 characters), allowing you to:

- Resume thinking where you left off
- Reference and revise previous thoughts
- Create branches from existing thoughts
- Track the evolution of your reasoning process
- Review your complete thinking history
- Save your state mid-thought and resume later
- Convert completed thought sequences into execution plans
- Track progress through execution of the plan
- Maintain context across multiple user sessions

## Implementation Note

In the database, all tables and functions are prefixed with "sqt\_" (Sequential Quantum Thinking) to avoid naming conflicts. For example, thoughts are stored in the `sqt_thoughts` table and sessions in the `sqt_sessions` table. The database uses `chat_id` as the primary identifier for sessions (rather than `session_id`) to prevent column name ambiguity with function parameters.

When using the database functions, remember to include the "sqt\_" prefix (e.g., `sqt_add_thought()`, `sqt_get_active_thought()`) and use `chat_id` to identify sessions.

The database schema uses snake_case for field names (e.g., `thought_number`, `next_thought_needed`), while this document uses camelCase (e.g., `thoughtNumber`, `nextThoughtNeeded`) for conceptual clarity.
