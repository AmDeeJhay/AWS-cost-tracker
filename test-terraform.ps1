# Terraform Installation Test Script
Write-Host "🔍 Testing Terraform Installation..." -ForegroundColor Cyan
Write-Host ""

# Test 1: Check if terraform command exists
Write-Host "Test 1: Checking if 'terraform' command is available..." -ForegroundColor Yellow
try {
    $terraformVersion = terraform version 2>$null
    if ($terraformVersion) {
        Write-Host "✅ SUCCESS: Terraform is installed!" -ForegroundColor Green
        Write-Host "Version: $($terraformVersion.Split("`n")[0])" -ForegroundColor Green
    } else {
        Write-Host "❌ FAILED: Terraform command not found" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ FAILED: Terraform command not found" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 2: Check if it's in PATH
Write-Host "Test 2: Checking if terraform is in PATH..." -ForegroundColor Yellow
$terraformPath = Get-Command terraform -ErrorAction SilentlyContinue
if ($terraformPath) {
    Write-Host "✅ SUCCESS: Terraform found in PATH at: $($terraformPath.Source)" -ForegroundColor Green
} else {
    Write-Host "❌ FAILED: Terraform not found in PATH" -ForegroundColor Red
    Write-Host "Make sure you added C:\terraform to your PATH environment variable" -ForegroundColor Yellow
}

Write-Host ""

# Test 3: Check if it's the official HashiCorp version
Write-Host "Test 3: Checking if it's official HashiCorp Terraform..." -ForegroundColor Yellow
try {
    $terraformVersion = terraform version 2>$null
    if ($terraformVersion -match "Terraform v") {
        Write-Host "✅ SUCCESS: Official HashiCorp Terraform detected!" -ForegroundColor Green
    } else {
        Write-Host "⚠️  WARNING: May not be official HashiCorp Terraform" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ FAILED: Cannot determine version" -ForegroundColor Red
}

Write-Host ""

# Test 4: Check if terraform can initialize
Write-Host "Test 4: Testing terraform init capability..." -ForegroundColor Yellow
if (Test-Path "main.tf") {
    Write-Host "✅ Found Terraform configuration files" -ForegroundColor Green
    Write-Host "You can now run: terraform init" -ForegroundColor Cyan
} else {
    Write-Host "⚠️  No Terraform configuration files found in current directory" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Cyan
Write-Host "=============" -ForegroundColor Cyan

if ($terraformPath) {
    Write-Host "✅ Terraform is ready! You can now:" -ForegroundColor Green
    Write-Host "1. Run: terraform init" -ForegroundColor White
    Write-Host "2. Run: terraform plan" -ForegroundColor White
    Write-Host "3. Run: terraform apply" -ForegroundColor White
} else {
    Write-Host "❌ Terraform installation incomplete. Please:" -ForegroundColor Red
    Write-Host "1. Download from: https://www.terraform.io/downloads" -ForegroundColor White
    Write-Host "2. Extract to C:\terraform" -ForegroundColor White
    Write-Host "3. Add C:\terraform to PATH" -ForegroundColor White
    Write-Host "4. Restart PowerShell" -ForegroundColor White
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
