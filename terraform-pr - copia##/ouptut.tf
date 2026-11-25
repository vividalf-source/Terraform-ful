output "nlb_dns_name" {
  value = aws_lb.nlb.dns_name
}

output "rds_endpoint" {
  value = aws_db_instance.mysql.endpoint
}

output "s3_bucket_name" {
  value = aws_s3_bucket.bucket.id
}