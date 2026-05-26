/mco# Design System — Prestige Men

Design tokens and component styles for UI consistency across all modules.

---

## Color Palette

### Primary Colors

| Token          | Hex       | RGB                | Usage                                    |
| -------------- | --------- | ------------------ | ---------------------------------------- |
| **Primary**    | `#111827` | rgb(17, 24, 39)    | Headers, primary text, drawer background |
| **Secondary**  | `#F2C94C` | rgb(242, 201, 76)  | Accent, selected nav items, highlights   |
| **Surface**    | `#1F2937` | rgb(31, 41, 55)    | Cards, bottom nav, input backgrounds     |
| **Background** | `#F5F5F5` | rgb(245, 245, 245) | Page background, scaffold background     |

### Semantic Colors

| Token        | Hex       | RGB                | Usage                                     |
| ------------ | --------- | ------------------ | ----------------------------------------- |
| **Error**    | `#EF4444` | rgb(239, 68, 68)   | Error states, destructive actions, badges |
| **Tertiary** | `#6B7280` | rgb(107, 114, 128) | Secondary text, disabled states           |
| **White**    | `#FFFFFF` | rgb(255, 255, 255) | Primary text on dark surfaces             |
| **Black**    | `#000000` | rgb(0, 0, 0)       | Primary text on light surfaces            |

### Neutral Grays

| Token                                  | Hex                       | Usage                               |
| -------------------------------------- | ------------------------- | ----------------------------------- |
| `Colors.white70`                       | rgba(255, 255, 255, 0.7)  | Secondary icons, hints              |
| `Colors.white24`                       | rgba(255, 255, 255, 0.24) | Dividers, subtle borders            |
| `Colors.black87`                       | rgba(0, 0, 0, 0.87)       | Secondary text on light backgrounds |
| `Colors.white.withValues(alpha: 0.16)` | rgba(255, 255, 255, 0.16) | Hover/focus states on dark surfaces |

### Gradient

**Navigation Bar Gradient:**

```
LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    #1F2A44,  // top-left
    #23395B,  // mid
    #2A3D66,  // bottom-right
  ],
)
```

---

## Typography

### Font Family

- **Default**: System default (Roboto on Android, SF Pro on iOS)
- **Weight options**: w400, w500, w600, w700, bold

### Font Sizes

| Token  | Size      | Usage                          |
| ------ | --------- | ------------------------------ |
| `xs`   | 9px       | Badges, small labels           |
| `sm`   | 12px      | Small text, helper text, hints |
| `base` | 14px–16px | Body text, regular content     |
| `lg`   | 20px      | Subheadings, section titles    |
| `xl`   | 28px      | Page headings                  |

### Text Styles

#### Heading (Page Title)

```dart
TextStyle(
  fontSize: 28,
  fontWeight: FontWeight.bold,
)
```

#### Subheading

```dart
TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.w500,
)
```

#### Body Text (Regular)

```dart
TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w400,
)
```

#### Emphasized Body

```dart
TextStyle(
  fontSize: 14–16,
  fontWeight: FontWeight.w600,
)
```

#### Navigation Label

```dart
TextStyle(
  fontSize: 13,
  fontWeight: FontWeight.w500,  // normal state
  fontWeight: FontWeight.w700,  // selected state
)
```

#### Badge Text

```dart
TextStyle(
  fontSize: 9,
  fontWeight: FontWeight.bold,
  color: Colors.white,
)
```

---

## Spacing

### Base Unit

Base spacing unit: **4px** (scales to 8, 12, 16, 20, 24, 28, 32, etc.)

### Common Spacing Values

| Token | Size | Usage                                |
| ----- | ---- | ------------------------------------ |
| `xs`  | 4px  | Minimal gaps                         |
| `sm`  | 8px  | Tight spacing (nav items, badges)    |
| `md`  | 12px | Medium spacing (padding, gaps)       |
| `lg`  | 16px | Standard padding (cards, containers) |
| `xl`  | 20px | Large padding (form fields)          |
| `2xl` | 24px | Extra large gaps                     |
| `3xl` | 28px | Navigation bar margin                |
| `4xl` | 32px | Large containers                     |

### Common Patterns

```dart
// Padding: Container/Card
padding: const EdgeInsets.all(16),

// Margin: Between elements
margin: const EdgeInsets.only(bottom: 12),

// Form inputs
contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),

// Navigation items
padding: const EdgeInsets.symmetric(vertical: 6),
```

---

## Border Radius

### Radius Tokens

| Token | Value   | Usage                          |
| ----- | ------- | ------------------------------ |
| `sm`  | 10–12px | Input fields, small buttons    |
| `md`  | 16px    | Cards, modals, large buttons   |
| `lg`  | 28px    | Bottom navigation bar, dialogs |

### Common Patterns

```dart
// Input fields
BorderRadius.circular(12),

// Cards
BorderRadius.circular(16),

// Bottom navigation bar
BorderRadius.circular(28),
```

---

## Component Styles

### Cards

```dart
CardThemeData(
  color: colorScheme.surface,  // #1F2937
  elevation: 3,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  ),
)
```

### Input Fields

```dart
InputDecorationTheme(
  filled: true,
  fillColor: colorScheme.surface,  // #1F2937
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: colorScheme.outline),
  ),
  contentPadding: const EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 20,
  ),
)
```

### Bottom Navigation Bar

```dart
BottomNavigationBarThemeData(
  backgroundColor: colorScheme.surface,  // #1F2937
  selectedItemColor: colorScheme.secondary,  // #F2C94C
  unselectedItemColor: Colors.white70,
  showUnselectedLabels: true,
  type: BottomNavigationBarType.fixed,
)
```

### App Bar

```dart
AppBarTheme(
  centerTitle: true,
  elevation: 0,
  backgroundColor: Colors.transparent,
  foregroundColor: Colors.black,
  systemOverlayStyle: SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ),
)
```

### Button Badge (Cart Count)

```dart
Container(
  padding: const EdgeInsets.symmetric(
    horizontal: 5,
    vertical: 1,
  ),
  decoration: BoxDecoration(
    color: Colors.red,  // #EF4444
    borderRadius: BorderRadius.circular(10),
  ),
  child: Text(
    count,
    style: const TextStyle(
      color: Colors.white,
      fontSize: 9,
      fontWeight: FontWeight.bold,
    ),
  ),
)
```

---

## Shadows

### Standard Elevation

```dart
BoxShadow(
  color: const Color(0xFF111827).withValues(alpha: 0.25),
  blurRadius: 18,
  offset: const Offset(0, 8),
)
```

---

## Animations

### Durations

| Token  | Duration  | Usage                              |
| ------ | --------- | ---------------------------------- |
| Fast   | 260–320ms | Icon transitions, small UI changes |
| Normal | 380–420ms | Navigation slides, scale changes   |
| Slow   | 600ms     | Page transitions, body swaps       |

### Common Curves

- `Curves.easeInOutCubic` — balance, smooth feel
- `Curves.easeInOutCubicEmphasized` — emphasized motion
- `Curves.easeInOut` — default smoothing

---

## Usage Guidelines

### New Feature Checklist

When building a new module/page, reference:

1. ✅ **Colors** — Use palette tokens, avoid hardcoding
2. ✅ **Typography** — Match font sizes and weights from this guide
3. ✅ **Spacing** — Use 4px base units (8, 12, 16, 20, 24, etc.)
4. ✅ **Border Radius** — Use sm (12), md (16), or lg (28)
5. ✅ **Shadows** — Use standard elevation pattern
6. ✅ **Animations** — Use documented durations and curves

### Example: New Card Component

```dart
Card(
  color: Theme.of(context).colorScheme.surface,  // #1F2937
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),  // md radius
  ),
  elevation: 3,
  child: Padding(
    padding: const EdgeInsets.all(16),  // lg spacing
    child: Column(
      children: [
        Text(
          'Title',
          style: TextStyle(
            fontSize: 20,  // lg font
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 12),  // md spacing
        Text(
          'Body text',
          style: TextStyle(
            fontSize: 16,  // base font
            color: Colors.white,
          ),
        ),
      ],
    ),
  ),
)
```

---

## References

- **Theme Definition**: `lib/main.dart` (ColorScheme, ThemeData)
- **Component Examples**: See `lib/pages/` for implemented patterns
- **Color Tool**: Use [Coolors.co](https://coolors.co/) to explore palette variations

---

**Last Updated**: 2026-05-19
