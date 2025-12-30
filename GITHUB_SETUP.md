# GitHub Setup Guide for Prestige Men App

## ✅ Step 1: Create GitHub Repository

1. Go to [GitHub.com](https://github.com) and sign in
2. Click the **"+"** icon in the top right corner
3. Select **"New repository"**
4. Fill in the details:
   - **Repository name**: `prestige-men` (or any name you prefer)
   - **Description**: "Prestige Men - Luxury Men's Accessories Store Flutter App"
   - **Visibility**: Choose **Public** (free) or **Private** (if you have GitHub Pro)
   - **DO NOT** check "Initialize with README" (we already have one)
   - **DO NOT** add .gitignore or license (we already have them)
5. Click **"Create repository"**

## ✅ Step 2: Copy Your Repository URL

After creating the repository, GitHub will show you a page with setup instructions.
Copy the repository URL. It will look like:

- `https://github.com/muzamilhanif37/prestige-men.git` (HTTPS)
- OR `git@github.com:muzamilhanif37/prestige-men.git` (SSH)

## ✅ Step 3: Connect Local Repository to GitHub

Run these commands in your terminal (replace YOUR_USERNAME and REPO_NAME):

```bash
# Add GitHub as remote repository
git remote add origin https://github.com/YOUR_USERNAME/REPO_NAME.git

# Verify the remote was added
git remote -v

# Push your code to GitHub
git push -u origin main
```

**Example:**

```bash
git remote add origin https://github.com/muzamilhanif37/prestige-men.git
git push -u origin main
```

## ✅ Step 4: Authentication

When you run `git push`, GitHub will ask for authentication:

- **Option 1**: Use GitHub Personal Access Token (recommended)

  - Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
  - Generate a new token with `repo` permissions
  - Use this token as your password when pushing

- **Option 2**: Use GitHub CLI (`gh auth login`)

## ✅ Step 5: Verify Your Code is on GitHub

1. Go to your GitHub repository page
2. You should see all your files there
3. Your code is now safely stored on GitHub! 🎉

## 📝 Future Updates

Whenever you make changes to your code, use these commands:

```bash
# Check what files changed
git status

# Add all changed files
git add .

# Commit with a message
git commit -m "Description of your changes"

# Push to GitHub
git push
```

## 🔒 Your Code is Safe!

Once pushed to GitHub:

- ✅ Your code is backed up in the cloud
- ✅ You can access it from anywhere
- ✅ You can share it with others
- ✅ You can track all changes
- ✅ You can restore previous versions

---

**Need Help?** If you encounter any issues, check:

- GitHub documentation: https://docs.github.com
- Git documentation: https://git-scm.com/doc
