# Cloud Cost Tracker & Alert System - Architecture

## System Architecture Diagram

```mermaid
graph TB
    subgraph "AWS Cloud"
        subgraph "Data Storage"
            DDB[(DynamoDB<br/>Cost Logs Table)]
        end
        
        subgraph "Compute"
            L1[Lambda: Cost Logger<br/>Scheduled Function]
            L2[Lambda: API Handler<br/>REST API Function]
        end
        
        subgraph "Monitoring & Alerts"
            CW[CloudWatch<br/>Billing Alarm]
            SNS[SNS Topic<br/>Email Notifications]
        end
        
        subgraph "Scheduling"
            EB[EventBridge Rule<br/>6-hour Schedule]
        end
        
        subgraph "API Layer"
            APIGW[API Gateway<br/>REST Endpoint]
        end
        
        subgraph "Frontend"
            S3[S3 Bucket<br/>Static Website]
            CF[CloudFront<br/>CDN Distribution]
        end
        
        subgraph "AWS Services"
            CE[Cost Explorer API]
            BILLING[AWS Billing Metrics]
        end
    end
    
    subgraph "External"
        USER[User/Admin]
        EMAIL[Email Recipient]
    end
    
    %% Data Flow
    EB -->|Triggers| L1
    L1 -->|Fetches Cost Data| CE
    L1 -->|Stores Logs| DDB
    BILLING -->|Monitors| CW
    CW -->|Threshold Exceeded| SNS
    SNS -->|Sends Alert| EMAIL
    
    %% API Flow
    USER -->|Access Dashboard| CF
    CF -->|Serves Static Files| S3
    S3 -->|JavaScript API Calls| APIGW
    APIGW -->|Invokes| L2
    L2 -->|Queries Data| DDB
    L2 -->|Returns JSON| APIGW
    APIGW -->|API Response| S3
    S3 -->|Renders Dashboard| CF
    CF -->|Displays Data| USER
    
    %% Styling
    classDef aws fill:#ff9900,stroke:#232f3e,stroke-width:2px,color:#fff
    classDef compute fill:#ff6b6b,stroke:#c92a2a,stroke-width:2px,color:#fff
    classDef storage fill:#4ecdc4,stroke:#26a69a,stroke-width:2px,color:#fff
    classDef external fill:#95a5a6,stroke:#7f8c8d,stroke-width:2px,color:#fff
    
    class DDB,S3 storage
    class L1,L2,APIGW compute
    class CW,SNS,EB,CF,CE,BILLING aws
    class USER,EMAIL external
```

## Component Descriptions

### Core Components

1. **DynamoDB Table** (`cost_logs`)
   - Stores cost and usage logs with timestamp as primary key
   - Pay-per-request billing mode for cost efficiency
   - Contains monthly cost data, service breakdowns, and metadata

2. **Lambda Functions**
   - **Cost Logger**: Scheduled function that fetches cost data from Cost Explorer API and stores it in DynamoDB
   - **API Handler**: Handles REST API requests to retrieve cost data from DynamoDB

3. **EventBridge Rule**
   - Triggers the cost logger Lambda function on a schedule (default: every 6 hours)
   - Configurable via Terraform variables

4. **CloudWatch Alarm**
   - Monitors AWS billing metrics for cost threshold breaches
   - Triggers SNS notifications when threshold is exceeded

5. **SNS Topic & Subscription**
   - Sends email notifications when cost thresholds are exceeded
   - Configurable email endpoint

### API Layer

6. **API Gateway**
   - Provides RESTful API endpoint for cost data access
   - Handles CORS for web dashboard integration
   - Integrates with Lambda API handler

### Frontend

7. **S3 Bucket**
   - Hosts static HTML dashboard files
   - Configured for website hosting with public read access

8. **CloudFront Distribution**
   - CDN for fast global access to the dashboard
   - Handles HTTPS and custom error pages for SPA routing

## Data Flow

### Cost Logging Flow
1. EventBridge triggers cost logger Lambda every 6 hours
2. Lambda calls AWS Cost Explorer API to fetch current month's cost data
3. Cost data is processed and stored in DynamoDB with timestamp
4. CloudWatch monitors billing metrics continuously
5. When threshold exceeded, SNS sends email alert

### Dashboard Access Flow
1. User accesses CloudFront URL
2. CloudFront serves static HTML from S3
3. JavaScript in HTML makes API calls to API Gateway
4. API Gateway invokes Lambda API handler
5. Lambda queries DynamoDB for cost logs
6. Data is returned and displayed in interactive dashboard

## Security Considerations

- IAM roles with least privilege access
- S3 bucket policies for public read access to static content only
- API Gateway with no authentication (can be enhanced with API keys or Cognito)
- Lambda functions have minimal required permissions
- CloudWatch alarms for monitoring and alerting

## Scalability Features

- DynamoDB auto-scaling with pay-per-request billing
- Lambda functions scale automatically
- CloudFront CDN for global distribution
- S3 static hosting for high availability
- EventBridge for reliable scheduling

## Cost Optimization

- DynamoDB on-demand billing
- Lambda functions with appropriate timeouts
- CloudFront caching to reduce origin requests
- S3 standard storage class
- EventBridge free tier usage
