---
name: todo
description: View, add, update, or delete project to-do items
argument-hint: "[task description]"
---

# Todo

## Trigger

User says "/todo", "/todo <task description>", "add todo", "show todos", etc.

## Rules

**CRITICAL: Never update, delete, complete, or modify any to-do item unless the user explicitly asks you to.** Only the user can change the status of, edit, or remove a to-do. You may only add new items when the user asks.

## Steps

### No argument — list todos

1. Read vault path from `.the-agency-config`
2. Resolve the linked project (or ask which project)
3. Read `wiki/todo.md`
4. Display the to-do list to the user
5. Ask: "Want to update or remove any items?"
6. **Wait for the user to tell you** which items to change — do not suggest changes

### With argument — add a todo

1. Read vault path from `.the-agency-config`
2. Resolve the linked project (or ask which project)
3. Read `wiki/todo.md`
4. Add a new row to the table:
   - `#` — next sequential number
   - `Task` — the argument passed by the user
   - `Priority` — ask the user, or leave empty
   - `Plan` — empty (user can link a plan later)
   - `Added` — today's date (YYYY-MM-DD)
   - `Status` — `open`
5. Write the updated file
6. Confirm: "Added to <project> todos: <task>"

### User asks to update or delete

When the user explicitly asks to change a to-do:

- **Complete**: change status to `done`
- **Delete**: remove the row entirely
- **Edit**: update the task description
- **Reopen**: change status back to `open`
- **Link plan**: add a wikilink to a plan in the Plan column (e.g., `[[plans/2026-04-13-auth-refactor]]`)

Always confirm the change before writing.
