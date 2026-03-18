#!/bin/bash
export JWT_SECRET=your-very-secure-and-long-secret-key-for-decp-project
nohup java -jar backend/auth-service/target/*.jar > logs/auth.log 2>&1 &
nohup java -jar backend/user-service/target/*.jar > logs/user.log 2>&1 &
nohup java -jar backend/post-service/target/*.jar > logs/post.log 2>&1 &
nohup java -jar backend/job-service/target/*.jar > logs/job.log 2>&1 &
nohup java -jar backend/event-service/target/*.jar > logs/event.log 2>&1 &
nohup java -jar backend/research-service/target/*.jar > logs/research.log 2>&1 &
nohup java -jar backend/messaging-service/target/*.jar > logs/messaging.log 2>&1 &
nohup java -jar backend/notification-service/target/*.jar > logs/notification.log 2>&1 &
nohup java -jar backend/analytics-service/target/*.jar > logs/analytics.log 2>&1 &
nohup java -jar backend/mentorship-service/target/*.jar > logs/mentorship.log 2>&1 &
sleep 5
nohup java -jar backend/api-gateway/target/*.jar > logs/gateway.log 2>&1 &
cd frontend/web-client && nohup npm run dev > ../../logs/frontend.log 2>&1 &
