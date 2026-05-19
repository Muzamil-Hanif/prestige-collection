# Validate Design

Audit new/modified pages against design.md tokens. Ensure colors, fonts, spacing, and radius match design system.

## When to use
- After building new page/component
- Before commit (catch design drift)
- Code review: verify design consistency
- Refactoring existing pages

---

## Steps

### 1. Identify Changed Files
Ask: Which page/component was modified?

Example: `lib/pages/my_profile_page.dart`

### 2. Check for Hardcoded Values
Scan for:
- **Colors**: `Color(0x...)`, `Colors.red`, `#FF0000`
- **Font sizes**: `fontSize: 15`, `fontSize: 22`
- **Font weights**: `fontWeight: FontWeight.w600`
- **Padding/Margin**: `EdgeInsets.all(15)`, `EdgeInsets.only(left: 18)`
- **Border radius**: `BorderRadius.circular(14)`, `BorderRadius.circular(20)`

### 3. Cross-Check Against design.md

**Colors** (must use these):
```
Primary:     #111827
Secondary:   #F2C94C
Surface:     #1F2937
Background:  #F5F5F5
Error:       #EF4444
Tertiary:    #6B7280
```

**Font Sizes** (allowed):
```
9px, 12px, 13px, 14px, 16px, 20px, 28px
```

**Font Weights** (allowed):
```
w400, w500, w600, w700 (bold)
```

**Spacing** (must be multiples of 4):
```
4, 8, 12, 16, 20, 24, 28, 32, ...
```

**Border Radius** (use these):
```
12px (sm) — inputs, small buttons
16px (md) — cards, modals
28px (lg) — bottom nav, dialogs
```

### 4. Flag Deviations

Example findings:
```
❌ lib/pages/my_profile_page.dart:42
   Color(0xFF00FF00) — not in palette
   → Use: Color(0xFFF2C94C) (secondary)

❌ lib/pages/my_profile_page.dart:67
   fontSize: 18 — not allowed (use 16 or 20)
   → Use: fontSize: 16 or 20

❌ lib/pages/my_profile_page.dart:90
   EdgeInsets.all(15) — not divisible by 4
   → Use: EdgeInsets.all(16)

❌ lib/pages/my_profile_page.dart:105
   BorderRadius.circular(18) — not in {12, 16, 28}
   → Use: BorderRadius.circular(16)
```

### 5. Report

**Format:**
```
File: lib/pages/new_page.dart

Deviations Found:
- Line X: [Issue] → Fix
- Line Y: [Issue] → Fix

Status: ✅ Compliant / ⚠️ Needs Fixes
```

---

## Quick Validation Checklist

- ✅ All colors from palette
- ✅ Font sizes are {9, 12, 13, 14, 16, 20, 28}
- ✅ Font weights are {400, 500, 600, 700}
- ✅ Padding/margin divisible by 4
- ✅ Border radius in {12, 16, 28}
- ✅ Uses theme colors: `Theme.of(context).colorScheme.primary`
- ✅ No magic numbers (hardcoded values)

---

## Example: Compliant Component

```dart
// ✅ Good
Card(
  color: Theme.of(context).colorScheme.surface,  // #1F2937
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),  // md
  ),
  child: Padding(
    padding: const EdgeInsets.all(16),  // lg spacing
    child: Column(
      children: [
        Text(
          'Title',
          style: TextStyle(
            fontSize: 20,  // allowed
            fontWeight: FontWeight.w600,  // allowed
          ),
        ),
        SizedBox(height: 12),  // md spacing
        Text(
          'Body',
          style: TextStyle(
            fontSize: 16,  // allowed
            color: Colors.white,
          ),
        ),
      ],
    ),
  ),
)
```

---

**Reference**: See `design.md` for complete palette, sizes, and component examples.

**Run after**: Building new pages, before code review
