🔗 HOW IT WORKS
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


🔄 Complete Data Flow
On the Dashboard:
The User Https in the server via CloudFront and retrieves the static dashboard files stored in S3 which enabables the user to interact with the application. After gaining access to the app, the user trigger an API  call via the API Gateway which then invoke a lambda function via the api handler to get cost data via the Cloudwatch and Gets the log data stored in the database(DynamoDB). The API Handler(Lambda) sends response(JSON) back to API Gateway, which returns it to the user via CloudFront.

for the cost Logging
EventBridge( a scheduler) invokes the cost logger function to get the current costs stored in the database whereby if threshold exceeded, the cost logger  sends an alert(SNS) using the Email service to the user notifying the user of the cost

For the Emergency Stop function, the user https into the browser and sends a post request via the API gateway to stop or terminate  an instance. The API Handler queries it and invoke a lambda function which dppescribe the EC2 instance and a function to stop the instance. the log action is stored in the database by the Lambda function, then Lambda sends response to API Gateway on the app telling the user that the instance is stopped or terminated successfully.


🔐 Security Connections
IAM Role Permissions
Lambda Execution Role: DynamoDB, CloudWatch, EC2, SNS, Cost Explorer
API Gateway Role: Lambda invoke permissions
CloudFront: S3 and API Gateway access

Network Security
VPC: All resources in default VPC
Security Groups: Default security groups
NACLs: Default network ACLs
Encryption: TLS 1.2+ for all external connections

Data Encryption
At Rest: DynamoDB and S3 use AES-256
In Transit: All connections use TLS
Keys: AWS managed keys (KMS)

STEPS I TOOk
I developed a comprehensive AWS Cost Tracker system using a serverless architecture to provide real-time cost monitoring, automated logging, and emergency instance management capabilities. The project involved building both backend infrastructure using Terraform and frontend dashboard using React, with seamless integration between AWS services.


🛠️ Development Steps Taken
Phase 1: Infrastructure Setup with Terraform
I began by designing the core infrastructure using Terraform as Infrastructure as Code. This involved creating multiple .tf files to define AWS resources including Lambda functions, API Gateway, DynamoDB, S3, CloudFront, and supporting services like SNS and EventBridge. The Terraform configuration was structured to be modular and reusable, with variables defined for different environments.
The initial challenge was understanding the proper resource dependencies and ensuring that IAM roles and policies were correctly configured before creating the resources that would use them. I learned to use depends_on attributes strategically and to structure the configuration in a logical order.

Phase 2: Lambda Function Development
I developed two Python Lambda functions using the Boto3 AWS SDK. The API Handler function served as the main backend, handling dashboard data requests, threshold updates, and emergency EC2 operations. The Cost Logger function was designed for automated cost monitoring and logging.
The most complex part was implementing robust cost data fetching from AWS Cost Explorer and CloudWatch. I discovered that AWS Cost Explorer data can have significant delays (up to 24 hours), so I implemented multiple fallback strategies including different end dates, daily granularity queries, and CloudWatch billing metrics as alternatives.

Phase 3: Frontend Dashboard Development
I built a React-based dashboard with Tailwind CSS for styling, implementing features like real-time cost display, service breakdown, emergency controls, and responsive design. The dashboard communicates with the backend through API Gateway endpoints.
The frontend development involved creating a clean, modern interface that clearly communicates cost information to users, including proper handling of loading states, error conditions, and user feedback for all operations.
Phase 4: API Gateway Configuration
I configured API Gateway to create RESTful endpoints for the dashboard functionality. This involved setting up proper CORS policies, defining resource methods, and integrating with Lambda functions. I learned the importance of proper API Gateway deployment and stage management, which initially caused routing issues that required troubleshooting.
Phase 5: Data Storage and Monitoring
I implemented DynamoDB for storing cost logs and CloudWatch for monitoring and alerting. The system includes automated cost logging every 6 hours via EventBridge, with SNS integration for email alerts when cost thresholds are exceeded.
Phase 6: Testing and Troubleshooting
Throughout development, I encountered various challenges including network connectivity issues, API Gateway routing problems, and cost data accuracy issues. I systematically debugged each problem, often by testing individual components and using AWS CLI commands to verify functionality.


🎓 Key Lessons Learned
Terraform Lessons
Resource Dependencies Matter: I learned that Terraform resource creation order is crucial. Resources must be created in the correct sequence, with dependencies properly defined. For example, IAM roles must exist before Lambda functions that use them, and API Gateway deployments require all integrations to be complete.
State Management is Critical: Understanding Terraform state became essential when making changes to existing infrastructure. I learned to use terraform import for resources that were created outside of Terraform and to be careful with state file modifications.
Variable and Output Design: Creating meaningful variables and outputs made the infrastructure more maintainable and reusable. I learned to think about what values might change between environments and what information other developers or users would need to know after deployment.
Lifecycle Management: I discovered the importance of lifecycle rules, especially create_before_destroy for resources like API Gateway deployments that can cause service interruptions during updates.


AWS Lessons
Service Integration Complexity: AWS services are powerful but require careful configuration to work together properly. I learned that each service has its own specific requirements for permissions, networking, and data formats.
Cost Data Challenges: AWS Cost Explorer data is not real-time and can have significant delays. I learned to implement multiple data sources and fallback strategies to provide the most accurate information possible to users.
IAM Permissions are Granular: Understanding AWS IAM was crucial for security and functionality. I learned that each service needs specific permissions, and it's better to start with minimal permissions and add more as needed rather than using overly broad policies.
API Gateway Nuances: API Gateway has specific requirements for deployments and stages. I learned that simply creating a REST API isn't enough - proper deployment and stage configuration is essential for the API to be accessible.
Lambda Cold Starts: I discovered that Lambda functions can have cold start delays, especially with larger packages. This influenced my decisions about function sizing and timeout configurations.

This project taught me that building production-ready cloud applications requires deep understanding of both the technical infrastructure and the business requirements. The integration between different AWS services, while powerful, requires careful planning and testing. User experience considerations, especially around data accuracy and system reliability, are just as important as technical implementation.
The most valuable lesson was learning to think systematically about problems - breaking down complex issues into smaller, testable components, and implementing robust error handling and user feedback mechanisms throughout the system.