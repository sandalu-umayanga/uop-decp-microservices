# User Manual — System Administrator / DevOps

> **UniConnect — Department Engagement & Career Platform (DECP)**
> CO528 Applied Software Architecture · University of Peradeniya

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Architecture Overview](#2-architecture-overview)
   - 2.1 Service Map
   - 2.2 Technology Stack
   - 2.3 Network Topology
3. [Prerequisites](#3-prerequisites)
4. [Local Deployment with Docker Compose](#4-local-deployment-with-docker-compose)
   - 4.1 Clone the Repository
   - 4.2 Build & Start All Services
   - 4.3 Verifying the Deployment
   - 4.4 Stopping the Platform
5. [Service Configuration](#5-service-configuration)
   - 5.1 Environment Variables
   - 5.2 Database Configuration
   - 5.3 API Gateway Configuration
   - 5.4 Nginx (Web Client) Configuration
6. [Database Administration](#6-database-administration)
   - 6.1 MySQL (User Service & Career Service)
   - 6.2 MongoDB (Feed Service)
   - 6.3 Backup & Restore
7. [Security Configuration](#7-security-configuration)
   - 7.1 JWT Secret Management
   - 7.2 CORS Configuration
   - 7.3 Password Hashing
   - 7.4 Hardening Checklist
8. [Cloud Deployment](#8-cloud-deployment)
   - 8.1 Kubernetes (EKS / GKE)
   - 8.2 Managed Databases
   - 8.3 Container Registry
   - 8.4 Ingress & TLS
9. [Monitoring & Logging](#9-monitoring--logging)
10. [Scaling & Performance](#10-scaling--performance)
11. [Maintenance Procedures](#11-maintenance-procedures)
    - 11.1 Updating a Service
    - 11.2 Database Migrations
    - 11.3 Log Rotation
    - 11.4 Health Checks
12. [Troubleshooting](#12-troubleshooting)
13. [Disaster Recovery](#13-disaster-recovery)
14. [Reference](#14-reference)

---

## 1. Introduction

This manual is for the **System Administrator** or **DevOps Engineer** responsible for deploying, configuring, maintaining, and monitoring the UniConnect platform. It covers the full infrastructure lifecycle — from initial local deployment through production cloud hosting.

### Your Responsibilities

| Area | Tasks |
|------|-------|
| **Deployment** | Build, deploy, and orchestrate all microservices |
| **Configuration** | Manage environment variables, secrets, and network settings |
| **Database** | Administer MySQL and MongoDB instances; manage backups |
| **Security** | Manage JWT secrets, CORS policies, and access controls |
| **Monitoring** | Monitor service health, logs, and performance metrics |
| **Scaling** | Scale services based on load; manage Kubernetes replicas |
| **Maintenance** | Apply updates, perform migrations, handle incidents |

---

## 2. Architecture Overview

### 2.1 Service Map

```
┌─────────────┐     ┌──────────────┐     ┌────────────────┐
│  Web Client │────▶│  API Gateway │────▶│  User Service  │──▶ MySQL
│  (Nginx:80) │     │  (Spring:8080│     │  (Spring:8081) │
└─────────────┘     │   /ext:8088) │     └────────────────┘
                    │              │
                    │              │────▶┌────────────────┐
                    │              │     │  Feed Service  │──▶ MongoDB
                    │              │     │  (Spring:8082) │
                    │              │     └────────────────┘
                    │              │
                    │              │────▶┌────────────────┐
                    └──────────────┘     │ Career Service │──▶ MySQL
                                        │  (Spring:8083) │
                                        └────────────────┘
```

### 2.2 Technology Stack

| Component | Technology | Version |
|-----------|-----------|---------|
| API Gateway | Spring Cloud Gateway | Spring Boot 4.0.3, Java 21 |
| User Service | Spring Boot | 4.0.3, Java 21, MySQL |
| Feed Service | Spring Boot | 3.3.2, Java 21, MongoDB |
| Career Service | Spring Boot | 4.0.3, Java 21, MySQL |
| Web Client | React 19 + Vite 7 | Served by Nginx |
| MySQL | MySQL Server | 8.0 |
| MongoDB | MongoDB Community | Latest |
| Containerisation | Docker + Docker Compose | 3.8 schema |

### 2.3 Network Topology

All services communicate over a private Docker bridge network (`decp-network`).

| Service | Internal Port | External Port | Notes |
|---------|---------------|---------------|-------|
| `mysql-db` | 3306 | 3308 | MySQL |
| `mongodb` | 27017 | 27018 | MongoDB |
| `api-gateway` | 8080 | 8088 | Spring Cloud Gateway |
| `user-service` | 8081 | — | Internal only |
| `feed-service` | 8082 | — | Internal only |
| `career-service` | 8083 | — | Internal only |
| `web-client` | 80 | 80 | Nginx reverse proxy |

---

## 3. Prerequisites

Ensure the following are installed on the deployment machine:

| Software | Minimum Version | Check Command |
|----------|----------------|---------------|
| **Docker** | 24.0+ | `docker --version` |
| **Docker Compose** | 2.20+ (or v1 plugin) | `docker compose version` |
| **Git** | 2.30+ | `git --version` |
| **Java** (for local dev) | 21 | `java -version` |
| **Maven** (for local dev) | 3.9+ | `mvn --version` |
| **Node.js** (for local dev) | 18+ | `node --version` |

### Disk Space

| Component | Estimated Size |
|-----------|---------------|
| Docker images (all services) | ~2 GB |
| MySQL data volume | 500 MB (grows with data) |
| MongoDB data volume | 500 MB (grows with data) |
| Source code | ~200 MB |

---

## 4. Local Deployment with Docker Compose

### 4.1 Clone the Repository

```bash
git clone <repository-url> uop-decp-microservices
cd uop-decp-microservices
```

### 4.2 Build & Start All Services

```bash
# Build all images and start containers in detached mode
docker compose up --build -d
```

This command:
1. Builds Docker images for all 5 application services.
2. Pulls MySQL 8.0 and MongoDB latest images.
3. Creates the `decp-network` bridge network.
4. Creates persistent volumes for `mysql_data` and `mongodb_data`.
5. Starts all 7 containers in dependency order.

**Startup Order** (managed by `depends_on`):
```
mysql-db, mongodb
    ↓
user-service, feed-service, career-service
    ↓
api-gateway
    ↓
web-client
```

### 4.3 Verifying the Deployment

```bash
# Check all containers are running
docker compose ps

# Check logs for a specific service
docker compose logs -f api-gateway
docker compose logs -f user-service
docker compose logs -f feed-service
docker compose logs -f career-service
docker compose logs -f web-client
```

**Health Check URLs**:

| Service | URL | Expected |
|---------|-----|----------|
| Web Client | `http://localhost` | Login page loads |
| API Gateway | `http://localhost:8088` | Gateway responds |
| MySQL | `docker exec decp-mysql mysqladmin ping -u root -prootpassword` | `mysqld is alive` |
| MongoDB | `docker exec decp-mongodb mongosh --eval "db.stats()" -u root -p rootpassword --authenticationDatabase admin` | Database stats |

### 4.4 Stopping the Platform

```bash
# Stop all containers (preserves data volumes)
docker compose down

# Stop and remove volumes (DESTROYS DATA)
docker compose down -v
```

---

## 5. Service Configuration

### 5.1 Environment Variables

All environment variables are defined in `docker-compose.yml`:

#### MySQL

| Variable | Default | Description |
|----------|---------|-------------|
| `MYSQL_ROOT_PASSWORD` | `rootpassword` | Root password |
| `MYSQL_DATABASE` | `decp_users` | Initial database |
| `MYSQL_USER` | `decp_admin` | Application user |
| `MYSQL_PASSWORD` | `decp_password` | Application password |

#### User Service

| Variable | Default | Description |
|----------|---------|-------------|
| `SPRING_DATASOURCE_URL` | `jdbc:mysql://mysql-db:3306/decp_users?...` | JDBC connection string |

#### Feed Service

| Variable | Default | Description |
|----------|---------|-------------|
| `SPRING_DATA_MONGODB_URI` | `mongodb://root:rootpassword@mongodb:27017/decp_feed?authSource=admin` | MongoDB connection URI |

#### Career Service

| Variable | Default | Description |
|----------|---------|-------------|
| `SPRING_DATASOURCE_URL` | `jdbc:mysql://mysql-db:3306/decp_careers?createDatabaseIfNotExist=true&...` | JDBC connection string |

#### API Gateway

| Variable | Default | Description |
|----------|---------|-------------|
| `USER_SERVICE_URL` | `http://user-service:8081` | User service internal URL |
| `FEED_SERVICE_URL` | `http://feed-service:8082` | Feed service internal URL |
| `CAREER_SERVICE_URL` | `http://career-service:8083` | Career service internal URL |

### 5.2 Database Configuration

**MySQL** uses Spring Boot's auto-DDL with Hibernate (`spring.jpa.hibernate.ddl-auto`). In development, this is typically set to `update` to auto-create tables.

**MongoDB** auto-creates collections on first write. No schema setup is needed.

### 5.3 API Gateway Configuration

The API Gateway routes are defined in `application.yaml`:

```yaml
# Routing rules
/api/users/** → user-service:8081
/api/posts/** → feed-service:8082
/api/jobs/**  → career-service:8083
```

The Gateway also performs **JWT validation** and injects identity headers (`X-User-Id`, `X-User-Name`, `X-User-Role`) into downstream requests.

### 5.4 Nginx (Web Client) Configuration

The web client uses Nginx as a reverse proxy. Configuration is at `decp-platform/web-client/nginx.conf`:

- Serves static React build from `/usr/share/nginx/html`
- Proxies `/api/*` requests to `http://api-gateway:8080`
- All unmatched routes serve `index.html` (SPA fallback)

---

## 6. Database Administration

### 6.1 MySQL (User Service & Career Service)

**Connect to MySQL**:
```bash
# From host (port 3308 mapped)
mysql -h 127.0.0.1 -P 3308 -u root -prootpassword

# From inside the container
docker exec -it decp-mysql mysql -u root -prootpassword
```

**Key Databases**:

| Database | Service | Tables |
|----------|---------|--------|
| `decp_users` | user-service | `users` |
| `decp_careers` | career-service | `jobs`, `applications` |

**Useful Queries**:
```sql
-- List all users
USE decp_users;
SELECT id, name, email, role, status, created_at FROM users;

-- Count users by role
SELECT role, COUNT(*) FROM users GROUP BY role;

-- List all jobs
USE decp_careers;
SELECT id, title, company, type, posted_by, created_at FROM jobs;

-- List applications with applicant details
SELECT a.id, a.job_id, a.applicant_id, a.status, a.submitted_at 
FROM applications a ORDER BY a.submitted_at DESC;
```

> **Warning**: The `users` table contains `password_hash` — never expose this column in exports or logs.

### 6.2 MongoDB (Feed Service)

**Connect to MongoDB**:
```bash
# From host (port 27018 mapped)
mongosh "mongodb://root:rootpassword@127.0.0.1:27018/decp_feed?authSource=admin"

# From inside the container
docker exec -it decp-mongodb mongosh -u root -p rootpassword --authenticationDatabase admin
```

**Useful Commands**:
```javascript
use decp_feed

// Count all posts
db.posts.countDocuments()

// List recent posts
db.posts.find().sort({ createdAt: -1 }).limit(10)

// Find posts by a specific author
db.posts.find({ authorId: 1 })

// Count comments across all posts
db.posts.aggregate([
    { $project: { commentCount: { $size: "$comments" } } },
    { $group: { _id: null, total: { $sum: "$commentCount" } } }
])
```

### 6.3 Backup & Restore

#### MySQL Backup
```bash
# Full backup of both databases
docker exec decp-mysql mysqldump -u root -prootpassword --databases decp_users decp_careers > backup_mysql_$(date +%Y%m%d).sql

# Restore
docker exec -i decp-mysql mysql -u root -prootpassword < backup_mysql_20260309.sql
```

#### MongoDB Backup
```bash
# Dump the feed database
docker exec decp-mongodb mongodump -u root -p rootpassword --authenticationDatabase admin -d decp_feed --out /data/backup

# Copy backup to host
docker cp decp-mongodb:/data/backup ./backup_mongo_$(date +%Y%m%d)

# Restore
docker cp ./backup_mongo_20260309 decp-mongodb:/data/backup
docker exec decp-mongodb mongorestore -u root -p rootpassword --authenticationDatabase admin /data/backup
```

#### Automated Backup Schedule (Recommended)

```bash
# Add to crontab (daily at 2 AM)
0 2 * * * /path/to/backup-script.sh >> /var/log/decp-backup.log 2>&1
```

---

## 7. Security Configuration

### 7.1 JWT Secret Management

**Current State**: The JWT signing secret is **hardcoded** in two places:

| Service | File | Location |
|---------|------|----------|
| user-service | `application.yaml` | `jwt.secret` property |
| api-gateway | `JwtAuthFilter.java` | Inline constant |

**⚠️ CRITICAL for Production**: Move the JWT secret to an environment variable:

```yaml
# application.yaml
jwt:
  secret: ${JWT_SECRET}
```

```yaml
# docker-compose.yml
environment:
  - JWT_SECRET=your-strong-256-bit-secret-here
```

Generate a secure secret:
```bash
openssl rand -base64 64
```

**Both the user-service and api-gateway MUST use the same secret**.

### 7.2 CORS Configuration

CORS is configured in the API Gateway. Currently allows `http://localhost:5173` (Vite dev server).

**For production**, update to allow your actual domain:
```yaml
spring:
  cloud:
    gateway:
      globalcors:
        corsConfigurations:
          '[/**]':
            allowedOrigins: "https://your-domain.com"
```

### 7.3 Password Hashing

- User passwords are hashed using **BCrypt** with automatic salting.
- The `password_hash` column in the `users` table stores the hash.
- BCrypt rounds: default (10 rounds), suitable for production.

### 7.4 Hardening Checklist

| # | Item | Priority | Status |
|---|------|----------|--------|
| 1 | Externalise JWT secret to environment variable | 🔴 Critical | ⬜ |
| 2 | Change default MySQL root/admin passwords | 🔴 Critical | ⬜ |
| 3 | Change MongoDB root password | 🔴 Critical | ⬜ |
| 4 | Update CORS to allow only production domain | 🟡 High | ⬜ |
| 5 | Remove `/api/users/list` password hash exposure | 🟡 High | ⬜ |
| 6 | Disable Admin self-registration in production | 🟡 High | ⬜ |
| 7 | Enable HTTPS/TLS with real certificates | 🟡 High | ⬜ |
| 8 | Add rate limiting to the API Gateway | 🟢 Medium | ⬜ |
| 9 | Enable Spring Security configuration (currently permits all) | 🟡 High | ⬜ |
| 10 | Add request logging and audit trail | 🟢 Medium | ⬜ |

---

## 8. Cloud Deployment

### 8.1 Kubernetes (EKS / GKE)

For production, deploy to a managed Kubernetes cluster:

```bash
# Build and push images to container registry
docker build -t <registry>/user-service:v1.0 ./decp-platform/backend/user-service
docker build -t <registry>/feed-service:v1.0 ./decp-platform/backend/feed-service
docker build -t <registry>/career-service:v1.0 ./decp-platform/backend/career-service
docker build -t <registry>/api-gateway:v1.0 ./decp-platform/backend/api-gateway
docker build -t <registry>/web-client:v1.0 ./decp-platform/web-client

# Push all images
docker push <registry>/user-service:v1.0
docker push <registry>/feed-service:v1.0
docker push <registry>/career-service:v1.0
docker push <registry>/api-gateway:v1.0
docker push <registry>/web-client:v1.0
```

Each service should have its own Kubernetes Deployment + Service manifest. Use ConfigMaps for non-sensitive configuration and Secrets for database credentials and JWT secrets.

### 8.2 Managed Databases

| Database | Recommended Service |
|----------|-------------------|
| MySQL | Amazon RDS / Google Cloud SQL |
| MongoDB | MongoDB Atlas (cross-cloud) |

**Benefits**: Automated backups, point-in-time recovery, high availability, automatic patching.

### 8.3 Container Registry

| Provider | Registry |
|----------|----------|
| AWS | Amazon ECR |
| GCP | Google Artifact Registry |
| Alternative | Docker Hub (public/private) |

### 8.4 Ingress & TLS

For production, configure an Ingress Controller (e.g., Nginx Ingress or AWS ALB) with TLS:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: uniconnect-ingress
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
    - hosts:
        - uniconnect.example.com
      secretName: uniconnect-tls
  rules:
    - host: uniconnect.example.com
      http:
        paths:
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: api-gateway
                port:
                  number: 8080
          - path: /
            pathType: Prefix
            backend:
              service:
                name: web-client
                port:
                  number: 80
```

---

## 9. Monitoring & Logging

### Container Logs

```bash
# Real-time logs for a specific service
docker compose logs -f user-service

# Last 100 lines of all services
docker compose logs --tail=100

# Search for errors
docker compose logs | grep -i "error\|exception\|failed"
```

### Recommended Monitoring Stack

| Tool | Purpose |
|------|---------|
| **Prometheus** | Metrics collection (Spring Boot Actuator integration) |
| **Grafana** | Metrics visualisation and dashboards |
| **ELK Stack** | Centralised log aggregation (Elasticsearch + Logstash + Kibana) |
| **Docker stats** | Quick resource monitoring |

```bash
# Quick resource monitoring
docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
```

### Spring Boot Actuator (Future)

Add to each service's `pom.xml`:
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

Expose health and metrics endpoints:
```yaml
management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,prometheus
```

---

## 10. Scaling & Performance

### Horizontal Scaling (Docker Compose)

```bash
# Scale a specific service to 3 replicas
docker compose up -d --scale feed-service=3
```

> **Note**: When scaling backend services, ensure the API Gateway can load-balance across replicas. In Docker Compose, this works through DNS round-robin on the service name.

### Kubernetes Scaling

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: feed-service-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: feed-service
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
```

### Performance Considerations

| Area | Recommendation |
|------|---------------|
| **Database connections** | Configure connection pools (HikariCP for MySQL, built-in for MongoDB) |
| **Feed pagination** | Already implemented; ensure `page` + `size` are used |
| **Caching** | Consider Redis for frequently accessed data (user profiles, feed) |
| **Image/file uploads** | Use object storage (S3/GCS) instead of storing in database |
| **Static assets** | Nginx serves React build with proper Cache-Control headers |

---

## 11. Maintenance Procedures

### 11.1 Updating a Service

```bash
# Rebuild and restart a single service (zero-downtime with replicas)
docker compose build user-service
docker compose up -d --no-deps user-service

# Rebuild all services
docker compose up --build -d
```

### 11.2 Database Migrations

Currently, Hibernate auto-DDL creates/updates tables. For production:

1. Set `spring.jpa.hibernate.ddl-auto` to `validate` (not `update`).
2. Use a migration tool like **Flyway** or **Liquibase**.
3. Version your migration scripts in the repository.

### 11.3 Log Rotation

Docker log files can grow indefinitely. Configure log rotation in `/etc/docker/daemon.json`:

```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

Restart Docker after changing:
```bash
sudo systemctl restart docker
```

### 11.4 Health Checks

Add health checks to `docker-compose.yml` for automatic restart:

```yaml
user-service:
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:8081/actuator/health"]
    interval: 30s
    timeout: 10s
    retries: 3
    start_period: 60s
```

---

## 12. Troubleshooting

| Symptom | Likely Cause | Resolution |
|---------|-------------|------------|
| Container exits immediately | Missing env var or port conflict | `docker compose logs <service>` to see error |
| `Connection refused` on API | Gateway started before backend services | Restart: `docker compose restart api-gateway` |
| MySQL `Access denied` | Wrong password in env variable | Check `SPRING_DATASOURCE_URL` and MySQL passwords match |
| MongoDB auth failure | Wrong credentials or auth database | Ensure `?authSource=admin` in URI |
| Web client shows blank page | Nginx config error or build failure | Check `docker compose logs web-client` |
| CORS errors in browser | Frontend URL not in allowed origins | Update Gateway CORS configuration |
| JWT expired / invalid token | Secret mismatch between services | Ensure same JWT secret in user-service and api-gateway |
| Slow first request | JVM cold start (Spring Boot) | Normal; subsequent requests are faster |
| `decp_careers` database not found | MySQL only creates one initial DB | Career service uses `createDatabaseIfNotExist=true`; if missing, create manually |
| Port 80 already in use | Another web server (Apache/Nginx) running | Stop conflicting service or change web-client port mapping |

### Debugging a Single Service

```bash
# Check container status
docker inspect <container-name> --format='{{.State.Status}}'

# Enter a running container
docker exec -it <container-name> /bin/sh

# Check network connectivity between containers
docker exec api-gateway ping user-service

# View environment variables
docker exec <container-name> env
```

---

## 13. Disaster Recovery

### Recovery Priority Order

| Priority | Service | Rationale |
|----------|---------|-----------|
| 1 | MySQL | Contains user accounts and career data |
| 2 | MongoDB | Contains feed posts and comments |
| 3 | API Gateway | Stateless; rebuildable from source |
| 4 | All Backend Services | Stateless; rebuildable from source |
| 5 | Web Client | Stateless; rebuildable from source |

### Recovery Procedure

```bash
# 1. Restore databases from latest backup
cat backup_mysql_latest.sql | docker exec -i decp-mysql mysql -u root -prootpassword
docker cp ./backup_mongo_latest decp-mongodb:/data/backup
docker exec decp-mongodb mongorestore -u root -p rootpassword --authenticationDatabase admin /data/backup

# 2. Rebuild and restart all services
docker compose up --build -d

# 3. Verify
docker compose ps
curl -s http://localhost | head -5
```

### Data Recovery Points

| Component | Recovery Method | RPO (Recovery Point Objective) |
|-----------|----------------|-------------------------------|
| MySQL | SQL dump restore | Depends on backup frequency |
| MongoDB | mongodump restore | Depends on backup frequency |
| Application code | Git clone | Latest commit (near-zero RPO) |
| Docker images | Rebuild from Dockerfile | Minutes |

---

## 14. Reference

### Useful Commands Cheat Sheet

```bash
# === Docker Compose ===
docker compose up --build -d        # Build + start all
docker compose down                 # Stop all (keep data)
docker compose down -v              # Stop all + delete data
docker compose ps                   # List containers
docker compose logs -f <service>    # Follow logs
docker compose restart <service>    # Restart one service
docker compose exec <service> sh    # Shell into container

# === MySQL ===
docker exec -it decp-mysql mysql -u root -prootpassword
docker exec decp-mysql mysqldump -u root -prootpassword --all-databases > full_backup.sql

# === MongoDB ===
docker exec -it decp-mongodb mongosh -u root -p rootpassword --authenticationDatabase admin

# === Debugging ===
docker stats                        # Live resource usage
docker system df                    # Disk usage
docker system prune -a              # Clean unused images/containers (careful!)
```

### Service Ports Reference

| Service | Internal | External | Protocol |
|---------|----------|----------|----------|
| MySQL | 3306 | 3308 | TCP |
| MongoDB | 27017 | 27018 | TCP |
| API Gateway | 8080 | 8088 | HTTP |
| User Service | 8081 | — | HTTP |
| Feed Service | 8082 | — | HTTP |
| Career Service | 8083 | — | HTTP |
| Web Client | 80 | 80 | HTTP |

### File Structure Reference

```
uop-decp-microservices/
├── docker-compose.yml                    # Main orchestration file
├── decp-platform/
│   ├── backend/
│   │   ├── api-gateway/                  # Spring Cloud Gateway
│   │   │   ├── Dockerfile
│   │   │   ├── pom.xml
│   │   │   └── src/main/...
│   │   ├── user-service/                 # User management + auth
│   │   │   ├── Dockerfile
│   │   │   ├── pom.xml
│   │   │   └── src/main/...
│   │   ├── feed-service/                 # Social feed (MongoDB)
│   │   │   ├── Dockerfile
│   │   │   ├── pom.xml
│   │   │   └── src/main/...
│   │   └── career-service/               # Jobs + applications
│   │       ├── Dockerfile
│   │       ├── pom.xml
│   │       └── src/main/...
│   ├── infrastructure/
│   │   └── docker-compose.yml            # (Alternate infrastructure config)
│   └── web-client/                       # React frontend
│       ├── Dockerfile
│       ├── nginx.conf
│       ├── package.json
│       └── src/...
└── docs/                                 # All documentation
```

---

*Last updated: March 2026 · UniConnect DECP v1.0*
