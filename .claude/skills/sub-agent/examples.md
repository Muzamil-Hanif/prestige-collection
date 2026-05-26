# Sub-Agent Usage Examples

## 🎯 Real-World Examples for Your Project

### 1. Preview HTML Reports (Using html-preview skill)
```
Ask me: "Create a sub-agent to open the test HTML in browser"

I will:
- Spawn an agent
- Instruct it to use ./.claude/skills/html-preview/run.sh
- Open test-example.html
```

**Try now:**
```
Create a sub-agent to preview HTML using: ./.claude/skills/html-preview/test-example.html
```

---

### 2. Explore Codebase (Checkout Screen)
```
Ask me: "Use an explorer agent to find all cart-related code"

The agent will:
- Search through lib/pages/, lib/services/, lib/models/
- Find cart references
- Show you the structure
```

**Try now:**
```
Spawn explorer agent to find all references to "_cartItems" in the codebase
```

---

### 3. Plan New Features
```
Ask me: "Plan how to add a wishlist feature to the app"

The agent will:
- Analyze current architecture
- Design database schema changes
- Suggest Flutter UI/UX approach
- Propose implementation steps
```

**Try now:**
```
Create planning agent to design product filtering by price range
```

---

### 4. Code Review Security
```
Ask me: "Review the checkout_page.dart for security issues"

The agent will:
- Scan for vulnerabilities
- Check input validation
- Verify data handling
```

**Try now:**
```
Spawn reviewer agent to security-review the auth flow
```

---

### 5. Build & Compile
```
Ask me: "Build the Flutter app for iOS and fix errors"

The agent will:
- Run flutter build ios
- Parse errors
- Suggest fixes
```

**Try now:**
```
Create builder agent to build the app and report any issues
```

---

## 💡 Tips for Better Results

### ✅ Good Task Descriptions
- "Explore lib/pages/ and find all files that use SharedPreferences"
- "Review lib/services/api_service.dart for JWT token handling"
- "Plan how to add dark mode to the app"
- "Build the Flutter app for web and show any errors"

### ❌ Avoid Vague Tasks
- "Look at the code"
- "Fix stuff"
- "Make it work"
- "Check everything"

---

## 🔄 Multi-Turn Conversations

After I spawn an agent, you can ask me to continue the conversation:

```
Me: "Create a sub-agent to explore cart code"
(Agent spawns and provides output)

You: "Ask the agent to find the createOrder function"
Me: "I'll ask that agent to search further..."
```

---

## 📋 Command Patterns

### Pattern 1: Simple Task
```
"Create a [type] agent to [do something]"
```
Example: `"Create a general agent to preview the test HTML file"`

### Pattern 2: With File Context
```
"Spawn [type] agent to [task] in [file/path]"
```
Example: `"Spawn explorer agent to find all API calls in lib/services/"`

### Pattern 3: With Requirements
```
"Create [type] agent to [task] and [verify/report/check] [criteria]"
```
Example: `"Create builder agent to build the app and report any TypeErrors"`

---

## 🚀 Your Next Steps

1. **Try Example 1**: Ask me to preview HTML using sub-agent
2. **Try Example 2**: Ask me to explore cart-related code
3. **Try Example 3**: Ask me to plan a new feature
4. **Try Example 4**: Ask me to security-review auth code
5. **Try Example 5**: Ask me to build the app

**Pick any one and say it below!** 👇
