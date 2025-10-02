# S3 Bucket for static website
resource "aws_s3_bucket" "dashboard_bucket" {
  bucket = "${var.project_name}-dashboard-${random_string.bucket_suffix.result}"

  tags = {
    Name        = "${var.project_name}-dashboard"
    Environment = var.environment
  }
}

# Random string for unique bucket name
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "dashboard_bucket_pab" {
  bucket = aws_s3_bucket.dashboard_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# S3 Bucket Website Configuration
resource "aws_s3_bucket_website_configuration" "dashboard_website" {
  bucket = aws_s3_bucket.dashboard_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# S3 Bucket Policy for public read access
resource "aws_s3_bucket_policy" "dashboard_bucket_policy" {
  bucket = aws_s3_bucket.dashboard_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.dashboard_bucket.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.dashboard_bucket_pab]
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "dashboard_distribution" {
  origin {
    domain_name = aws_s3_bucket_website_configuration.dashboard_website.website_endpoint
    origin_id   = "S3-${aws_s3_bucket.dashboard_bucket.bucket}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.dashboard_bucket.bucket}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  # Custom error response for SPA
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name        = "${var.project_name}-cloudfront"
    Environment = var.environment
  }
}

# Upload HTML file to S3
resource "aws_s3_object" "dashboard_html" {
  bucket       = aws_s3_bucket.dashboard_bucket.id
  key          = "index.html"
  source       = "${path.module}/frontend/index.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/frontend/index.html")
}

# Upload JavaScript file to S3
resource "aws_s3_object" "dashboard_js" {
  bucket       = aws_s3_bucket.dashboard_bucket.id
  key          = "dashboard.js"
  source       = "${path.module}/frontend/dashboard.js"
  content_type = "application/javascript"
  etag         = filemd5("${path.module}/frontend/dashboard.js")
}
