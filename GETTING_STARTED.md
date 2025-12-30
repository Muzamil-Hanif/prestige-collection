# 🚀 Getting Started with Your Flutter App

## 📍 Project Location

Your Flutter project is located at:
```
/Users/devexcel-management/my_first_app
```

Or in short form:
```
~/my_first_app
```

## 📁 Important Files & Folders

- **`lib/main.dart`** - This is your MAIN CODE FILE! All your app logic goes here
- **`pubspec.yaml`** - Project configuration and dependencies
- **`android/`** - Android-specific code (if you want to build for Android)
- **`ios/`** - iOS-specific code (if you want to build for iPhone/iPad)
- **`web/`** - Web-specific code (if you want to run in browser)
- **`macos/`** - macOS desktop app code
- **`test/`** - Unit tests for your app

## ▶️ How to Run Your Project

### Step 1: Open Terminal and Navigate to Project
```bash
cd ~/my_first_app
```

### Step 2: Check Available Devices
```bash
flutter devices
```

### Step 3: Run on Different Platforms

**Run on Chrome (Web Browser):**
```bash
flutter run -d chrome
```

**Run on macOS Desktop:**
```bash
flutter run -d macos
```

**Run on iOS Simulator:**
```bash
flutter run -d ios
```

**Run on Connected iPhone:**
```bash
flutter run -d ios
# (Make sure your iPhone is connected and unlocked)
```

### Step 4: While App is Running
- Press **`r`** in terminal = Hot Reload (quick update)
- Press **`R`** in terminal = Hot Restart (full restart)
- Press **`q`** in terminal = Quit the app

## 🎓 Understanding Your First App

### What the App Does
This is a simple counter app that:
- Shows a number starting at 0
- Has a floating "+" button
- When you click the button, the number increases

### Key Concepts in `lib/main.dart`:

1. **`main()` function** (line 3-5)
   - Entry point of your app
   - Calls `runApp()` to start Flutter

2. **`MyApp` class** (line 7-36)
   - Root widget of your app
   - Sets up the theme and home page

3. **`MyHomePage` class** (line 38-54)
   - The main page widget
   - Receives a title

4. **`_MyHomePageState` class** (line 56-122)
   - Manages the state (the counter number)
   - `_counter` variable stores the count
   - `_incrementCounter()` function increases the count
   - `build()` method creates the UI

### Try These Changes:

1. **Change the title:**
   - Find line 33: `home: const MyHomePage(title: 'Flutter Demo Home Page')`
   - Change to: `home: const MyHomePage(title: 'My Awesome App')`
   - Save and press `r` for hot reload!

2. **Change the color:**
   - Find line 31: `seedColor: Colors.deepPurple`
   - Change to: `seedColor: Colors.green` or `Colors.blue`
   - Save and hot reload!

3. **Change the button text:**
   - Find line 107: `'You have pushed the button this many times:'`
   - Change to your own message
   - Save and hot reload!

## 🔥 Hot Reload vs Hot Restart

- **Hot Reload (`r`)**: Fast! Updates UI instantly, keeps app state
- **Hot Restart (`R`)**: Slower, but resets app state (counter goes back to 0)

## 📚 Learning Resources

1. **Official Flutter Docs**: https://docs.flutter.dev/
2. **Flutter Widget Catalog**: https://docs.flutter.dev/ui/widgets
3. **Dart Language Tour**: https://dart.dev/guides/language/language-tour
4. **Flutter YouTube Channel**: https://www.youtube.com/c/flutterdev

## 💡 Next Steps

1. ✅ Edit `lib/main.dart` and experiment
2. ✅ Try running on different devices
3. ✅ Learn about Flutter widgets (Text, Container, Row, Column, etc.)
4. ✅ Build a simple app (calculator, todo list, etc.)

Happy coding! 🎉

