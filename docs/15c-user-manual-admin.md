# User Manual — Admin Role

> **UniConnect — Department Engagement & Career Platform (DECP)**
> CO528 Applied Software Architecture · University of Peradeniya

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Getting Started](#2-getting-started)
   - 2.1 System Requirements
   - 2.2 Accessing the Platform
3. [Account Management](#3-account-management)
   - 3.1 Admin Account Setup
   - 3.2 Logging In & Out
4. [User Management](#4-user-management)
   - 4.1 Viewing the User List
   - 4.2 Assigning & Changing Roles
   - 4.3 Activating / Deactivating Accounts
5. [Content Moderation](#5-content-moderation)
   - 5.1 Monitoring the Feed
   - 5.2 Removing Inappropriate Posts
   - 5.3 Moderation Guidelines
6. [Career & Opportunities — Posting Jobs](#6-career--opportunities--posting-jobs)
   - 6.1 Posting Official Opportunities
   - 6.2 Reviewing Applicants
   - 6.3 Managing Organisation-Submitted Listings
7. [Department Feed (Read & Moderate)](#7-department-feed-read--moderate)
8. [Networking & Community Overview](#8-networking--community-overview)
9. [Dashboard & Analytics](#9-dashboard--analytics)
10. [Responsive Design & Mobile Usage](#10-responsive-design--mobile-usage)
11. [Security & Access Control](#11-security--access-control)
12. [Troubleshooting](#12-troubleshooting)
13. [FAQ](#13-faq)

---

## 1. Introduction

Welcome to **UniConnect**! As a **Platform Administrator**, you have the highest level of access and responsibility. You ensure the platform runs smoothly, content stays appropriate, users are managed correctly, and official career opportunities are posted on behalf of the department.

### Admin Capabilities at a Glance

| Feature | Description |
|---------|-------------|
| **User Management** | View all users, assign/change roles, activate/deactivate accounts |
| **Content Moderation** | Monitor and remove inappropriate posts from any user |
| **Career Posting** | Post official job/internship listings; manage organisation partnerships |
| **Feed Monitoring** | View the department feed to stay informed |
| **Networking Overview** | See the full member directory |

### Role Comparison — What Makes Admin Different

| Capability | Student | Alumni | Admin |
|------------|---------|--------|-------|
| Register account | ✅ | ✅ | — (pre-created or self-register) |
| Edit own profile | ✅ | ✅ | — |
| Create feed posts | ✅ | ✅ | ❌ (monitor only) |
| Like / comment | ✅ | ✅ | ❌ (monitor only) |
| Delete own posts | ✅ | ✅ | — |
| **Moderate any post** | ❌ | ❌ | ✅ |
| Apply for jobs | ✅ | ❌ | ❌ |
| **Post jobs** | ❌ | ✅ | ✅ |
| **Manage users** | ❌ | ❌ | ✅ |
| **Assign roles** | ❌ | ❌ | ✅ |

---

## 2. Getting Started

### 2.1 System Requirements

| Requirement | Details |
|-------------|---------|
| **Browser** | Chrome 90+, Firefox 90+, Safari 14+, or Edge 90+ |
| **Screen** | Responsive on all devices (320px+ phones to full desktops) |
| **Network** | Stable internet or same-network access to the server |

### 2.2 Accessing the Platform

1. Open your browser and navigate to the UniConnect URL:
   - **Local**: `http://localhost`
   - **Cloud**: `https://<your-domain>`
2. You will see the Login page.

---

## 3. Account Management

### 3.1 Admin Account Setup

Admin accounts can be created in two ways:

1. **Self-Registration**: Navigate to the Register page and select the **ADMIN** role.
2. **Pre-Created**: A system administrator can create an Admin account directly.

> **Security Note**: In a production environment, Admin registration should be restricted. Only authorised personnel should have Admin access. Consider disabling public Admin self-registration and having the system administrator create Admin accounts directly in the database.

| Field | Description | Example |
|-------|-------------|---------|
| **Full Name** | Admin display name | `Dr. Rajitha Jayasinghe` |
| **Email** | Official admin email | `admin@ce.pdn.ac.lk` |
| **Password** | Strong password (12+ characters recommended) | `••••••••••••` |
| **Role** | Select **ADMIN** | `ADMIN` |

### 3.2 Logging In & Out

- **Login**: Enter email and password → Click **Sign in**.
- **Logout**: Click **Logout** in the navigation bar.
- Sessions last **24 hours** (JWT-based).

---

## 4. User Management

User management is a core Admin responsibility. You oversee who has access to the platform and in what capacity.

### 4.1 Viewing the User List

1. The platform provides access to the full list of registered users.
2. Navigate to the **Networking** page to see all members.
3. Each user card displays:
   - Name and avatar
   - Department
   - Role badge (if shown)

> **Note**: The `/api/users/list` API endpoint provides the complete user registry for administrative purposes.

### 4.2 Assigning & Changing Roles

As an Admin, you can promote or change user roles:

| Action | Use Case |
|--------|----------|
| Student → Alumni | When a student graduates |
| Alumni → Student | Rare; role correction |
| Student/Alumni → Admin | Appointing a new moderator |

**How to Change a Role**:
1. Identify the user through the Networking page or user list.
2. Use the role assignment functionality (via API: `PUT /api/users/{id}/role`).
3. The change takes effect immediately on the user's next request.

### 4.3 Activating / Deactivating Accounts

| Status | Meaning |
|--------|---------|
| **ACTIVE** | User can log in and use all features |
| **INACTIVE** | User is blocked from accessing the platform |

**When to Deactivate**:
- User has left the department permanently
- Account shows suspicious or malicious activity
- User requests account suspension
- Policy violations after warnings

---

## 5. Content Moderation

Maintaining a professional, respectful community is one of your primary duties.

### 5.1 Monitoring the Feed

1. Click **Feed** in the navigation bar.
2. Browse all posts chronologically.
3. Look for content that violates community standards.

### 5.2 Removing Inappropriate Posts

As an Admin, you have the ability to **delete any post** from any user:

1. Identify the problematic post on the Feed.
2. Click the **Delete** or **Moderate** action on the post.
3. The post and all its comments are permanently removed.

> **Important**: Moderation actions are permanent. There is no undo. Exercise discretion and establish clear moderation policies.

### 5.3 Moderation Guidelines

Follow these principles when moderating content:

| Category | Action |
|----------|--------|
| **Spam or advertisements** | Remove immediately |
| **Offensive language or hate speech** | Remove and consider deactivating the account |
| **Misinformation** | Add a corrective comment or remove if harmful |
| **Off-topic but harmless** | Consider leaving it; community will self-moderate |
| **Duplicate posts** | Remove duplicates, keep the original |
| **Personal disputes** | Monitor; intervene if it escalates |
| **Copyrighted content** | Remove and notify the poster |

**Recommended Moderation Workflow**:

```
1. Observe → 2. Assess severity → 3. Act (remove/warn) → 4. Document → 5. Follow up
```

---

## 6. Career & Opportunities — Posting Jobs

### 6.1 Posting Official Opportunities

Admins can post career opportunities on behalf of the department or partner organisations.

1. Navigate to the **Careers** page.
2. Use the **"Post a New Opportunity"** form at the top.
3. Fill in:

   | Field | Description | Example |
   |-------|-------------|---------|
   | **Job Title** | Clear, descriptive title | `Research Assistant — AI Lab` |
   | **Company** | Department or organisation name | `UoP — Computer Engineering` |
   | **Description** | Full details: responsibilities, requirements, benefits | `The AI Lab seeks…` |

4. Click **Post Job**.

### 6.2 Reviewing Applicants

1. On your posted job card, click **View Applicants**.
2. The ATS (Applicant Tracking System) dashboard shows:
   - Applicant name
   - Cover letter content
   - Resume/portfolio URL
   - Application status
   - Submission date

3. Use this information to forward qualified candidates to the appropriate department or company contact.

### 6.3 Managing Organisation-Submitted Listings

For external companies or academics who want to post through the platform:

1. Receive the job details from the external party (email, form, etc.).
2. Create the listing on their behalf using the Careers form.
3. Note the organisation name in the **Company** field.
4. Monitor applications and relay them to the external party.

---

## 7. Department Feed (Read & Moderate)

The Admin role is primarily a **monitoring** role on the Feed:

| Action | Admin Capability |
|--------|-----------------|
| Read all posts | ✅ |
| Moderate/delete any post | ✅ |
| Create posts | Per design: monitoring focus; can create if needed |
| Like & comment | Per design: monitoring focus |

### Monitoring Routine Suggestion

| Frequency | Task |
|-----------|------|
| **Daily** | Scan the feed for policy violations |
| **Weekly** | Review new registrations and user activity |
| **Monthly** | Audit active job listings and remove expired ones |

---

## 8. Networking & Community Overview

1. Navigate to the **Networking** page.
2. View all registered members across all roles.
3. Use the **search bar** to find specific users by name or department.
4. This view serves as your user registry for management purposes.

---

## 9. Dashboard & Analytics

### Platform-Level Metrics

As Admin, you have visibility into:

| Metric | Where to Find |
|--------|---------------|
| Total registered users | Networking page (member count) |
| Active job postings | Careers page |
| Feed activity | Feed page (post volume, engagement) |
| Profile analytics | Your own profile sidebar |

### User-Level Monitoring

Through the user list and profiles:
- View each user's profile, department, and bio
- Check connection counts as a proxy for engagement
- Monitor profile completeness across the community

---

## 10. Responsive Design & Mobile Usage

| Device | Navigation | Best For |
|--------|------------|----------|
| **Phone** | Hamburger menu (☰) | Quick moderation checks, reviewing alerts |
| **Tablet** | Compact navigation | Content review, applicant screening |
| **Desktop** | Full navigation bar | User management, detailed analysis, job posting |

The platform is fully functional on all devices. For detailed management tasks (bulk user review, detailed applicant screening), desktop is recommended.

---

## 11. Security & Access Control

### Admin-Specific Security

| Feature | Detail |
|---------|--------|
| **Elevated Permissions** | Admins can moderate any content and manage users |
| **JWT Authentication** | Same 24-hour token as other roles |
| **Password Security** | BCrypt-hashed, never stored in plain text |
| **Audit Trail** | Actions are logged at the API level |

### Security Best Practices for Admins

| Practice | Reason |
|----------|--------|
| Use a **strong, unique password** (12+ characters) | Admin accounts are high-value targets |
| **Never share** your admin credentials | Each admin should have their own account |
| **Log out** after every session | Prevents unauthorised access |
| **Review** user registrations regularly | Detect fake or spam accounts early |
| **Limit** Admin accounts | Only grant Admin role to trusted personnel |
| **Document** moderation actions | Maintain transparency and accountability |

### Access Control Matrix

| Resource | Student | Alumni | Admin |
|----------|---------|--------|-------|
| Own posts | CRUD | CRUD | — |
| Other users' posts | Read | Read | Read + Delete |
| Own profile | Read + Update | Read + Update | — |
| Other users' profiles | Read | Read | Read |
| Job listings | Read + Apply | Read + Create | Read + Create |
| Applicant data | — | Own listings | Own listings |
| User list | Read (Networking) | Read (Networking) | Full management |
| Role assignment | — | — | ✅ |
| Account activation | — | — | ✅ |

---

## 12. Troubleshooting

| Problem | Solution |
|---------|----------|
| Cannot see moderation controls | Ensure you are logged in with an ADMIN role account |
| Job posting form not visible | Refresh the page; check your session has not expired |
| Cannot deactivate a user | Use the API endpoint; UI feature may require admin panel extension |
| Feed loads slowly | Large number of posts; pagination handles this; check network |
| User complains about deleted post | Verify it was a policy violation; communicate the reason |
| Multiple admin accounts conflicting | Establish a moderation schedule; document actions |

---

## 13. FAQ

**Q: Can there be multiple Admin accounts?**
A: Yes. Multiple users can have the Admin role. Coordinate responsibilities to avoid conflicts.

**Q: Can I create posts on the Feed?**
A: The Admin role is designed primarily for monitoring and moderation. Depending on the implementation, you may be able to create posts, but the primary focus is platform governance.

**Q: Can I apply for jobs?**
A: No. Job applications are exclusive to the Student role. As Admin, you can post jobs and review applicants.

**Q: How do I remove a user permanently?**
A: Deactivate the user account (set status to INACTIVE). Full account deletion may require database-level intervention by the system administrator.

**Q: Can I see all applications across all jobs?**
A: You can see applications for jobs **you** posted. For a complete view of all applications, database-level access is needed.

**Q: How do I handle a content dispute between users?**
A: Review the content objectively, apply moderation guidelines, remove violating content, and communicate the policy to both parties.

**Q: Is there an admin-specific dashboard?**
A: The current version uses the same interface for all roles with elevated permissions for Admin. A dedicated admin dashboard is planned for a future release.

**Q: Can Admin accounts be deleted?**
A: Only another Admin or the system administrator can deactivate an Admin account. Self-deletion is not supported.

---

*Last updated: March 2026 · UniConnect DECP v1.0*
