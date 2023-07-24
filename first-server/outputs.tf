output "public_dns_server_1" {
  value = aws_instance.servidor_1.public_dns
}
output "public_dns_server2" {
  value = aws_instance.servidor_2.public_dns
}

output "public_ip_server_1" {
  value = aws_instance.servidor_1.public_ip
}
output "public_ip_server_2" {
  value = aws_instance.servidor_2.public_ip
}

output "my_app" {
  value       = "http://${aws_instance.servidor_1.public_dns}:8080"
  description = "public dns my app in my server"
}

output "my_app_2" {
  value       = "http://${aws_instance.servidor_2.public_dns}:8080"
  description = "public dns my app in my server"
}