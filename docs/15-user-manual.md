# 15 — User Manual

## 1. Getting Started
UniConnect (DECP) is accessible through a web browser. Ensure you are connected to the same network as the host server.

- **URL**: `http://localhost` (or your server's IP address)

## 2. Account Management
### 2.1 Registration
1. Navigate to the **Register** page.
2. Enter your full name, university email, and a secure password.
3. Select your role: **Student**, **Alumni**, or **Admin**.
4. Upon successful registration, you will be redirected to the Login page.

### 2.2 Profile Management
1. After logging in, click the **Profile** link in the navigation bar.
2. Here you can see your basic university details.
3. Click **Edit My Profile** to update your:
    - **Display Name**
    - **Department** (e.g., Computer Engineering)
    - **Graduation Year**
    - **Biography** (Tell others about your interests and goals)

---

## 3. Social Interaction (Department Feed)
The Feed is the central place to stay updated with department announcements and discussions.

### 3.1 Creating a Post
1. Type your update in the "What's happening?" box at the top of the Feed.
2. Click **Post Announcement**.
3. Your post will appear at the top of the Feed for all members to see.

### 3.2 Interacting with Posts
- **Like**: Click the 👍 button to show your support. It will toggle to ❤️ once liked.
- **Comment**: Click the 💬 button to see existing comments and add your own.
- **Reply**: You can reply to any comment by clicking the **Reply** link next to it.
- **Manage**: If you created the post or comment, you will see **Edit** or **Delete** options to manage your content.

---

## 4. Careers & Jobs
This module connects students with professional opportunities posted by alumni and admins.

### 4.1 For Students (Apply)
1. Navigate to the **Careers** page.
2. Browse through available jobs and internships.
3. Click **Apply Internally** on any job that interests you.
4. Fill out a brief **Cover Letter** and provide a link to your **Resume/Portfolio** (e.g., Google Drive link).
5. Click **Submit Application**.

### 4.2 For Alumni/Admins (Post & Track)
1. Use the form at the top of the Careers page to post a new opportunity.
2. Provide a clear title, company name, and detailed description.
3. Once posted, you will see a **View Applicants** button on your specific job card.
4. Clicking this opens a private **Applicant Dashboard** where you can see all students who applied, read their cover letters, and view their resumes.

---

## 5. Security & Privacy
- **Ownership**: You can only edit or delete content (posts, comments, jobs) that you created.
- **Data Protection**: Your password is encrypted using high-security hashing (BCrypt).
- **Session**: Your login remains active for 24 hours (JWT expiration). Always remember to **Logout** when using a shared computer.
