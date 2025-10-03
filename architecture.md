# 🏗️ AWS Cost Tracker - Architecture Overview

## System Architecture

The AWS Cost Tracker is built using a **serverless, event-driven architecture** that provides real-time cost monitoring and management capabilities.

### High-Level Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   API Gateway   │    │   Lambda        │
│   (React SPA)   │◄──►│   (REST API)    │◄──►│   Functions     │
│   CloudFront    │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       ▼
         │                       │              ┌─────────────────┐
         │                       │              │   DynamoDB      │
         │                       │              │   (Cost Logs)   │
         │                       │              └─────────────────┘
         │                       │                       │
         │                       │                       ▼
         │                       │              ┌─────────────────┐
         │                       │              │   CloudWatch    │
         │                       │              │   (Billing)     │
         │                       │              └─────────────────┘
         │                       │                       │
         │                       │                       ▼
         │                       │              ┌─────────────────┐
         │                       │              │   SNS           │
         │                       │              │   (Alerts)      │
         │                       │              └─────────────────┘
         │                       │
         │                       ▼
         │              ┌─────────────────┐
         │              │   EventBridge   │
         │              │   (Scheduler)   │
         │              └─────────────────┘
         │
         ▼
┌─────────────────┐
│   S3 Bucket     │
│   (Static Host) │
└─────────────────┘
```

## Core Components

### 1. Frontend Layer
- **Technology**: React 18 with Tailwind CSS
- **Hosting**: S3 + CloudFront CDN
- **Features**: Responsive design, dark/light mode, real-time updates

### 2. API Gateway
- **Purpose**: RESTful API endpoint management
- **Endpoints**: 
  - `/dashboard-data` - Get cost and alert data
  - `/update-threshold` - Update billing threshold
  - `/stop-ec2` - Emergency stop EC2 instances

### 3. Lambda Functions

#### API Handler Lambda
- **Purpose**: Main backend for dashboard operations
- **Capabilities**:
  - Fetch real-time cost data from CloudWatch/Cost Explorer
  - Retrieve cost logs from DynamoDB
  - Update CloudWatch billing alarms
  - Control EC2 instances

#### Cost Logger Lambda
- **Purpose**: Automated cost monitoring and logging
- **Triggers**: EventBridge schedule (every 6 hours), SNS notifications
- **Capabilities**:
  - Fetch current AWS costs
  - Generate contextual log descriptions
  - Store data in DynamoDB
  - Send email alerts

### 4. Data Storage

#### DynamoDB Table
- **Name**: `cost-tracker-cost-logs`
- **Schema**:
  - `id`: Timestamp (Primary Key)
  - `message`: Event description
  - `description`: Detailed context
  - `region`: AWS region
  - `severity`: low/medium/high
  - `type`: Event type
  - `timestamp`: ISO datetime

#### S3 Bucket
- **Purpose**: Static website hosting
- **Contents**: React application files
- **Access**: Public read for web content

### 5. Monitoring & Alerts

#### CloudWatch
- **Billing Metrics**: Real-time cost tracking
- **Custom Alarms**: Threshold breach detection
- **Logs**: Lambda execution logs

#### SNS
- **Purpose**: Email alert distribution
- **Triggers**: CloudWatch alarm state changes

#### EventBridge
- **Purpose**: Scheduled cost monitoring
- **Schedule**: Every 6 hours (configurable)

## Data Flow

### 1. Real-Time Cost Monitoring
1. User opens dashboard
2. Frontend calls API Gateway
3. API Handler Lambda fetches data from CloudWatch/Cost Explorer
4. Data returned to frontend and displayed

### 2. Automated Cost Logging
1. EventBridge triggers every 6 hours
2. Cost Logger Lambda fetches current costs
3. Generates contextual descriptions
4. Stores log entry in DynamoDB
5. Sends email alert if threshold exceeded

### 3. Threshold Updates
1. User updates threshold in dashboard
2. Frontend sends POST request to API Gateway
3. API Handler Lambda updates CloudWatch alarm
4. Logs threshold update in DynamoDB

## Security

### IAM Roles
- **Lambda Execution Role**: Permissions for DynamoDB, CloudWatch, Cost Explorer, SNS, EC2
- **API Gateway Permissions**: Invoke Lambda functions

### Data Security
- **Encryption at Rest**: DynamoDB and S3 use AES-256
- **Encryption in Transit**: All API calls use TLS 1.2+
- **Access Control**: IAM-based permissions

## Scalability

### Auto-Scaling
- **Lambda**: Up to 1000 concurrent executions (3000 burst)
- **DynamoDB**: On-demand scaling (5-40,000 RCU/WCU)
- **API Gateway**: 10,000 requests/second per account

### Performance Optimizations
- **CloudFront CDN**: Global edge caching
- **Lambda Caching**: In-memory result caching
- **DynamoDB GSI**: Optimized query patterns

## Cost Optimization

### Resource Sizing
- **API Handler**: 256 MB memory, 30s timeout
- **Cost Logger**: 128 MB memory, 60s timeout
- **DynamoDB**: On-demand billing mode

### Monitoring
- **Real-time Costs**: CloudWatch billing metrics
- **Service Breakdown**: Cost by AWS service
- **Forecasting**: Next month predictions
- **Alerts**: Configurable spending thresholds

## Key Benefits

- ✅ **Zero Infrastructure Management**
- ✅ **Automatic Scaling**
- ✅ **Pay-per-Use Pricing**
- ✅ **High Availability**
- ✅ **Security by Default**
- ✅ **Real-time Monitoring**
- ✅ **Cost-Effective**
- ✅ **Event-Driven Architecture**