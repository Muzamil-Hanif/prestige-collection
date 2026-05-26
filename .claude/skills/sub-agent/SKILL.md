# Sub-Agent Creator Skill

Create and delegate tasks to specialized sub-agents using the Agent framework.

## Quick Usage

### Syntax
```
/sub-agent <agent-type> <task-description>
```

### Supported Agent Types
- `general` — General-purpose agent for any task
- `explorer` — Fast read-only search and code exploration
- `planner` — Software architect for implementation planning
- `reviewer` — Code review agent
- `builder` — Build and compilation tasks

## Examples

### Example 1: General Task Agent
```
/sub-agent general "Preview this HTML in browser: <html><body><h1>Test</h1></body></html>"
```

### Example 2: Code Explorer
```
/sub-agent explorer "Find all API endpoints in lib/services/"
```

### Example 3: Planning Agent
```
/sub-agent planner "Design the checkout flow for the Flutter app"
```

### Example 4: Code Review
```
/sub-agent reviewer "Review the changes on this branch for security issues"
```

### Example 5: Builder Agent
```
/sub-agent builder "Build the Flutter app for iOS and check for errors"
```

## Agent Types Explained

| Type | Best For | Capabilities |
|------|----------|--------------|
| `general` | Flexible tasks, scripting, API work | All tools (Bash, Read, Edit, Web) |
| `explorer` | Finding code, searching patterns | Fast grep, file search (read-only) |
| `planner` | Architecture, design decisions | Planning, no code execution |
| `reviewer` | Code quality, security review | Code review specialized tools |
| `builder` | Build, test, compilation | Build/test focused tools |

## Advanced: Continuing Conversations

After spawning an agent, you can continue asking it questions:

```
Use SendMessage with to: '<agent-id>' to ask follow-up questions
```

## Pro Tips

1. **Be specific**: The more detail you provide, the better the agent performs
2. **Task breakdown**: Complex tasks work better when split into smaller sub-tasks
3. **Context**: Reference files and functions by path for clarity
4. **Monitoring**: Check agent output and guide if needed

## Examples of Great Tasks

✅ "Open test-example.html in browser using html-preview skill"
✅ "Find all TODO comments in lib/pages/"
✅ "Design state management for the cart feature"
✅ "Review security of the auth flow"
✅ "Build the app and fix any compilation errors"

## Examples of Vague Tasks

❌ "Do something with the code"
❌ "Fix the app"
❌ "Check everything"
❌ "Make it faster"

---

**Note:** This is a helper guide. Copy the examples above and use them as `/sub-agent <type> <task>` commands.
