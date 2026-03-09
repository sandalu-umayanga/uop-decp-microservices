# User Manual — Student Role

> **UniConnect — Department Engagement & Career Platform (DECP)**
> CO528 Applied Software Architecture · University of Peradeniya

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Getting Started](#2-getting-started)
   - 2.1 System Requirements
   - 2.2 Accessing the Platform
3. [Account Management](#3-account-management)
   - 3.1 Creating Your Account
   - 3.2 Logging In
   - 3.3 Logging Out
4. [Your Profile](#4-your-profile)
   - 4.1 Viewing Your Profile
   - 4.2 Editing Your Profile
   - 4.3 Profile Analytics
5. [Department Feed](#5-department-feed)
   - 5.1 Browsing the Feed
   - 5.2 Creating a Post
   - 5.3 Liking Posts
   - 5.4 Commenting on Posts
   - 5.5 Replying to Comments
   - 5.6 Editing & Deleting Your Content
6. [Career & Opportunities](#6-career--opportunities)
   - 6.1 Browsing Job & Internship Listings
   - 6.2 Applying for a Position
   - 6.3 Tracking Your Applications
7. [Networking](#7-networking)
   - 7.1 Discovering Department Members
   - 7.2 Searching for People
   - 7.3 Connecting with Others
8. [Responsive Design & Mobile Usage](#8-responsive-design--mobile-usage)
9. [Security & Privacy](#9-security--privacy)
10. [Troubleshooting](#10-troubleshooting)
11. [FAQ](#11-faq)

---

## 1. Introduction

Welcome to **UniConnect**! As a **Student**, you are at the heart of the platform. UniConnect is designed to help you stay connected with your department, engage with peers and alumni, discover career opportunities, and build your professional network — all from a single, modern web application.

### What You Can Do as a Student

| Feature | Description |
|---------|-------------|
| **Feed** | Create posts, like and comment on updates from the department community |
| **Career** | Browse and apply for jobs and internships posted by alumni and administrators |
| **Profile** | Showcase your biography, department, and graduation details |
| **Networking** | Discover and connect with other department members |

---

## 2. Getting Started

### 2.1 System Requirements

| Requirement | Details |
|-------------|---------|
| **Browser** | Google Chrome 90+, Mozilla Firefox 90+, Safari 14+, or Microsoft Edge 90+ |
| **Screen** | Works on phones (320px+), tablets (768px+), and desktops (1100px+) |
| **Network** | Stable internet connection or access to the same local network as the server |

### 2.2 Accessing the Platform

1. Open your web browser.
2. Navigate to the UniConnect URL provided by your administrator:
   - **Local deployment**: `http://localhost`
   - **Cloud deployment**: `https://<your-domain>`
3. You will be presented with the **Login** page.

---

## 3. Account Management

### 3.1 Creating Your Account

1. On the Login page, click the **"Don't have an account? Register"** link at the bottom.
2. You will be redirected to the **Registration** page.
3. Fill in the required fields:

   | Field | Description | Example |
   |-------|-------------|---------|
   | **Full Name** | Your display name on the platform | `Kamal Perera` |
   | **University Email** | A valid email address (used for login) | `kamal@eng.pdn.ac.lk` |
   | **Password** | A secure password (minimum 6 characters recommended) | `••••••••` |
   | **Role** | Select **STUDENT** | `STUDENT` |

4. Click **Create Account**.
5. On success, you will see a confirmation message and can proceed to the Login page.

> **Tip**: Use your university email for easy identification by peers and alumni.

### 3.2 Logging In

1. Enter your registered **email** and **password** on the Login page.
2. Click **Sign in**.
3. If credentials are valid, you will be redirected to the **Feed** page.
4. Your session is valid for **24 hours** (JWT-based authentication).

### 3.3 Logging Out

1. Click the **Logout** button in the navigation bar (top-right on desktop, inside the mobile menu on smaller screens).
2. You will be redirected to the Login page.
3. Your session token is removed from the browser.

> **Important**: Always log out when using a shared or public computer.

---

## 4. Your Profile

### 4.1 Viewing Your Profile

1. Click **Profile** in the navigation bar.
2. Your profile page displays:
   - **Avatar**: Your name initial in a coloured badge.
   - **Name**: Your display name.
   - **Department**: Your affiliated department (e.g., Computer Engineering).
   - **Graduation Year**: Expected or actual graduation year.
   - **Biography**: A personal description visible to other members.
   - **Connection Count**: Number of people you are connected with.

### 4.2 Editing Your Profile

1. On your Profile page, click **Edit Profile**.
2. A modal dialog will appear with editable fields:

   | Field | Description |
   |-------|-------------|
   | **Display Name** | Change how your name appears across the platform |
   | **Department** | Update your department affiliation |
   | **Graduation Year** | Set or update your graduation year |
   | **Short Bio** | Write about your interests, goals, or achievements |

3. Make your changes and click **Save Changes**.
4. A success message confirms the update, and your profile is immediately refreshed.

### 4.3 Profile Analytics

On the right sidebar (or below the main card on mobile), you can see:

| Metric | Description |
|--------|-------------|
| **Profile Views** | Number of times your profile has been viewed |
| **Professional Connections** | Total number of active connections |

---

## 5. Department Feed

The Feed is the social hub of the department, where students, alumni, and administrators share updates, announcements, and discussions.

### 5.1 Browsing the Feed

1. Click **Feed** in the navigation bar (this is also the default page after login).
2. Posts are displayed in reverse chronological order (newest first).
3. Each post shows:
   - Author name and initial avatar
   - Post text content
   - Timestamp
   - Like count and comment count
   - Like button and Comment toggle button

**Layout Notes**:
- On **desktop**: Three-column layout with a left sidebar (your quick stats), the main feed in the centre, and a trending sidebar on the right.
- On **tablets**: Two-column layout (sidebars collapse).
- On **phones**: Single-column layout; sidebars are hidden.

### 5.2 Creating a Post

1. At the top of the Feed page, you will see the **"What's on your mind?"** text area.
2. Type your post content.
3. Click **Post**.
4. Your post immediately appears at the top of the feed.

> **Note**: Currently, text-only posts are supported. Media attachment support is planned for future releases.

### 5.3 Liking Posts

1. Click the **👍** (thumbs up) button on any post.
2. The button changes to **❤️** (red heart) and the like count increments.
3. Click again to **unlike** the post.

### 5.4 Commenting on Posts

1. Click the **💬** (comment) icon on any post to expand the comments section.
2. Existing comments are displayed below the post.
3. Type your comment in the input field at the bottom of the comment section.
4. Click **Post** (or press **Enter**) to submit.
5. Your comment appears instantly.

### 5.5 Replying to Comments

1. Under any comment, click the **Reply** link.
2. A nested reply input appears.
3. Type your reply and submit it.
4. Replies are displayed in a threaded format beneath the parent comment.

### 5.6 Editing & Deleting Your Content

- **Delete a Post**: On your own posts, a **Delete** button is visible. Clicking it permanently removes the post and all its comments.
- **Edit/Delete a Comment**: On your own comments, **Edit** and **Delete** options are available. Use them to correct or remove your comments.

> **Note**: You can only manage content that **you** created. You cannot edit or delete other users' posts or comments.

---

## 6. Career & Opportunities

The Careers page connects you with jobs and internships posted by alumni and administrators.

### 6.1 Browsing Job & Internship Listings

1. Click **Careers** in the navigation bar.
2. All available positions are listed as cards showing:
   - **Job Title**
   - **Company Name**
   - **Type** (JOB or INTERNSHIP)
   - **Description**
   - **Posted Date**

### 6.2 Applying for a Position

1. Find a job or internship that interests you.
2. Click **Apply Internally** on the job card.
3. A modal dialog opens with the application form:

   | Field | Description | Example |
   |-------|-------------|---------|
   | **Cover Letter** | A brief paragraph explaining your interest | `I am excited about this role because…` |
   | **Resume/Portfolio URL** | Link to your resume (Google Drive, LinkedIn, personal site) | `https://drive.google.com/...` |

4. Click **Submit Application**.
5. On success, the modal closes and a confirmation is shown.

> **Important**: You can only apply **once** per job listing. Make sure your cover letter and resume URL are correct before submitting.

### 6.3 Tracking Your Applications

- After applying, your application status can be tracked.
- Possible statuses:

  | Status | Meaning |
  |--------|---------|
  | `SUBMITTED` | Your application has been received |
  | `REVIEWED` | The job poster has reviewed your application |
  | `ACCEPTED` | Congratulations! Your application was accepted |
  | `REJECTED` | The position has been filled or your application was not selected |

---

## 7. Networking

### 7.1 Discovering Department Members

1. Click **Networking** in the navigation bar.
2. A grid of department members is displayed (excluding yourself).
3. Each user card shows:
   - Name initial avatar
   - Full name
   - Department

### 7.2 Searching for People

1. Use the **search bar** at the top of the Networking page.
2. Type a name or department to filter results in real-time.
3. The grid updates instantly as you type.

### 7.3 Connecting with Others

1. On any user card, click the **Connect** button.
2. A connection is established, increasing both your and their connection count.

---

## 8. Responsive Design & Mobile Usage

UniConnect is designed with a **mobile-first** approach and works seamlessly across all device sizes.

| Device | Navigation | Layout |
|--------|------------|--------|
| **Phone** (< 480px) | Hamburger menu (☰) at top-right; tap to open side drawer | Single column; all sidebars hidden |
| **Tablet** (480–768px) | Hamburger menu or partial top bar | Two-column grids; feed sidebars collapse |
| **Desktop** (768px+) | Full horizontal navigation bar | Multi-column layouts with visible sidebars |

### Using on Mobile

1. Tap the **☰** hamburger icon (top-right) to open the navigation drawer.
2. Select a page from the slide-out menu.
3. Tap outside the menu or click the **✕** close icon to dismiss it.
4. The menu automatically closes when you navigate to a new page.

---

## 9. Security & Privacy

| Feature | Detail |
|---------|--------|
| **Password Protection** | Your password is hashed using BCrypt; it is never stored in plain text |
| **Session Security** | Sessions use JWT tokens that expire after 24 hours |
| **Ownership** | You can only edit/delete content you created |
| **Data Visibility** | Your profile is visible to other authenticated platform members |

### Best Practices

- Choose a **strong, unique password** (combine letters, numbers, and symbols).
- **Log out** after each session on shared devices.
- **Do not share** your login credentials with others.
- Report suspicious activity to your platform administrator.

---

## 10. Troubleshooting

| Problem | Possible Cause | Solution |
|---------|---------------|----------|
| Cannot log in | Incorrect email or password | Double-check credentials; use the correct email |
| Page loads but shows nothing | Session expired | Log out and log in again |
| Post/comment not appearing | Network issue | Refresh the page; check your internet connection |
| "Failed to load" error | Backend service is down | Contact your system administrator |
| Mobile menu not opening | JavaScript issue | Hard-refresh the page (Ctrl + Shift + R) |
| Cannot apply for a job | Already applied | Each job allows only one application per student |

---

## 11. FAQ

**Q: Can I change my role after registration?**
A: No. Role changes must be performed by an Admin. Contact your platform administrator if you need a role update.

**Q: Can I delete my account?**
A: Account deletion is not currently self-service. Contact your administrator for account management requests.

**Q: Can I post jobs or internships?**
A: As a Student, you can only **apply** for positions. Job posting is available to Alumni and Admin roles.

**Q: How do I upload a profile picture?**
A: Profile pictures are not yet supported. Your avatar displays the first letter of your name.

**Q: Is there a mobile app?**
A: The web application is fully responsive and works like a mobile app in your browser. A dedicated React Native mobile app is planned for a future release.

**Q: Who can see my posts?**
A: All authenticated users on the platform can see your feed posts. There are no private post settings at this time.

**Q: How do I report inappropriate content?**
A: Contact your platform administrator directly. Admin users have the ability to moderate and remove inappropriate content.

---

*Last updated: March 2026 · UniConnect DECP v1.0*
