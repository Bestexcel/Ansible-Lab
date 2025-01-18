#Creating outputs

output "ansible_ip" {
  value = aws_instance.ansible.public_ip
}

output "redhat_ip" {
  value = aws_instance.redhat.public_ip
}

output "ubuntu_ip" {
  value = aws_instance.ubuntu.public_ip
}