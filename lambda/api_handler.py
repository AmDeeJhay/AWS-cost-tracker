import boto3
import json
import os
import subprocess
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

def smart_round(amount):
    """Smart rounding - show more precision for very small amounts"""
    if amount == 0:
        return 0.00
    elif amount < 0.01:
        # For amounts less than 1 cent, show up to 6 decimal places
        return round(amount, 6)
    elif amount < 0.10:
        # For amounts less than 10 cents, show 4 decimal places
        return round(amount, 4)
    else:
        # For normal amounts, show 2 decimal places
        return round(amount, 2)

def get_real_cost_data():
    """Get real cost data from AWS Cost Explorer and CloudWatch Billing with multiple strategies"""
    try:
        # Get current month date range - Cost Explorer needs the full month range
        now = datetime.now()
        start_date = now.replace(day=1).strftime('%Y-%m-%d')
        
        # Try multiple end dates to get the most recent data
        end_dates_to_try = [
            now.strftime('%Y-%m-%d'),  # Today
            (now + timedelta(days=1)).strftime('%Y-%m-%d'),  # Tomorrow (Cost Explorer often needs this)
            (now + timedelta(days=2)).strftime('%Y-%m-%d')   # Day after tomorrow
        ]
        
        print(f"Fetching cost data from {start_date} with multiple end dates: {end_dates_to_try}")
        
        # Strategy 1: Try Cost Explorer with different end dates
        for end_date in end_dates_to_try:
            try:
                print(f"Trying Cost Explorer with end date: {end_date}")
                
                # First try: Get current month costs by service
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
                
                print(f"Cost Explorer response for {end_date}: {response}")
                
                # Process the response
                if response.get('ResultsByTime') and len(response['ResultsByTime']) > 0:
                    current_month_data = response['ResultsByTime'][0]
                    groups = current_month_data.get('Groups', [])
                    
                    # Calculate total spend and find highest cost service
                    total_spend = 0
                    services = []
                    highest_service = {"name": "No Data", "cost": 0}
                    
                    if groups:
                        # Process grouped data (by service)
                        print(f"Processing {len(groups)} service groups")
                        for group in groups:
                            service_name = group['Keys'][0]
                            cost_amount = float(group['Metrics']['BlendedCost']['Amount'])
                            
                            print(f"Service: {service_name}, Cost: ${cost_amount}")
                            
                            # Include all services, even those with very small costs
                            services.append({
                                "name": service_name,
                                "cost": cost_amount
                            })
                            total_spend += cost_amount
                            
                            # Track highest cost service (including very small amounts)
                            if cost_amount > highest_service["cost"]:
                                highest_service = {"name": service_name, "cost": cost_amount}
                    else:
                        # Process ungrouped data (total only)
                        print("Processing ungrouped total cost data")
                        total_cost = current_month_data.get('Total', {}).get('BlendedCost', {})
                        if total_cost:
                            total_spend = float(total_cost.get('Amount', 0))
                            print(f"Total ungrouped cost: ${total_spend}")
                            
                            if total_spend > 0:
                                # Since we don't have service breakdown, use a generic service
                                highest_service = {"name": "AWS Services", "cost": total_spend}
                                services = [{"name": "AWS Services", "cost": total_spend}]
                    
                    # If we found any data (even with very small amounts), use it
                    if total_spend >= 0 and len(services) > 0:
                        print(f"Found cost data: ${total_spend} with {len(services)} services for end date {end_date}")
                        
                        # Get forecast data for next month
                        try:
                            next_month = now.replace(month=now.month + 1) if now.month < 12 else now.replace(year=now.year + 1, month=1)
                            forecast_response = ce.get_cost_forecast(
                                TimePeriod={
                                    'Start': end_date,
                                    'End': next_month.strftime('%Y-%m-%d')
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
                        except Exception as forecast_error:
                            print(f"Forecast failed, using default: {forecast_error}")
                            forecasted_bill = total_spend * 1.2
                        
                        # Ensure we have a valid highest service even if costs are very small
                        if highest_service["cost"] == 0 and len(services) > 0:
                            # If all services have 0 cost, pick the first one
                            highest_service = services[0]
                        
                        real_data = {
                            "currentSpend": smart_round(total_spend),
                            "forecastedBill": smart_round(forecasted_bill),
                            "highestCostService": {
                                "name": highest_service["name"],
                                "cost": smart_round(highest_service["cost"])
                            },
                            "serviceBreakdown": [
                                {
                                    "name": service["name"],
                                    "cost": smart_round(service["cost"])
                                } for service in sorted(services, key=lambda x: x["cost"], reverse=True)[:10]  # Top 10 services
                            ],
                            "lastUpdated": datetime.utcnow().isoformat(),
                            "dataSource": f"AWS Cost Explorer (end_date: {end_date})"
                        }
                        
                        print(f"Real cost data retrieved: ${total_spend:.6f} total (rounded: ${smart_round(total_spend)}), {len(services)} services")
                        return real_data
                    else:
                        print(f"No non-zero cost data found with end date {end_date}")
                
            except Exception as ce_error:
                print(f"Cost Explorer failed for end date {end_date}: {ce_error}")
                continue
        
        # Strategy 2: Try CloudWatch billing metrics (more immediate)
        print("Trying CloudWatch billing data as fallback...")
        cloudwatch_cost = get_cloudwatch_billing_data()
        if cloudwatch_cost and cloudwatch_cost > 0:
            print(f"Using CloudWatch billing data: ${cloudwatch_cost}")
            return {
                "currentSpend": smart_round(cloudwatch_cost),
                "forecastedBill": smart_round(cloudwatch_cost * 1.2),  # 20% increase estimate
                "highestCostService": {
                    "name": "AWS Services (CloudWatch)",
                    "cost": smart_round(cloudwatch_cost)
                },
                "serviceBreakdown": [
                    {
                        "name": "AWS Services",
                        "cost": smart_round(cloudwatch_cost)
                    }
                ],
                "lastUpdated": datetime.utcnow().isoformat(),
                "dataSource": "CloudWatch Billing"
            }
        
        # Strategy 3: Try Cost Explorer with DAILY granularity for more recent data
        print("Trying Cost Explorer with DAILY granularity...")
        try:
            daily_response = ce.get_cost_and_usage(
                TimePeriod={
                    'Start': start_date,
                    'End': (now + timedelta(days=1)).strftime('%Y-%m-%d')
                },
                Granularity='DAILY',
                Metrics=['BlendedCost']
            )
            
            print(f"Daily Cost Explorer response: {daily_response}")
            
            if daily_response.get('ResultsByTime'):
                total_daily_spend = 0
                for result in daily_response['ResultsByTime']:
                    daily_cost = float(result['Total']['BlendedCost']['Amount'])
                    total_daily_spend += daily_cost
                    print(f"Daily cost for {result['TimePeriod']['Start']}: ${daily_cost}")
                
                if total_daily_spend > 0:
                    print(f"Total daily spend: ${total_daily_spend}")
                    return {
                        "currentSpend": smart_round(total_daily_spend),
                        "forecastedBill": smart_round(total_daily_spend * 1.2),
                        "highestCostService": {
                            "name": "AWS Services (Daily)",
                            "cost": smart_round(total_daily_spend)
                        },
                        "serviceBreakdown": [
                            {
                                "name": "AWS Services",
                                "cost": smart_round(total_daily_spend)
                            }
                        ],
                        "lastUpdated": datetime.utcnow().isoformat(),
                        "dataSource": "AWS Cost Explorer (Daily)"
                    }
        except Exception as daily_error:
            print(f"Daily Cost Explorer failed: {daily_error}")
        
        # Strategy 4: Try AWS CLI as final fallback
        print("Trying AWS CLI as final fallback...")
        cli_cost = get_billing_via_cli()
        if cli_cost and cli_cost > 0:
            print(f"Using AWS CLI billing data: ${cli_cost}")
            return {
                "currentSpend": smart_round(cli_cost),
                "forecastedBill": smart_round(cli_cost * 1.2),
                "highestCostService": {
                    "name": "AWS Services (CLI)",
                    "cost": smart_round(cli_cost)
                },
                "serviceBreakdown": [
                    {
                        "name": "AWS Services",
                        "cost": smart_round(cli_cost)
                    }
                ],
                "lastUpdated": datetime.utcnow().isoformat(),
                "dataSource": "AWS CLI"
            }
        
        print("No cost data available from any source")
        return None
        
    except Exception as e:
        print(f"Error fetching real cost data: {str(e)}")
        import traceback
        print(f"Full traceback: {traceback.format_exc()}")
        # Return None so dashboard falls back to estimates
        return None

def get_cloudwatch_billing_data():
    """Get billing data from CloudWatch metrics with multiple strategies"""
    try:
        # Try multiple time ranges to get the most recent data
        end_time = datetime.utcnow()
        time_ranges = [
            (end_time - timedelta(days=1), end_time),  # Last 24 hours
            (end_time - timedelta(days=7), end_time),  # Last 7 days
            (end_time - timedelta(days=30), end_time)  # Last 30 days
        ]
        
        for start_time, end_time_range in time_ranges:
            try:
                print(f"Trying CloudWatch billing for {start_time} to {end_time_range}")
                
                response = cloudwatch.get_metric_statistics(
                    Namespace='AWS/Billing',
                    MetricName='EstimatedCharges',
                    Dimensions=[
                        {
                            'Name': 'Currency',
                            'Value': 'USD'
                        }
                    ],
                    StartTime=start_time,
                    EndTime=end_time_range,
                    Period=86400,  # 1 day
                    Statistics=['Maximum']
                )
                
                print(f"CloudWatch billing response: {response}")
                
                if response.get('Datapoints'):
                    # Get the most recent datapoint
                    latest_datapoint = max(response['Datapoints'], key=lambda x: x['Timestamp'])
                    billing_amount = latest_datapoint['Maximum']
                    print(f"Latest CloudWatch billing amount: ${billing_amount}")
                    
                    if billing_amount > 0:
                        return billing_amount
                    else:
                        print(f"CloudWatch returned $0 for time range {start_time} to {end_time_range}")
                else:
                    print(f"No CloudWatch billing datapoints found for {start_time} to {end_time_range}")
                    
            except Exception as range_error:
                print(f"CloudWatch failed for time range {start_time} to {end_time_range}: {range_error}")
                continue
        
        print("No CloudWatch billing data found in any time range")
        return None
            
    except Exception as e:
        print(f"Error getting CloudWatch billing data: {str(e)}")
        return None

def get_billing_via_cli():
    """Get billing data using AWS CLI as final fallback"""
    try:
        # Get current month date range
        now = datetime.now()
        start_date = now.replace(day=1).strftime('%Y-%m-%d')
        end_date = (now + timedelta(days=1)).strftime('%Y-%m-%d')
        
        print(f"Trying AWS CLI for billing data from {start_date} to {end_date}")
        
        # Try to get cost data using AWS CLI
        cmd = [
            'aws', 'ce', 'get-cost-and-usage',
            '--time-period', f'Start={start_date},End={end_date}',
            '--granularity', 'MONTHLY',
            '--metrics', 'BlendedCost',
            '--output', 'json'
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        
        if result.returncode == 0:
            data = json.loads(result.stdout)
            print(f"AWS CLI response: {data}")
            
            if data.get('ResultsByTime') and len(data['ResultsByTime']) > 0:
                total_cost = float(data['ResultsByTime'][0]['Total']['BlendedCost']['Amount'])
                print(f"AWS CLI total cost: ${total_cost}")
                return total_cost
            else:
                print("No cost data in AWS CLI response")
                return None
        else:
            print(f"AWS CLI failed: {result.stderr}")
            return None
            
    except subprocess.TimeoutExpired:
        print("AWS CLI command timed out")
        return None
    except Exception as e:
        print(f"Error running AWS CLI: {str(e)}")
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
        
        # Log the threshold update with description
        threshold_description = f"The billing alarm threshold was updated to ${threshold}. Future cost alerts will trigger when spending exceeds this amount. This change affects monitoring for region {region}."
        table.put_item(Item={
            "id": datetime.utcnow().isoformat(),
            "message": f"Threshold updated to ${threshold}",
            "description": threshold_description,
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
    """Emergency stop and terminate all EC2 instances"""
    try:
        body = json.loads(event.get("body", "{}"))
        region = body.get("region", "us-east-1")
        
        # Get all running and stopped instances (to handle both cases)
        response = ec2.describe_instances(
            Filters=[
                {
                    'Name': 'instance-state-name',
                    'Values': ['running', 'stopped', 'stopping']
                }
            ]
        )
        
        running_instance_ids = []
        stopped_instance_ids = []
        
        for reservation in response['Reservations']:
            for instance in reservation['Instances']:
                instance_id = instance['InstanceId']
                state = instance['State']['Name']
                
                if state == 'running':
                    running_instance_ids.append(instance_id)
                elif state in ['stopped', 'stopping']:
                    stopped_instance_ids.append(instance_id)
        
        actions_taken = []
        total_instances = len(running_instance_ids) + len(stopped_instance_ids)
        
        # Stop running instances first
        if running_instance_ids:
            try:
                stop_response = ec2.stop_instances(InstanceIds=running_instance_ids)
                actions_taken.append(f"Stopped {len(running_instance_ids)} running instances")
                print(f"Stopped instances: {running_instance_ids}")
            except Exception as stop_error:
                print(f"Error stopping instances: {stop_error}")
                actions_taken.append(f"Failed to stop {len(running_instance_ids)} instances: {str(stop_error)}")
        
        # Terminate both running and stopped instances
        all_instance_ids = running_instance_ids + stopped_instance_ids
        if all_instance_ids:
            try:
                # Wait a moment for instances to stop if they were running
                if running_instance_ids:
                    import time
                    time.sleep(2)
                
                terminate_response = ec2.terminate_instances(InstanceIds=all_instance_ids)
                actions_taken.append(f"Terminated {len(all_instance_ids)} instances")
                print(f"Terminated instances: {all_instance_ids}")
            except Exception as terminate_error:
                print(f"Error terminating instances: {terminate_error}")
                actions_taken.append(f"Failed to terminate {len(all_instance_ids)} instances: {str(terminate_error)}")
        
        # Log the emergency action
        log_message = f"Emergency action: {', '.join(actions_taken)}" if actions_taken else "No instances found to process"
        
        table.put_item(Item={
            "id": datetime.utcnow().isoformat(),
            "message": log_message,
            "region": region,
            "severity": "high",
            "type": "emergency_stop",
            "instance_ids": all_instance_ids,
            "actions": actions_taken
        })
        
        return {
            "statusCode": 200,
            "headers": headers,
            "body": json.dumps({
                "message": log_message,
                "instanceIds": all_instance_ids,
                "region": region,
                "actions": actions_taken,
                "totalInstances": total_instances
            })
        }
        
    except Exception as e:
        print(f"Error processing EC2 instances: {str(e)}")
        import traceback
        print(f"Full traceback: {traceback.format_exc()}")
        
        # Log the error
        table.put_item(Item={
            "id": datetime.utcnow().isoformat(),
            "message": f"Emergency stop failed: {str(e)}",
            "region": region,
            "severity": "high",
            "type": "emergency_stop_error",
            "error": str(e)
        })
        
        return {
            "statusCode": 500,
            "headers": headers,
            "body": json.dumps({
                "error": "Failed to process EC2 instances",
                "details": str(e)
            })
        }
