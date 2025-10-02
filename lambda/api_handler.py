import boto3
import json
import os
from datetime import datetime, timedelta
from decimal import Decimal

# AWS clients
dynamodb = boto3.resource("dynamodb")
cloudwatch = boto3.client("cloudwatch")
ec2 = boto3.client("ec2")
ce = boto3.client("ce")

table_name = os.environ.get("DDB_TABLE", "CostTrackerLogs")
table = dynamodb.Table(table_name)

class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)

def lambda_handler(event, context):
    try:
        # Parse the request
        http_method = event.get("httpMethod", "GET")
        path = event.get("path", "/")
        query_params = event.get("queryStringParameters") or {}
        
        # CORS headers
        headers = {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
            "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS"
        }
        
        # Handle OPTIONS request for CORS
        if http_method == "OPTIONS":
            return {
                "statusCode": 200,
                "headers": headers,
                "body": json.dumps({"message": "CORS preflight"})
            }
        
        # Route requests based on path
        if path == "/" or path == "/cost-data":
            return get_cost_logs(headers, query_params)
        elif path == "/dashboard-data":
            return get_dashboard_data(headers, query_params)
        elif path == "/update-threshold" and http_method == "POST":
            return update_threshold(event, headers)
        elif path == "/stop-ec2" and http_method == "POST":
            return stop_ec2_instances(event, headers)
        else:
            return {
                "statusCode": 404,
                "headers": headers,
                "body": json.dumps({"error": "Endpoint not found"})
            }
            
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            "statusCode": 500,
            "headers": headers,
            "body": json.dumps({"error": "Internal server error", "details": str(e)})
        }

def get_cost_logs(headers, query_params):
    """Get cost logs from DynamoDB"""
    try:
        limit = int(query_params.get("limit", 10))
        region = query_params.get("region", "us-east-1")
        
        # Scan table for recent logs
        response = table.scan(
            Limit=limit
        )
        
        items = response.get("Items", [])
        
        # Filter by region if specified (handle both old and new data formats)
        if region != "all":
            filtered_items = []
            for item in items:
                item_region = item.get("region", "us-east-1")  # Default to us-east-1 for old data
                if item_region == region:
                    filtered_items.append(item)
            items = filtered_items
        
        # Sort by timestamp (most recent first)
        items.sort(key=lambda x: x.get("id", ""), reverse=True)
        
        # Ensure all items have required fields for frontend compatibility
        formatted_items = []
        for item in items:
            # Clean up message if it's raw JSON
            message = item.get("message", "Cost alert")
            if message.startswith('{"version"'):
                message = "Automated cost monitoring check completed"
            
            formatted_item = {
                "id": item.get("id", ""),
                "message": message,
                "region": item.get("region", "us-east-1"),
                "severity": item.get("severity", "medium"),
                "timestamp": item.get("timestamp", item.get("id", ""))
            }
            formatted_items.append(formatted_item)
        
        return {
            "statusCode": 200,
            "headers": headers,
            "body": json.dumps(formatted_items, cls=DecimalEncoder)
        }
        
    except Exception as e:
        print(f"Error getting cost logs: {str(e)}")
        return {
            "statusCode": 500,
            "headers": headers,
            "body": json.dumps({"error": "Failed to get cost logs"})
        }

def get_dashboard_data(headers, query_params):
    """Get comprehensive dashboard data with real AWS Cost Explorer data"""
    try:
        region = query_params.get("region", "us-east-1")
        
        # Get current month's cost data from AWS Cost Explorer
        real_cost_data = get_real_cost_data()
        
        dashboard_data = {
            "realCostData": real_cost_data,
            "region": region,
            "dataSource": "AWS Cost Explorer" if real_cost_data else "Estimated"
        }
        
        return {
            "statusCode": 200,
            "headers": headers,
            "body": json.dumps(dashboard_data, cls=DecimalEncoder)
        }
        
    except Exception as e:
        print(f"Error getting dashboard data: {str(e)}")
        return {
            "statusCode": 500,
            "headers": headers,
            "body": json.dumps({"error": "Failed to get dashboard data", "details": str(e)})
        }

def get_real_cost_data():
    """Get real cost data from AWS Cost Explorer"""
    try:
        # Get current month date range
        now = datetime.now()
        start_date = now.replace(day=1).strftime('%Y-%m-%d')
        end_date = now.strftime('%Y-%m-%d')
        
        print(f"Fetching cost data from {start_date} to {end_date}")
        
        # Get current month costs by service
        response = ce.get_cost_and_usage(
            TimePeriod={
                'Start': start_date,
                'End': end_date
            },
            Granularity='MONTHLY',
            Metrics=['BlendedCost'],
            GroupBy=[
                {
                    'Type': 'DIMENSION',
                    'Key': 'SERVICE'
                }
            ]
        )
        
        # Process the response
        if not response.get('ResultsByTime'):
            print("No cost data available for current month")
            return None
            
        current_month_data = response['ResultsByTime'][0]
        groups = current_month_data.get('Groups', [])
        
        # Calculate total spend and find highest cost service
        total_spend = 0
        services = []
        highest_service = {"name": "No Data", "cost": 0}
        
        for group in groups:
            service_name = group['Keys'][0]
            cost_amount = float(group['Metrics']['BlendedCost']['Amount'])
            
            if cost_amount > 0:
                services.append({
                    "name": service_name,
                    "cost": cost_amount
                })
                total_spend += cost_amount
                
                # Track highest cost service
                if cost_amount > highest_service["cost"]:
                    highest_service = {"name": service_name, "cost": cost_amount}
        
        # Get forecast data for next month
        forecast_response = ce.get_cost_forecast(
            TimePeriod={
                'Start': end_date,
                'End': (now.replace(month=now.month + 1) if now.month < 12 else now.replace(year=now.year + 1, month=1)).strftime('%Y-%m-%d')
            },
            Metric='BLENDED_COST',
            Granularity='MONTHLY'
        )
        
        forecasted_bill = total_spend * 1.2  # Default 20% increase
        if forecast_response.get('ForecastResultsByTime'):
            try:
                forecasted_bill = float(forecast_response['ForecastResultsByTime'][0]['MeanValue'])
            except (KeyError, ValueError, IndexError):
                pass
        
        real_data = {
            "currentSpend": round(total_spend, 2),
            "forecastedBill": round(forecasted_bill, 2),
            "highestCostService": {
                "name": highest_service["name"],
                "cost": round(highest_service["cost"], 2)
            },
            "serviceBreakdown": [
                {
                    "name": service["name"],
                    "cost": round(service["cost"], 2)
                } for service in sorted(services, key=lambda x: x["cost"], reverse=True)[:10]  # Top 10 services
            ],
            "lastUpdated": datetime.utcnow().isoformat()
        }
        
        print(f"Real cost data retrieved: ${total_spend:.2f} total, {len(services)} services")
        return real_data
        
    except Exception as e:
        print(f"Error fetching real cost data: {str(e)}")
        # Return None so dashboard falls back to estimates
        return None

def update_threshold(event, headers):
    """Update CloudWatch alarm threshold"""
    try:
        body = json.loads(event.get("body", "{}"))
        threshold = float(body.get("threshold", 10.0))
        region = body.get("region", "us-east-1")
        
        # Update CloudWatch alarm
        alarm_name = "cost-tracker-billing-alarm"
        
        cloudwatch.put_metric_alarm(
            AlarmName=alarm_name,
            ComparisonOperator='GreaterThanThreshold',
            EvaluationPeriods=1,
            MetricName='EstimatedCharges',
            Namespace='AWS/Billing',
            Period=86400,
            Statistic='Maximum',
            Threshold=threshold,
            ActionsEnabled=True,
            AlarmActions=[
                # SNS topic ARN would be passed as environment variable
                os.environ.get("SNS_TOPIC_ARN", "")
            ],
            AlarmDescription=f'Billing alarm for threshold ${threshold}',
            Dimensions=[
                {
                    'Name': 'Currency',
                    'Value': 'USD'
                },
            ]
        )
        
        # Log the threshold update
        table.put_item(Item={
            "id": datetime.utcnow().isoformat(),
            "message": f"Threshold updated to ${threshold}",
            "region": region,
            "severity": "info",
            "type": "threshold_update"
        })
        
        return {
            "statusCode": 200,
            "headers": headers,
            "body": json.dumps({
                "message": f"Threshold updated to ${threshold}",
                "threshold": threshold,
                "region": region
            })
        }
        
    except Exception as e:
        print(f"Error updating threshold: {str(e)}")
        return {
            "statusCode": 500,
            "headers": headers,
            "body": json.dumps({"error": "Failed to update threshold"})
        }

def stop_ec2_instances(event, headers):
    """Emergency stop all EC2 instances"""
    try:
        body = json.loads(event.get("body", "{}"))
        region = body.get("region", "us-east-1")
        
        # Get all running instances
        response = ec2.describe_instances(
            Filters=[
                {
                    'Name': 'instance-state-name',
                    'Values': ['running']
                }
            ]
        )
        
        instance_ids = []
        for reservation in response['Reservations']:
            for instance in reservation['Instances']:
                instance_ids.append(instance['InstanceId'])
        
        if instance_ids:
            # Stop all running instances
            ec2.stop_instances(InstanceIds=instance_ids)
            
            # Log the emergency stop
            table.put_item(Item={
                "id": datetime.utcnow().isoformat(),
                "message": f"Emergency stop: {len(instance_ids)} EC2 instances stopped",
                "region": region,
                "severity": "high",
                "type": "emergency_stop",
                "instance_ids": instance_ids
            })
            
            return {
                "statusCode": 200,
                "headers": headers,
                "body": json.dumps({
                    "message": f"Emergency stop initiated for {len(instance_ids)} instances",
                    "instanceIds": instance_ids,
                    "region": region
                })
            }
        else:
            return {
                "statusCode": 200,
                "headers": headers,
                "body": json.dumps({
                    "message": "No running EC2 instances found",
                    "instanceIds": [],
                    "region": region
                })
            }
        
    except Exception as e:
        print(f"Error stopping EC2 instances: {str(e)}")
        return {
            "statusCode": 500,
            "headers": headers,
            "body": json.dumps({"error": "Failed to stop EC2 instances"})
        }
