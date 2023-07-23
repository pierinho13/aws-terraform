output "public_dns" {
  value = aws_instance.my_server.public_dns
}

output "public_ip" {
  value = aws_instance.my_server.public_ip
}

output "my_app" {
  value = "http://${aws_instance.my_server.public_dns}:8080"
  description = "public dns my app in my server"
}