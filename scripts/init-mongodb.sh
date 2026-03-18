#!/bin/bash
# MongoDB Database Initialization Script
# This script creates the required databases for Messaging and Notification services

echo "Creating MongoDB databases for DECP Microservices..."

MONGO_USER="${MONGO_ROOT_USERNAME:-admin}"
MONGO_PASS="${MONGO_ROOT_PASSWORD:-change_me}"

# Create decp_messaging database
docker exec decp-mongodb sh -c "mongosh \"mongodb://${MONGO_USER}:${MONGO_PASS}@localhost:27017/?authSource=admin\" --eval \"
db = db.getSiblingDB(\"decp_messaging\");
db.conversations.insert({_id: \"init\", createdAt: new Date()});
print(\"✅ Created decp_messaging database\");
\""

# Create decp_notifications database  
docker exec decp-mongodb sh -c "mongosh \"mongodb://${MONGO_USER}:${MONGO_PASS}@localhost:27017/?authSource=admin\" --eval \"
db = db.getSiblingDB(\"decp_notifications\");
db.notifications.insert({_id: \"init\", createdAt: new Date()});
print(\"✅ Created decp_notifications database\");
\""

echo "MongoDB databases initialized successfully!"
