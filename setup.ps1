# Cloud Cost Tracker Setup Script
# Run this script to help set up your environment

Write-Host "🚀 Cloud Cost Tracker Setup Script" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Host "⚠️  This script should be run as Administrator for best results" -ForegroundColor Yellow
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    Write-Host ""
}

# Function to check if a command exists
function Test-Command($cmdname) {
    return [bool](Get-Command -Name $cmdname -ErrorAction SilentlyContinue)
}

Write-Host "🔍 Checking Prerequisites..." -ForegroundColor Cyan
Write-Host ""

# Check Terraform
if (Test-Command "terraform") {
    $terraformVersion = terraform version
    Write-Host "✅ Terraform: $($terraformVersion.Split("`n")[0])" -ForegroundColor Green
} else {
    Write-Host "❌ Terraform: Not installed" -ForegroundColor Red
    Write-Host "   Download from: https://www.terraform.io/downloads" -ForegroundColor Yellow
    Write-Host "   Add to PATH after installation" -ForegroundColor Yellow
}

Write-Host ""

# Check AWS CLI
if (Test-Command "aws") {
    $awsVersion = aws --version
    Write-Host "✅ AWS CLI: $($awsVersion.Split("`n")[0])" -ForegroundColor Green
} else {
    Write-Host "❌ AWS CLI: Not installed" -ForegroundColor Red
    Write-Host "   Download from: https://aws.amazon.com/cli/" -ForegroundColor Yellow
}

Write-Host ""

# Check Git
if (Test-Command "git") {
    $gitVersion = git --version
    Write-Host "✅ Git: $gitVersion" -ForegroundColor Green
} else {
    Write-Host "⚠️  Git: Not installed (optional but recommended)" -ForegroundColor Yellow
    Write-Host "   Download from: https://git-scm.com/download/win" -ForegroundColor Yellow
}

Write-Host ""

# Check AWS Configuration
Write-Host "🔐 Checking AWS Configuration..." -ForegroundColor Cyan
try {
    $awsIdentity = aws sts get-caller-identity 2>$null
    if ($awsIdentity) {
        $accountId = ($awsIdentity | ConvertFrom-Json).Account
        Write-Host "✅ AWS CLI configured for Account: $accountId" -ForegroundColor Green
    } else {
        Write-Host "❌ AWS CLI not configured" -ForegroundColor Red
        Write-Host "   Run: aws configure" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ AWS CLI not configured" -ForegroundColor Red
    Write-Host "   Run: aws configure" -ForegroundColor Yellow
}

Write-Host ""

# Check if terraform.tfvars exists
if (Test-Path "terraform.tfvars") {
    Write-Host "✅ terraform.tfvars found" -ForegroundColor Green
} else {
    Write-Host "❌ terraform.tfvars not found" -ForegroundColor Red
    Write-Host "   Run: copy terraform.tfvars.example terraform.tfvars" -ForegroundColor Yellow
    Write-Host "   Then edit terraform.tfvars with your email address" -ForegroundColor Yellow
}

Write-Host ""

# Check if terraform is initialized
if (Test-Path ".terraform") {
    Write-Host "✅ Terraform initialized" -ForegroundColor Green
} else {
    Write-Host "⚠️  Terraform not initialized" -ForegroundColor Yellow
    Write-Host "   Run: terraform init" -ForegroundColor Yellow
}

Write-Host ""

# Provide next steps
Write-Host "📋 Next Steps:" -ForegroundColor Cyan
Write-Host "=============" -ForegroundColor Cyan

if (-not (Test-Command "terraform")) {
    Write-Host "1. Install Terraform and add to PATH" -ForegroundColor White
}

if (-not (Test-Command "aws")) {
    Write-Host "1. Install AWS CLI" -ForegroundColor White
}

if (-not (Test-Path "terraform.tfvars")) {
    Write-Host "1. Create terraform.tfvars file" -ForegroundColor White
    Write-Host "   copy terraform.tfvars.example terraform.tfvars" -ForegroundColor Gray
    Write-Host "   Edit with your email address" -ForegroundColor Gray
}

Write-Host "2. Configure AWS CLI:" -ForegroundColor White
Write-Host "   aws configure" -ForegroundColor Gray

Write-Host "3. Initialize Terraform:" -ForegroundColor White
Write-Host "   terraform init" -ForegroundColor Gray

Write-Host "4. Deploy the system:" -ForegroundColor White
Write-Host "   terraform plan" -ForegroundColor Gray
Write-Host "   terraform apply" -ForegroundColor Gray

Write-Host "5. Update frontend with API URL:" -ForegroundColor White
Write-Host "   Edit frontend/index.html" -ForegroundColor Gray
Write-Host "   Replace YOUR_API_GATEWAY_URL" -ForegroundColor Gray

Write-Host "6. Re-upload frontend:" -ForegroundColor White
Write-Host "   terraform apply" -ForegroundColor Gray

Write-Host ""
Write-Host "📖 For detailed instructions, see SETUP_GUIDE.md" -ForegroundColor Cyan
Write-Host ""

# Check if all prerequisites are met
$allGood = $true

if (-not (Test-Command "terraform")) { $allGood = $false }
if (-not (Test-Command "aws")) { $allGood = $false }
if (-not (Test-Path "terraform.tfvars")) { $allGood = $false }

if ($allGood) {
    Write-Host "🎉 All prerequisites are ready! You can proceed with deployment." -ForegroundColor Green
} else {
    Write-Host "⚠️  Please complete the missing prerequisites before deploying." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
