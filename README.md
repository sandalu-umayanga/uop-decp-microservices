# UniConnect — Department Engagement & Career Platform (DECP)

> **CO528 Applied Software Architecture — Mini Project**
> Department of Computer Engineering, University of Peradeniya

## 🎓 Overview

**UniConnect** is a modern, microservices-based department engagement platform designed for students, alumni, and administrators. It bridges the gap between academic life and professional careers by providing a centralized space for department announcements, social interaction, and career opportunity management.

The project focuses on **architectural design**, **security-hardened microservices**, **polyglot persistence**, and **full containerization**.

---

## 🏗️ Architecture at a Glance

- **Architecture Style**: Service-Oriented Architecture (SOA) / Microservices
- **Backend Stack**: Java 21, Spring Boot 4.x, Spring Cloud Gateway
- **Frontend Stack**: React 19 (Vite), Nginx (Reverse Proxy)
- **Security**: JWT (JSON Web Token) + Gateway Identity Header Injection
- **Databases**: 
  - **MySQL**: Relational data (Users, Jobs, Applications)
  - **MongoDB**: Document data (Social Feed, Nested Comments)
- **Infrastructure**: Docker & Docker Compose (Full Orchestration)

---

## 🚀 Quick Deployment (Local Server)

UniConnect is fully containerized and ready to run on your local PC.

### Prerequisites
- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

### Launch the Platform
1. Clone the repository and navigate to the root folder.
2. Run the orchestration command:
   ```bash
   docker-compose up -d --build
   ```
3. Once the build finishes, open your browser:
   - **Frontend UI**: [http://localhost](http://localhost) (Port 80)
   - **API Gateway**: [http://localhost:8088](http://localhost:8088)

---

## 📁 Documentation Index

| # | Document | Description |
|---|----------|-------------|
| 1 | [Project Overview](docs/01-project-overview.md) | Scope, objectives, and functional requirements |
| 2 | [Technical Implementation](docs/14-technical-implementation-guide.md) | **[NEW]** Deep-dive into security, identity, and service logic |
| 3 | [User Manual](docs/15-user-manual.md) | **[NEW]** How to register, post updates, and apply for jobs |
| 4 | [Data Model](docs/08-data-model.md) | ER diagrams and MongoDB document schemas |
| 5 | [API Specification](docs/07-api-specification.md) | Full REST endpoint reference for all services |
| 6 | [Cloud Deployment](docs/12-cloud-deployment.md) | AWS/GCP strategy and Kubernetes configuration |

---

## 🛠️ Key Features

### 🔐 Security & Identity
- **Centralized Auth**: JWT-based authentication via the API Gateway.
- **Identity Proxy**: Gateway decrypts tokens and injects secure user headers (`X-User-Id`, `X-User-Name`) for downstream services.
- **BCrypt Hashing**: Passwords are never stored in plain text.

### 📢 Department Feed (Social)
- **Recursive Replies**: Infinite nesting of comments and replies in the social feed.
- **Engagement**: Real-time likes, comment editing, and deletion by owners.

### 💼 Careers & Jobs
- **ATS Dashboard**: Private applicant tracking system for job posters (Alumni/Admin).
- **Internal Applications**: Seamless job application process for students.

### 👤 Profile Management
- **Extended Profiles**: Member bios, graduation years, and department affiliation.

---

## 📜 License

This project is developed for academic purposes as part of CO528 — Applied Software Architecture.
