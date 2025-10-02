# AWS Cost Tracker v2.0 Upgrade Script
# This script helps upgrade from v1.0 to the modern v2.0 dashboard

Write-Host "🚀 AWS Cost Tracker v2.0 Upgrade Script" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Check prerequisites
Write-Host "🔍 Checking Prerequisites..." -ForegroundColor Cyan

# Check if we're in the right directory
if (-not (Test-Path "main.tf")) {
    Write-Host "❌ Error: main.tf not found. Please run this script from the project root directory." -ForegroundColor Red
    exit 1
}

# Check Terraform
if (-not (Get-Command "terraform" -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Error: Terraform not found. Please install Terraform first." -ForegroundColor Red
    exit 1
}

# Check AWS CLI
if (-not (Get-Command "aws" -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Error: AWS CLI not found. Please install AWS CLI first." -ForegroundColor Red
    exit 1
}

Write-Host "✅ Prerequisites check passed!" -ForegroundColor Green
Write-Host ""

# Backup existing data
Write-Host "💾 Creating Backup..." -ForegroundColor Cyan
try {
    $backupDir = "backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    
    # Backup DynamoDB data
    Write-Host "   📊 Backing up DynamoDB data..."
    aws dynamodb scan --table-name cost-tracker-cost-logs --output json > "$backupDir/dynamodb-backup.json"
    
    # Backup Terraform state
    Write-Host "   🏗️ Backing up Terraform state..."
    Copy-Item "terraform.tfstate*" $backupDir -ErrorAction SilentlyContinue
    
    Write-Host "✅ Backup created in: $backupDir" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Warning: Could not create complete backup. Continuing..." -ForegroundColor Yellow
}
Write-Host ""

# Show what's new
Write-Host "✨ What's New in v2.0:" -ForegroundColor Magenta
Write-Host "   🎨 Modern UI with dark/light mode toggle"
Write-Host "   📊 Interactive charts with Recharts"
Write-Host "   ⚙️ Customizable thresholds in dashboard"
Write-Host "   🌍 Multi-region monitoring support"
Write-Host "   🚨 Emergency EC2 stop functionality"
Write-Host "   📱 Fully responsive design"
Write-Host "   🔗 Enhanced API with multiple endpoints"
Write-Host ""

# Confirm upgrade
$confirm = Read-Host "Do you want to proceed with the upgrade? (y/N)"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "❌ Upgrade cancelled by user." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "🔄 Starting Upgrade Process..." -ForegroundColor Cyan

# Step 1: Terraform Plan
Write-Host "📋 Step 1: Reviewing changes..." -ForegroundColor Yellow
try {
    terraform plan -out=upgrade.tfplan
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform plan failed"
    }
    Write-Host "✅ Terraform plan completed successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Error during terraform plan: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
$applyConfirm = Read-Host "The plan looks good. Apply changes? (y/N)"
if ($applyConfirm -ne "y" -and $applyConfirm -ne "Y") {
    Write-Host "❌ Upgrade cancelled. Run 'terraform apply upgrade.tfplan' manually when ready." -ForegroundColor Yellow
    exit 0
}

# Step 2: Apply Changes
Write-Host "🚀 Step 2: Applying infrastructure changes..." -ForegroundColor Yellow
try {
    terraform apply upgrade.tfplan
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform apply failed"
    }
    Write-Host "✅ Infrastructure updated successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Error during terraform apply: $_" -ForegroundColor Red
    Write-Host "💡 Check the error above and run 'terraform apply' manually if needed." -ForegroundColor Yellow
    exit 1
}

# Step 3: Get outputs
Write-Host ""
Write-Host "📊 Step 3: Getting deployment information..." -ForegroundColor Yellow
$outputs = terraform output -json | ConvertFrom-Json

if ($outputs.dashboard_url) {
    $dashboardUrl = $outputs.dashboard_url.value
    Write-Host "✅ Dashboard URL: $dashboardUrl" -ForegroundColor Green
} else {
    Write-Host "⚠️ Could not retrieve dashboard URL. Run 'terraform output dashboard_url'" -ForegroundColor Yellow
}

if ($outputs.api_gateway_url) {
    $apiUrl = $outputs.api_gateway_url.value
    Write-Host "✅ API Gateway URL: $apiUrl" -ForegroundColor Green
} else {
    Write-Host "⚠️ Could not retrieve API URL. Run 'terraform output api_gateway_url'" -ForegroundColor Yellow
}

# Step 4: Verification
Write-Host ""
Write-Host "🧪 Step 4: Verifying deployment..." -ForegroundColor Yellow

# Test API endpoint
if ($apiUrl) {
    try {
        Write-Host "   🔗 Testing API endpoint..."
        $response = Invoke-RestMethod -Uri $apiUrl -Method GET -TimeoutSec 10
        Write-Host "   ✅ API endpoint responding correctly" -ForegroundColor Green
    } catch {
        Write-Host "   ⚠️ API endpoint test failed. This might be normal if data is still loading." -ForegroundColor Yellow
    }
}

# Check Lambda functions
Write-Host "   ⚡ Checking Lambda functions..."
try {
    $functions = aws lambda list-functions --query "Functions[?contains(FunctionName, 'cost-tracker')].FunctionName" --output text
    if ($functions) {
        Write-Host "   ✅ Lambda functions deployed: $functions" -ForegroundColor Green
    }
} catch {
    Write-Host "   ⚠️ Could not verify Lambda functions" -ForegroundColor Yellow
}

# Check DynamoDB
Write-Host "   📊 Checking DynamoDB table..."
try {
    $table = aws dynamodb describe-table --table-name cost-tracker-cost-logs --query "Table.TableStatus" --output text
    if ($table -eq "ACTIVE") {
        Write-Host "   ✅ DynamoDB table is active" -ForegroundColor Green
    }
} catch {
    Write-Host "   ⚠️ Could not verify DynamoDB table" -ForegroundColor Yellow
}

# Cleanup
Remove-Item "upgrade.tfplan" -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "🎉 Upgrade Complete!" -ForegroundColor Green
Write-Host "===================" -ForegroundColor Green
Write-Host ""

if ($dashboardUrl) {
    Write-Host "🌐 Your new modern dashboard is available at:" -ForegroundColor Cyan
    Write-Host "   $dashboardUrl" -ForegroundColor White
    Write-Host ""
}

Write-Host "✨ New Features Available:" -ForegroundColor Magenta
Write-Host "   • Dark/Light mode toggle (top right)" -ForegroundColor White
Write-Host "   • Interactive cost charts" -ForegroundColor White
Write-Host "   • Settings panel for threshold updates" -ForegroundColor White
Write-Host "   • Multi-region monitoring dropdown" -ForegroundColor White
Write-Host "   • Emergency EC2 stop controls (use carefully!)" -ForegroundColor White
Write-Host ""

Write-Host "📚 Documentation:" -ForegroundColor Cyan
Write-Host "   • Read MODERN_DASHBOARD_README.md for detailed features" -ForegroundColor White
Write-Host "   • Check COMPLETE_PROJECT_DOCUMENTATION.md for technical details" -ForegroundColor White
Write-Host ""

Write-Host "🔧 Next Steps:" -ForegroundColor Yellow
Write-Host "   1. Visit your dashboard and explore the new features" -ForegroundColor White
Write-Host "   2. Test the settings panel to update your cost threshold" -ForegroundColor White
Write-Host "   3. Try switching between light and dark modes" -ForegroundColor White
Write-Host "   4. Explore multi-region monitoring if you use multiple regions" -ForegroundColor White
Write-Host ""

Write-Host "⚠️ Important Notes:" -ForegroundColor Red
Write-Host "   • Emergency stop feature can stop ALL EC2 instances - use with caution!" -ForegroundColor White
Write-Host "   • Test all features in a development environment first" -ForegroundColor White
Write-Host "   • Your backup is saved in: $backupDir" -ForegroundColor White
Write-Host ""

Write-Host "🎊 Enjoy your new modern AWS Cost Tracker dashboard!" -ForegroundColor Green

# Open dashboard in browser (optional)
$openBrowser = Read-Host "Would you like to open the dashboard in your browser now? (y/N)"
if ($openBrowser -eq "y" -or $openBrowser -eq "Y") {
    if ($dashboardUrl) {
        Start-Process $dashboardUrl
    } else {
        Write-Host "❌ Dashboard URL not available. Please check terraform outputs." -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
