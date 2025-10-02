# 🔒 Secure Setup Guide - Cloud Cost Tracker

This guide uses **minimal IAM permissions** following the principle of least privilege for better security.

## 📋 Prerequisites Checklist

- [ ] AWS Account (free tier eligible)
- [ ] Windows 10/11 with PowerShell
- [ ] Internet connection
- [ ] Email address for notifications

---

## 🔧 Step 1: Install Required Software

### 1.1 Install Terraform

**Download Terraform:**
1. Go to [https://www.terraform.io/downloads](https://www.terraform.io/downloads)
2. Download the Windows AMD64 version
3. Extract the `terraform.exe` file to `C:\terraform`

**Add to PATH:**
1. Press `Win + R`, type `sysdm.cpl`, press Enter
2. Click "Environment Variables"
3. Under "System Variables", find and select "Path", click "Edit"
4. Click "New" and add `C:\terraform`
5. Click "OK" on all dialogs

**Verify Installation:**
```powershell
terraform version
```

### 1.2 Install AWS CLI

**Download AWS CLI:**
1. Go to [https://aws.amazon.com/cli/](https://aws.amazon.com/cli/)
2. Download the Windows installer (64-bit)
3. Run the installer and follow the prompts

**Verify Installation:**
```powershell
aws --version
```

---

## 🔐 Step 2: Set Up AWS Account Securely

### 2.1 Create AWS Account

1. Go to [https://aws.amazon.com/](https://aws.amazon.com/)
2. Click "Create an AWS Account"
3. Follow the registration process
4. **Important**: Use a valid email and phone number for verification

### 2.2 Enable Cost Explorer (Required for this project)

1. Sign in to AWS Console
2. Go to "Billing and Cost Management" → "Cost Explorer"
3. Click "Enable Cost Explorer"
4. Wait for activation (can take up to 24 hours)

### 2.3 Create Custom IAM Policy (Minimal Permissions)

**Create Custom Policy:**
1. Go to AWS Console → IAM → Policies
2. Click "Create policy"
3. Click "JSON" tab
4. Copy the content from `minimal-iam-policy.json` (included in this project)
5. Name it: `CostTrackerMinimalPolicy`
6. Description: `Minimal permissions for Cloud Cost Tracker system`
7. Click "Create policy"

### 2.4 Create IAM User with Minimal Permissions

**Create IAM User:**
1. Go to IAM → Users → "Create user"
2. Username: `cost-tracker-terraform`
3. Check "Programmatic access"
4. Click "Next: Permissions"

**Attach Custom Policy:**
1. Click "Attach existing policies directly"
2. Search for `CostTrackerMinimalPolicy`
3. Select it and click "Next: Tags"
4. Add tags (optional):
   - Key: `Project`, Value: `CostTracker`
   - Key: `Environment`, Value: `Dev`
5. Click "Next: Review" → "Create user"

**Save Credentials:**
1. **IMPORTANT**: Download the CSV file with Access Key ID and Secret Access Key
2. Keep this file secure - you'll need it for configuration

---

## ⚙️ Step 3: Configure AWS CLI

### 3.1 Configure AWS Credentials

```powershell
aws configure
```

**Enter the following when prompted:**
- AWS Access Key ID: `[Your Access Key from Step 2.4]`
- AWS Secret Access Key: `[Your Secret Key from Step 2.4]`
- Default region name: `us-east-1`
- Default output format: `json`

### 3.2 Test AWS Connection

```powershell
aws sts get-caller-identity
```

You should see your account details. If you get an error, check your credentials.

---

## 📁 Step 4: Set Up Project

### 4.1 Navigate to Project Directory

```powershell
cd C:\Users\DeeJhay\Documents\cloud-cost-tracker
```

### 4.2 Create Terraform Variables File

```powershell
copy terraform.tfvars.example terraform.tfvars
```

### 4.3 Edit terraform.tfvars

Open `terraform.tfvars` in a text editor and update:

```hcl
aws_region         = "us-east-1"
project_name       = "cost-tracker"
cost_threshold     = 10.00
notification_email = "your-email@example.com"  # CHANGE THIS!
schedule_expression = "rate(6 hours)"
environment        = "dev"
```

**Important**: Replace `your-email@example.com` with your actual email address!

---

## 🚀 Step 5: Deploy the System

### 5.1 Initialize Terraform

```powershell
terraform init
```

You should see:
```
Initializing the backend...
Initializing provider plugins...
Terraform has been successfully initialized!
```

### 5.2 Review the Plan

```powershell
terraform plan
```

This shows what resources will be created. Review the output carefully.

### 5.3 Deploy the Infrastructure

```powershell
terraform apply
```

Type `yes` when prompted. This will take 5-10 minutes.

**Expected Output:**
- DynamoDB table
- SNS topic
- CloudWatch alarm
- Lambda functions
- API Gateway
- S3 bucket
- CloudFront distribution

### 5.4 Get Important URLs

After deployment, run:

```powershell
terraform output
```

**Save these URLs:**
- `api_gateway_url`: Your API endpoint
- `dashboard_url`: Your dashboard URL

---

## 🔧 Step 6: Update Frontend

### 6.1 Update API URL in Frontend

1. Open `frontend/index.html` in a text editor
2. Find `YOUR_API_GATEWAY_URL` (around line 72)
3. Replace it with your actual API Gateway URL from Step 5.4
4. Save the file

### 6.2 Re-upload Frontend

```powershell
terraform apply
```

This updates the S3 bucket with your modified frontend.

---

## 🧪 Step 7: Test the System

### 7.1 Test Dashboard

1. Open your browser
2. Go to the `dashboard_url` from Step 5.4
3. You should see the CWA Cost Tracker Dashboard

### 7.2 Test Lambda Functions

**Test Cost Logger:**
1. Go to AWS Console → Lambda
2. Find `cost-tracker-cost-logger` function
3. Click "Test" → "Create new test event"
4. Use this test event:
```json
{
  "Records": [
    {
      "Sns": {
        "Message": "Test cost alert: $15.50"
      }
    }
  ]
}
```
5. Click "Test"
6. Check DynamoDB for new entries

**Test API Handler:**
1. Go to AWS Console → Lambda
2. Find `cost-tracker-api-handler` function
3. Click "Test" → "Create new test event"
4. Use this test event:
```json
{}
```
5. Click "Test"
6. Check the response

### 7.3 Test DynamoDB

```powershell
aws dynamodb scan --table-name cost-tracker-cost-logs
```

### 7.4 Test API Endpoint

```powershell
curl [YOUR_API_GATEWAY_URL]
```

---

## 🔔 Step 8: Test Alerts

### 8.1 Lower Cost Threshold for Testing

1. Edit `terraform.tfvars`
2. Change `cost_threshold = 0.01`
3. Run `terraform apply`

### 8.2 Check Email Notifications

1. Check your email for SNS subscription confirmation
2. Click the confirmation link
3. The alarm should trigger quickly with the low threshold

---

## 🛡️ Security Benefits of This Approach

### **Principle of Least Privilege:**
- ✅ Only permissions needed for this specific project
- ✅ Resources are scoped to `cost-tracker-*` naming
- ✅ No access to other AWS resources
- ✅ No administrative privileges

### **Specific Permissions:**
- ✅ DynamoDB: Only cost-tracker tables
- ✅ S3: Only cost-tracker buckets
- ✅ SNS: Only cost-tracker topics
- ✅ Lambda: Only cost-tracker functions
- ✅ API Gateway: Only cost-tracker APIs
- ✅ CloudWatch: Only cost-tracker alarms
- ✅ EventBridge: Only cost-tracker rules
- ✅ CloudFront: Only cost-tracker distributions

### **Audit Trail:**
- ✅ All actions are logged in CloudTrail
- ✅ IAM policy can be reviewed and modified
- ✅ User can be disabled/deleted easily

---

## 🚨 Troubleshooting

### Common Issues:

**1. "Access Denied" Errors:**
- Check your AWS credentials: `aws sts get-caller-identity`
- Verify IAM user has the custom policy attached
- Check if the policy was created correctly

**2. "Cost Explorer not enabled":**
- Go to AWS Console → Billing → Cost Explorer
- Click "Enable Cost Explorer"
- Wait up to 24 hours

**3. "Terraform not found":**
- Check PATH environment variable
- Restart PowerShell after adding to PATH

**4. "API Gateway 502 Error":**
- Check Lambda function logs in CloudWatch
- Verify API Gateway integration

**5. "Dashboard not loading":**
- Check CloudFront distribution status
- Verify S3 bucket policy allows public read

### Debug Commands:

```powershell
# Check AWS credentials
aws sts get-caller-identity

# Check Terraform version
terraform version

# Check AWS CLI version
aws --version

# List DynamoDB tables
aws dynamodb list-tables

# Check Lambda functions
aws lambda list-functions

# Check S3 buckets
aws s3 ls
```

---

## 📊 What You'll See

### Dashboard Features:
- **Header**: CWA Cost Tracker Dashboard
- **Alert Cards**: Individual cost alerts with timestamps
- **Stats**: Total alerts, recent alerts, last alert time
- **Refresh Button**: Load latest data
- **Responsive Design**: Works on mobile and desktop

### Backend Components:
- **DynamoDB**: Stores cost alerts
- **Lambda Functions**: Process and serve data
- **SNS**: Sends email notifications
- **CloudWatch**: Monitors costs
- **API Gateway**: Provides REST API
- **S3 + CloudFront**: Hosts dashboard

---

## 💰 Cost Considerations

**AWS Free Tier (First 12 months):**
- DynamoDB: 25 GB storage, 25 RCU/WCU
- Lambda: 1M requests, 400,000 GB-seconds
- S3: 5 GB storage, 20,000 GET requests
- CloudFront: 1 TB data transfer, 10M requests
- API Gateway: 1M API calls
- SNS: 1M requests

**Estimated monthly cost: $0-5** (within free tier)

---

## 🎉 Success!

Once everything is working, you'll have:
- ✅ A beautiful cost tracking dashboard
- ✅ Automated cost monitoring
- ✅ Email alerts when thresholds are exceeded
- ✅ REST API for programmatic access
- ✅ Scalable, cloud-native architecture
- ✅ **Secure, minimal permissions**

**Next Steps:**
- Monitor your AWS costs
- Customize alert thresholds
- Add more monitoring features
- Scale as needed

---

## 🆘 Need Help?

If you encounter issues:
1. Check the troubleshooting section above
2. Review AWS CloudWatch logs
3. Verify all prerequisites are installed
4. Check AWS service limits and permissions
5. Ensure the custom IAM policy is correctly attached

Happy secure cost tracking! 📊💰🔒


