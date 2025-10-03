🔗 Resource Connection Map
1. User Interface Layer
Web Browser ↔ CloudFront
  *Connection Type: HTTPS (TLS 1.2+)
  *Purpose: Global content delivery and caching
  *Data Flow:
    Static assets (HTML, CSS, JS) served from CloudFront edge locations
    API calls routed through CloudFront to API Gateway
  *Port: 443 (HTTPS)

CloudFront ↔ S3 Bucket
  *Connection Type: AWS Internal (HTTPS)
  *Purpose: Origin for static website hosting
  *Data Flow: CloudFront fetches React app files from S3
  *Configuration: Origin Access Identity (OAI) for secure access

CloudFront ↔ API Gateway
  *Connection Type: AWS Internal (HTTPS)
  *Purpose: API request routing
  *Data Flow: User API calls → CloudFront → API Gateway
  *Caching: API responses cached at edge locations

2. API Layer
  *API Gateway ↔ Lambda Functions
  *Connection Type: AWS Lambda Invoke
  *Purpose: Serverless compute execution
  *Data Flow:
      -REST API calls trigger Lambda functions
      -Lambda returns JSON responses
  *Permissions: IAM role allows API Gateway to invoke Lambda

API Gateway Endpoints:
  GET  /dashboard-data  → API Handler Lambda
  POST /update-threshold → API Handler Lambda  
  POST /stop-ec2        → API Handler Lambda


3. Compute Layer
API Handler Lambda ↔ DynamoDB
  *Connection Type: AWS SDK (HTTPS)
  *Purpose: Cost log storage and retrieval
  *Data Flow:
      -Read: Fetch cost logs for dashboard display
      -Write: Store threshold updates and emergency actions
  *Permissions: DynamoDB read/write access via IAM role

API Handler Lambda ↔ CloudWatch
  *Connection Type: AWS SDK (HTTPS)
  *Purpose: Real-time cost data and alarm management
  *Data Flow:
    -Read: Fetch billing metrics and cost data
    -Write: Update billing alarm thresholds
  *Permissions: CloudWatch read/write access via IAM role

API Handler Lambda ↔ EC2
  *Connection Type: AWS SDK (HTTPS)
  *Purpose: Emergency instance control
  *Data Flow:
    -Read: Describe running instances
    -Write: Stop and terminate instances
  *Permissions: EC2 describe, stop, terminate access via IAM role

Cost Logger Lambda ↔ DynamoDB
  *Connection Type: AWS SDK (HTTPS)
  *Purpose: Automated cost logging
  *Data Flow:
    -Write: Store cost log entries every 6 hours
    -Read: Query recent logs for context
  *Permissions: DynamoDB write access via IAM role

Cost Logger Lambda ↔ CloudWatch
  *Connection Type: AWS SDK (HTTPS)
  *Purpose: Fetch current cost data
  *Data Flow:
    -Read: Get billing metrics and cost explorer data
  *Permissions: CloudWatch read access via IAM role

4. Data Storage Layer
DynamoDB Table Structure
  *Table Name: cost-tracker-cost-logs
  *Primary Key: id (timestamp)
  *Attributes: message, description, region, severity, type, timestamp
  *Access Pattern: Query by timestamp range

S3 Bucket Structure
 *Bucket Name: cost-tracker-dashboard-8exmz3u1
  *Contents: React app files (HTML, CSS, JS)
  *Access: Public read for web content
  *Versioning: Enabled for rollback capability

5. Monitoring & Alerting Layer
EventBridge ↔ Cost Logger Lambda
  *Connection Type: AWS EventBridge Invoke
  *Purpose: Scheduled cost monitoring
  *Schedule: Every 6 hours (configurable)
  *Data Flow: EventBridge triggers Lambda execution
  *Permissions: EventBridge invoke permission

CloudWatch ↔ SNS
  *Connection Type: AWS CloudWatch Alarms
  *Purpose: Threshold breach notifications
  *Data Flow: Alarm state change → SNS notification
  *Configuration: CloudWatch alarm actions

SNS ↔ Email
  *Connection Type: SMTP (TLS)
  *Purpose: Email alert delivery
  *Data Flow: SNS → Email service → User inbox
  *Port: 587 (SMTP with TLS)

6. External AWS Services
Cost Explorer API
  *Connection Type: AWS SDK (HTTPS)
  *Purpose: Historical cost data and forecasting
  *Data Flow: Lambda functions query Cost Explorer API
  *Permissions: Cost Explorer read access

AWS CLI (Fallback)
  *Connection Type: AWS CLI commands
  *Purpose: Alternative cost data source
  *Data Flow: Lambda executes CLI commands via subprocess
  *Use Case: When Cost Explorer API fails