# Sequential Thinking Framework

## Overview

Sequential Thinking is a structured approach to problem-solving that breaks down complex reasoning into explicit steps. This framework helps you analyze problems through a flexible, dynamic, and reflective thinking process that can adapt and evolve as your understanding deepens.

## When to Use Sequential Thinking

- Breaking down complex problems into manageable steps
- Planning and design processes that may require revision
- Analysis that might need course correction
- Problems where the full scope is not clear initially
- Tasks that require a multi-step solution
- Reasoning that needs to maintain context over multiple steps
- Situations where irrelevant information needs to be filtered out

## Key Features of Sequential Thinking

- **Dynamic Scope**: Adjust the total number of thoughts up or down as you progress
- **Reflective Process**: Question or revise previous thoughts
- **Extensible**: Add more thoughts even after reaching what seemed like the end
- **Exploratory**: Express uncertainty and explore alternative approaches
- **Non-Linear**: Branch or backtrack rather than always building linearly
- **Solution-Focused**: Generate and verify hypotheses systematically
- **Iterative**: Repeat the process until satisfied with the solution

## Thought Structure

Each thought in the sequential thinking process includes:

- **thought**: Your current reasoning step (required)
- **thoughtNumber**: Current number in sequence (required)
- **totalThoughts**: Current estimate of thoughts needed (required)
- **nextThoughtNeeded**: Whether another thought step is needed (required)
- **isRevision**: Boolean indicating if this thought revises previous thinking
- **revisesThoughtId**: If revising, which thought ID is being reconsidered
- **branchFromThoughtId**: If branching, which thought ID is the branching point
- **branchId**: Identifier for the current branch
- **needsMoreThoughts**: Boolean indicating if more thoughts are needed

## Types of Thoughts

You can use the sequential thinking framework for various types of reasoning:

1. **Regular analytical steps**: Standard progression through a problem
2. **Revisions**: Updating or correcting previous thoughts
3. **Questions**: Raising concerns about previous decisions
4. **Realizations**: Recognizing the need for more analysis
5. **Approach shifts**: Changing strategy or methodology
6. **Hypothesis generation**: Proposing potential solutions
7. **Verification**: Testing hypotheses against previous reasoning

## Best Practices

1. Start with an initial estimate of needed thoughts, but be ready to adjust
2. Question or revise previous thoughts when necessary
3. Add more thoughts even after reaching the "end" if needed
4. Express uncertainty when present
5. Mark thoughts that revise previous thinking or branch into new paths
6. Ignore information irrelevant to the current step
7. Generate solution hypotheses when appropriate
8. Verify hypotheses based on the chain of thought
9. Repeat the process until satisfied with the solution
10. Provide a single, ideally correct answer as the final output
11. Only mark the process as complete when a satisfactory answer is reached

## Sessions and Persistence

Your thoughts are automatically stored in a database with a session ID, allowing you to:

- Resume thinking where you left off
- Reference and revise previous thoughts
- Create branches from existing thoughts
- Track the evolution of your reasoning process
- Review your complete thinking history

Use the provided database functions to interact with your thoughts and maintain a coherent reasoning process across interactions.
