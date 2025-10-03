# 🔌 AWS Cost Tracker - API Documentation

## 🌐 Overview

The AWS Cost Tracker API provides RESTful endpoints for cost monitoring, threshold management, and emergency controls. All endpoints return JSON responses and support CORS for web applications.

## 🔐 Authentication

The API uses **IAM-based authentication** through AWS API Gateway. No API keys are required as the Lambda functions run with appropriate IAM roles.

### Required Permissions
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "execute-api:Invoke"
      ],
      "Resource": "arn:aws:execute-api:us-east-1:123456789012:vf8wpnzzgf/dev/*"
    }
  ]
}
```

## 🌍 Base URL

```
https://vf8wpnzzgf.execute-api.us-east-1.amazonaws.com/dev
```

## 📡 Endpoints

### 1. Get Dashboard Data

**Endpoint**: `GET /dashboard-data`

**Description**: Retrieves current cost data, forecasts, and recent logs for the dashboard.

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `region` | string | No | AWS region (default: us-east-1) |

#### Request Example

```bash
curl -X GET "https://vf8wpnzzgf.execute-api.us-east-1.amazonaws.com/dev/dashboard-data?region=us-east-1"
```

#### Response Example

```json
{
  "realCostData": {
    "currentSpend": 1.07,
    "forecastedBill": 1.28,
    "highestCostService": {
      "name": "AWS Lambda",
      "cost": 0.45
    },
    "serviceBreakdown": [
      {
        "name": "AWS Lambda",
        "cost": 0.45
      },
      {
        "name": "Amazon S3",
        "cost": 0.32
      },
      {
        "name": "Amazon CloudWatch",
        "cost": 0.30
      }
    ],
    "lastUpdated": "2025-10-02T12:52:51.933016",
    "dataSource": "CloudWatch Billing"
  },
  "region": "us-east-1",
  "dataSource": "AWS Cost Explorer"
}
```

#### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `realCostData.currentSpend` | number | Current month's AWS spending |
| `realCostData.forecastedBill` | number | Predicted next month's bill |
| `realCostData.highestCostService` | object | Most expensive AWS service |
| `realCostData.serviceBreakdown` | array | Cost breakdown by service |
| `realCostData.lastUpdated` | string | ISO timestamp of last update |
| `realCostData.dataSource` | string | Data source (CloudWatch/Cost Explorer) |
| `region` | string | AWS region |
| `dataSource` | string | Overall data source |

### 2. Update Threshold

**Endpoint**: `POST /update-threshold`

**Description**: Updates the billing alarm threshold and logs the change.

#### Request Body

```json
{
  "threshold": 50.00,
  "region": "us-east-1"
}
```

#### Request Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `threshold` | number | Yes | New threshold amount in USD |
| `region` | string | No | AWS region (default: us-east-1) |

#### Request Example

```bash
curl -X POST "https://vf8wpnzzgf.execute-api.us-east-1.amazonaws.com/dev/update-threshold" \
  -H "Content-Type: application/json" \
  -d '{
    "threshold": 50.00,
    "region": "us-east-1"
  }'
```

#### Response Example

```json
{
  "message": "Threshold updated to $50.00",
  "threshold": 50.00,
  "region": "us-east-1"
}
```

#### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `message` | string | Success message |
| `threshold` | number | Updated threshold amount |
| `region` | string | AWS region |

### 3. Emergency Stop EC2

**Endpoint**: `POST /stop-ec2`

**Description**: Emergency stop all running EC2 instances in the specified region.

#### Request Body

```json
{
  "region": "us-east-1"
}
```

#### Request Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `region` | string | No | AWS region (default: us-east-1) |

#### Request Example

```bash
curl -X POST "https://vf8wpnzzgf.execute-api.us-east-1.amazonaws.com/dev/stop-ec2" \
  -H "Content-Type: application/json" \
  -d '{
    "region": "us-east-1"
  }'
```

#### Response Example

```json
{
  "message": "Emergency stop initiated",
  "stoppedInstances": [
    "i-1234567890abcdef0",
    "i-0987654321fedcba0"
  ],
  "region": "us-east-1"
}
```

#### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `message` | string | Success message |
| `stoppedInstances` | array | List of stopped instance IDs |
| `region` | string | AWS region |

### 4. Get Cost Logs

**Endpoint**: `GET /cost-logs`

**Description**: Retrieves recent cost monitoring logs from DynamoDB.

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `region` | string | No | AWS region (default: us-east-1) |
| `limit` | number | No | Number of logs to return (default: 50) |
| `type` | string | No | Filter by log type |

#### Request Example

```bash
curl -X GET "https://vf8wpnzzgf.execute-api.us-east-1.amazonaws.com/dev/cost-logs?region=us-east-1&limit=10"
```

#### Response Example

```json
{
  "logs": [
    {
      "id": "2025-10-02T12:52:51.933016",
      "message": "Daily cost review: Current spend $1.07 in us-east-1",
      "description": "Daily cost analysis completed for us-east-1. The system reviewed current spending patterns and service usage to provide accurate cost tracking.",
      "region": "us-east-1",
      "severity": "low",
      "type": "scheduled_check",
      "timestamp": "2025-10-02T12:52:51.933016",
      "current_cost": 1.07,
      "highest_cost_service": "AWS Lambda"
    }
  ],
  "region": "us-east-1",
  "totalCount": 1
}
```

#### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `logs` | array | Array of log entries |
| `logs[].id` | string | Unique log identifier |
| `logs[].message` | string | Log message |
| `logs[].description` | string | Detailed description |
| `logs[].region` | string | AWS region |
| `logs[].severity` | string | Log severity (low/medium/high) |
| `logs[].type` | string | Log type |
| `logs[].timestamp` | string | ISO timestamp |
| `logs[].current_cost` | number | Cost at time of log |
| `logs[].highest_cost_service` | string | Highest cost service |
| `region` | string | Filtered region |
| `totalCount` | number | Total number of logs |

## ❌ Error Handling

### HTTP Status Codes

| Code | Description |
|------|-------------|
| 200 | Success |
| 400 | Bad Request |
| 403 | Forbidden |
| 404 | Not Found |
| 500 | Internal Server Error |

### Error Response Format

```json
{
  "error": "Error message",
  "details": "Detailed error information",
  "timestamp": "2025-10-02T12:52:51.933016"
}
```

### Common Error Scenarios

#### 1. Invalid Threshold Value

**Request**:
```json
{
  "threshold": "invalid",
  "region": "us-east-1"
}
```

**Response** (400):
```json
{
  "error": "Invalid threshold value",
  "details": "Threshold must be a valid number",
  "timestamp": "2025-10-02T12:52:51.933016"
}
```

#### 2. AWS Service Unavailable

**Response** (500):
```json
{
  "error": "Failed to get cost data",
  "details": "CloudWatch service temporarily unavailable",
  "timestamp": "2025-10-02T12:52:51.933016"
}
```

#### 3. Insufficient Permissions

**Response** (403):
```json
{
  "error": "Access denied",
  "details": "Insufficient permissions to access this resource",
  "timestamp": "2025-10-02T12:52:51.933016"
}
```

## 🚦 Rate Limiting

### API Gateway Limits

- **Default Rate**: 10,000 requests per second per account
- **Burst Limit**: 5,000 requests per second
- **Per-Client Rate**: 10,000 requests per second

### Lambda Limits

- **Concurrent Executions**: 1,000 (default)
- **Burst Capacity**: 3,000 concurrent executions
- **Memory**: 256 MB (API Handler), 128 MB (Cost Logger)
- **Timeout**: 30 seconds (API Handler), 60 seconds (Cost Logger)

## 📝 Examples

### Complete Dashboard Integration

```javascript
// Fetch dashboard data
async function loadDashboardData() {
  try {
    const response = await fetch('https://vf8wpnzzgf.execute-api.us-east-1.amazonaws.com/dev/dashboard-data?region=us-east-1');
    const data = await response.json();
    
    // Update UI with cost data
    updateKPICards(data.realCostData);
    updateCostLogs(data.logs);
    
  } catch (error) {
    console.error('Failed to load dashboard data:', error);
  }
}

// Update threshold
async function updateThreshold(newThreshold) {
  try {
    const response = await fetch('https://vf8wpnzzgf.execute-api.us-east-1.amazonaws.com/dev/update-threshold', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        threshold: newThreshold,
        region: 'us-east-1'
      })
    });
    
    const result = await response.json();
    console.log('Threshold updated:', result.message);
    
  } catch (error) {
    console.error('Failed to update threshold:', error);
  }
}

// Emergency stop EC2 instances
async function emergencyStop() {
  if (confirm('Are you sure you want to stop all EC2 instances?')) {
    try {
      const response = await fetch('https://vf8wpnzzgf.execute-api.us-east-1.amazonaws.com/dev/stop-ec2', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          region: 'us-east-1'
        })
      });
      
      const result = await response.json();
      console.log('Emergency stop completed:', result.stoppedInstances);
      
    } catch (error) {
      console.error('Failed to stop instances:', error);
    }
  }
}
```

### Python Integration

```python
import requests
import json

class CostTrackerAPI:
    def __init__(self, base_url):
        self.base_url = base_url
    
    def get_dashboard_data(self, region='us-east-1'):
        """Get dashboard data"""
        response = requests.get(f"{self.base_url}/dashboard-data?region={region}")
        return response.json()
    
    def update_threshold(self, threshold, region='us-east-1'):
        """Update billing threshold"""
        data = {
            'threshold': threshold,
            'region': region
        }
        response = requests.post(f"{self.base_url}/update-threshold", json=data)
        return response.json()
    
    def emergency_stop(self, region='us-east-1'):
        """Emergency stop EC2 instances"""
        data = {'region': region}
        response = requests.post(f"{self.base_url}/stop-ec2", json=data)
        return response.json()

# Usage
api = CostTrackerAPI('https://vf8wpnzzgf.execute-api.us-east-1.amazonaws.com/dev')

# Get dashboard data
dashboard_data = api.get_dashboard_data()
print(f"Current spend: ${dashboard_data['realCostData']['currentSpend']}")

# Update threshold
result = api.update_threshold(100.00)
print(result['message'])

# Emergency stop
result = api.emergency_stop()
print(f"Stopped instances: {result['stoppedInstances']}")
```

### cURL Examples

```bash
# Get dashboard data
curl -X GET "https://vf8wpnzzgf.execute-api.us-east-1.amazonaws.com/dev/dashboard-data?region=us-east-1"

# Update threshold to $100
curl -X POST "https://vf8wpnzzgf.execute-api.us-east-1.amazonaws.com/dev/update-threshold" \
  -H "Content-Type: application/json" \
  -d '{"threshold": 100.00, "region": "us-east-1"}'

# Emergency stop EC2 instances
curl -X POST "https://vf8wpnzzgf.execute-api.us-east-1.amazonaws.com/dev/stop-ec2" \
  -H "Content-Type: application/json" \
  -d '{"region": "us-east-1"}'

# Get recent cost logs
curl -X GET "https://vf8wpnzzgf.execute-api.us-east-1.amazonaws.com/dev/cost-logs?region=us-east-1&limit=10"
```

## 🔧 Testing

### Postman Collection

```json
{
  "info": {
    "name": "AWS Cost Tracker API",
    "description": "API collection for AWS Cost Tracker"
  },
  "item": [
    {
      "name": "Get Dashboard Data",
      "request": {
        "method": "GET",
        "url": "https://vf8wpnzzgf.execute-api.us-east-1.amazonaws.com/dev/dashboard-data?region=us-east-1"
      }
    },
    {
      "name": "Update Threshold",
      "request": {
        "method": "POST",
        "url": "https://vf8wpnzzgf.execute-api.us-east-1.amazonaws.com/dev/update-threshold",
        "header": [
          {
            "key": "Content-Type",
            "value": "application/json"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"threshold\": 50.00,\n  \"region\": \"us-east-1\"\n}"
        }
      }
    }
  ]
}
```

### Unit Tests

```python
import unittest
import requests

class TestCostTrackerAPI(unittest.TestCase):
    def setUp(self):
        self.base_url = 'https://vf8wpnzzgf.execute-api.us-east-1.amazonaws.com/dev'
    
    def test_get_dashboard_data(self):
        response = requests.get(f"{self.base_url}/dashboard-data")
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn('realCostData', data)
    
    def test_update_threshold(self):
        data = {'threshold': 25.00, 'region': 'us-east-1'}
        response = requests.post(f"{self.base_url}/update-threshold", json=data)
        self.assertEqual(response.status_code, 200)
        result = response.json()
        self.assertEqual(result['threshold'], 25.00)

if __name__ == '__main__':
    unittest.main()
```

---

## 📞 Support

For API issues or questions:

1. **Check the error response** for detailed information
2. **Review CloudWatch logs** for Lambda execution details
3. **Verify AWS permissions** and service limits
4. **Test with cURL** to isolate frontend issues
5. **Contact support** with specific error details

**API Version**: 1.0  
**Last Updated**: October 2, 2025

