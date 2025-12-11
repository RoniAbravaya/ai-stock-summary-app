# Quick Fix: Share Test Credentials on Google Play Console

## Your Test Account
```
Email: test@test.com
Password: 123456
```

---

## 5-Minute Fix Process

### Step 1: Open Google Play Console
Go to: https://play.google.com/console

### Step 2: Find "App Access"
**Method A** - Via Sidebar:
```
Select your app → App content → App access
```

**Method B** - Via Search:
```
Use search bar → Type "App access" → Click result
```

### Step 3: Declare Restrictions
- Click on **"App access"**
- Select: **"All or some functionality is restricted"**
- Click **"Manage"** or **"Add instructions"**

### Step 4: Paste Instructions
Copy and paste this exactly:

```
TEST CREDENTIALS:
Email: test@test.com
Password: 123456

HOW TO SIGN IN:
1. Open the app
2. Tap "Sign In"
3. Select "Sign in with Email"
4. Enter credentials above
5. Tap "Sign In"

The account provides full access to all app features including:
- Stock quotes and charts
- AI-powered summaries
- Favorites management
- News feed
- User settings

Note: This account is active 24/7 and accessible from any location.
```

### Step 5: Save
- Scroll down
- Click **"Save"** button
- Wait for confirmation

### Step 6: Resubmit
- Go to **"Publishing overview"** (left sidebar)
- Find **"Changes ready to send for review"**
- Click **"Send for review"**
- Done! ✅

---

## Before You Submit: Test It!

1. **Open your app**
2. **Sign in with**: test@test.com / 123456
3. **Verify**: Everything works properly
4. **If login fails**: Check Firebase Console → Authentication

---

## Expected Timeline

- **Today**: Configure and resubmit
- **Tomorrow**: Review starts
- **2-3 days**: Approval decision
- **Total**: ~3 days from now

---

## Screenshots Reference

When you're in Google Play Console, you're looking for:

**Left Sidebar:**
```
🏠 Dashboard
📱 App content       ← Click here
   └─ 🔐 App access  ← Then click here
📊 Release
⚙️ Setup
```

**App Access Page:**
```
┌─────────────────────────────────────────┐
│ App access                              │
├─────────────────────────────────────────┤
│                                         │
│ Does your app have restricted features? │
│                                         │
│ ○ No restrictions                       │
│ ● All or some functionality restricted  │ ← Select this
│                                         │
│ [Manage] button                         │ ← Click this
└─────────────────────────────────────────┘
```

**Instructions Form:**
```
┌─────────────────────────────────────────┐
│ App access details                      │
├─────────────────────────────────────────┤
│                                         │
│ Instructions for access:                │
│ ┌─────────────────────────────────────┐ │
│ │ [Paste your credentials here]       │ │
│ │                                     │ │
│ │                                     │ │
│ └─────────────────────────────────────┘ │
│                                         │
│             [Cancel]  [Save]            │ ← Click Save
└─────────────────────────────────────────┘
```

---

## Troubleshooting

### Can't find "App access"?
- Try searching "App access" in the top search bar
- Or go: App content → Look for "App access" card
- Different Play Console versions may vary slightly

### Save button is grayed out?
- Make sure you filled in the instructions box
- Instructions must be in English
- Check for validation errors at the top

### Still confused?
Google's official guide: https://support.google.com/googleplay/android-developer/answer/9859455

---

## Quick Checklist

- [ ] Tested login with test@test.com
- [ ] Opened Google Play Console
- [ ] Found "App access" section
- [ ] Selected "restricted functionality"
- [ ] Pasted test credentials
- [ ] Saved changes
- [ ] Went to Publishing overview
- [ ] Clicked "Send for review"
- [ ] Done! ✅

---

**Time to complete**: 5-10 minutes  
**Time until approval**: 1-3 business days  
**No code changes needed**: This is just configuration!

Good luck! 🚀
