(() => {
  const DEVTOOLS_PASSWORD = '123456';
  let devToolsUnlocked = false;
  let passwordAttempts = 0;
  const maxAttempts = 3;

  // Detect DevTools opening and prevent it
  const blockDevTools = (e) => {
    if (devToolsUnlocked) return;

    const isF12 = e.key === 'F12';
    const isCtrlShiftI = e.ctrlKey && e.shiftKey && e.key === 'I';
    const isCmdOptionI = (e.metaKey || e.ctrlKey) && e.altKey && e.key === 'I';
    const isCtrlShiftC = e.ctrlKey && e.shiftKey && e.key === 'C';
    const isCtrlShiftJ = e.ctrlKey && e.shiftKey && e.key === 'J';

    if (isF12 || isCtrlShiftI || isCmdOptionI || isCtrlShiftC || isCtrlShiftJ) {
      e.preventDefault();
      showPasswordPrompt();
    }
  };

  // Block right-click context menu
  const blockRightClick = (e) => {
    if (devToolsUnlocked) return;
    e.preventDefault();
    showPasswordPrompt();
  };

  // Detect DevTools opening via timing
  let devToolsOpenTime = 0;
  const detectDevToolsOpen = () => {
    if (devToolsUnlocked) return;

    const now = Date.now();
    if (devToolsOpenTime && now - devToolsOpenTime < 100) {
      showPasswordPrompt();
    }
    devToolsOpenTime = now;
  };

  const showPasswordPrompt = () => {
    passwordAttempts++;

    if (passwordAttempts > maxAttempts) {
      alert('Too many incorrect attempts. DevTools access has been temporarily disabled.');
      setTimeout(() => {
        passwordAttempts = 0;
      }, 5000);
      return;
    }

    const password = prompt(
      `🔒 DevTools Access Protected\n\nEnter password to access Developer Tools:\n\nAttempts remaining: ${maxAttempts - passwordAttempts + 1}`,
      ''
    );

    if (password === DEVTOOLS_PASSWORD) {
      devToolsUnlocked = true;
      passwordAttempts = 0;
      alert('✓ DevTools unlocked! You can now access Developer Tools.');
      console.log('%cDeveloper Tools unlocked', 'color: green; font-weight: bold;');
    } else if (password !== null) {
      alert('❌ Incorrect password. Try again.');
    }
  };

  // Initialize protection on page load
  document.addEventListener('DOMContentLoaded', () => {
    document.addEventListener('keydown', blockDevTools);
    document.addEventListener('contextmenu', blockRightClick);
  });

  // Fallback for immediate page load
  document.addEventListener('keydown', blockDevTools);
  document.addEventListener('contextmenu', blockRightClick);

  // Detect window resize (DevTools opening detection)
  window.addEventListener('resize', detectDevToolsOpen);

  // Log that protection is active
  console.log('%cPrestige Men DevTools Protection Active', 'color: #111827; font-weight: bold; font-size: 14px;');
})();
