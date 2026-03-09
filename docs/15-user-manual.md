# 15 — User Manual (Index)

> **UniConnect — Department Engagement & Career Platform (DECP)**
> CO528 Applied Software Architecture · University of Peradeniya

---

## Overview

UniConnect (DECP) is accessible through a web browser. Navigate to `http://localhost` (or your server's IP / cloud domain) to get started.

This document serves as the **index** for the comprehensive, role-specific user manuals. Each role has dedicated documentation covering every feature, workflow, and capability available to that user type.

---

## Role-Specific User Manuals

| # | Manual | Audience | Document |
|---|--------|----------|----------|
| 1 | **Student Manual** | Current students of the department | [15a — Student](15a-user-manual-student.md) |
| 2 | **Alumni Manual** | Past students / graduates | [15b — Alumni](15b-user-manual-alumni.md) |
| 3 | **Admin Manual** | Platform administrators and moderators | [15c — Admin](15c-user-manual-admin.md) |
| 4 | **System Admin / DevOps Manual** | Infrastructure engineers and system administrators | [15d — System Admin](15d-user-manual-sysadmin.md) |

---

## Quick-Start Summary

### 1. Account Management
1. Navigate to the **Register** page.
2. Enter your full name, university email, and a secure password.
3. Select your role: **Student**, **Alumni**, or **Admin**.
4. Upon successful registration, you will be redirected to the Login page.

### 2. Profile Management
1. After logging in, click the **Profile** link in the navigation bar.
2. Click **Edit Profile** to update your Display Name, Department, Graduation Year, and Biography.

### 3. Department Feed
- **Create**: Type your post in the "What's on your mind?" box and click **Post**.
- **Like**: Click 👍 to like; click ❤️ to unlike.
- **Comment**: Click 💬 to expand comments; type and press Enter or click Post.
- **Manage**: Edit or Delete your own posts and comments.

### 4. Careers & Jobs
- **Students**: Browse listings and click **Apply Internally** to submit a cover letter + resume URL.
- **Alumni / Admins**: Use the form at the top to post opportunities; click **View Applicants** to see applications.

### 5. Networking
- Browse members on the **Networking** page, search by name/department, and click **Connect**.

### 6. Security & Privacy
- Passwords are BCrypt-hashed and never stored in plain text.
- Sessions last 24 hours (JWT). Always **Logout** on shared devices.
- You can only edit/delete content you created.

---

## Access Control Summary

| Capability | Student | Alumni | Admin |
|------------|---------|--------|-------|
| Register & Login | ✅ | ✅ | ✅ |
| Edit Profile | ✅ | ✅ | — |
| Create Feed Posts | ✅ | ✅ | Monitor |
| Like & Comment | ✅ | ✅ | Monitor |
| Moderate Any Post | — | — | ✅ |
| Apply for Jobs | ✅ | — | — |
| Post Jobs | — | ✅ | ✅ |
| View Applicants | — | ✅ (own) | ✅ (own) |
| Manage Users | — | — | ✅ |
| Assign Roles | — | — | ✅ |

---

*For comprehensive instructions, please refer to the role-specific manual linked above.*

*Last updated: March 2026 · UniConnect DECP v1.0*
