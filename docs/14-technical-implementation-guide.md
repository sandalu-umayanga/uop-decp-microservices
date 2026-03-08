# 14 — Technical Implementation Guide

## 1. Executive Summary
UniConnect (DECP) is a microservices-based platform designed for university department engagement. This document details the final technical implementation, spanning from the security-hardened API Gateway to the professional React frontend and Dockerized infrastructure.

## 2. Implemented Architecture

### 2.1 Microservices Overview
| Service | Responsibility | Database | Port |
|---------|----------------|----------|------|
| `user-service` | Identity, Auth, Profiles | MySQL | 8081 |
| `feed-service` | Social Posts, Interactions | MongoDB | 8082 |
| `career-service`| Job Postings, Applications | MySQL | 8083 |
| `api-gateway` | Routing & Security | - | 8080/8088 |
| `web-client` | Frontend UI | - | 80 |

### 2.2 Security & Identity Flow
The platform implements a **Zero-Trust Internal Model**:
1. **Authentication**: `user-service` generates a JWT containing the `id`, `name`, and `role`.
2. **Interception**: `api-gateway` decrypts the JWT using a shared secret.
3. **Identity Injection**: The Gateway injects `X-User-Id`, `X-User-Name`, and `X-User-Role` headers into the downstream request.
4. **Authorization**: Downstream services (Feed/Career) use these headers to verify ownership (e.g., "Can this user delete this post?") without re-validating the token.

## 3. Service Deep-Dives

### 3.1 Social Feed (NoSQL)
- **Model**: Uses a recursive `Comment` document structure to support infinite nesting of replies.
- **Interactions**:
  - `POST /api/posts`: Create post (author taken from Gateway headers).
  - `POST /api/posts/{id}/likes`: Atomic toggle of user IDs in the `likes` array.
  - `POST /api/posts/{id}/comments/{cid}/replies`: Nested document insertion.

### 3.2 Career & ATS (RDBMS)
- **Model**: Relational links between `Jobs` and `Applications` using MySQL.
- **ATS Dashboard**: Implementation of an Applicant Tracking System where Job Owners (Alumni/Admin) can view private cover letters and resumes of students who applied.

### 3.3 Identity (RDBMS)
- **Security**: Password hashing via **BCrypt** with unique salts.
- **Profile**: Extended data model including `department`, `graduation_year`, and `bio`.

## 4. Frontend Design System
The UI was overhauled to follow a professional design language:
- **Base Theme**: "UniConnect Blue" (#004b8d).
- **Components**: Standardized `card`, `btn`, `form-group`, and `badge` classes in `index.css`.
- **UX**: Implementation of "Optimistic UI" patterns for feed updates and modal-based job applications.

## 5. Deployment & Orchestration
The platform is fully containerized for self-hosting on a local PC or server:
- **Reverse Proxy**: Nginx serves the React app and proxies `/api/*` requests to the Gateway.
- **Docker Compose**: Orchestrates 7 containers (4 services, 2 DBs, 1 Frontend) on a private bridge network.
- **Networking**: Uses internal service names (e.g., `http://api-gateway:8080`) for communication, making the platform accessible from any device on the same network.

## 6. API Reference (Core)
- `POST /api/users/register`: Account creation (BCrypt).
- `POST /api/users/login`: JWT generation.
- `GET /api/posts/feed`: Paginated social timeline.
- `POST /api/jobs`: Create career opportunity.
- `GET /api/users/{id}/profile`: Detailed profile fetch.
