resource "tls_private_key" "ec2_instance" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "null_resource" "generate_key" {
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = <<-EOL
      echo '${tls_private_key.ec2_instance.private_key_pem}' > ./${var.generated_key_name}.pem
      chmod 400 ./${var.generated_key_name}.pem
      EOL
    }
  }

resource "aws_key_pair" "generated_key" {
  key_name   = var.ec2_key_name
  public_key = tls_private_key.ec2_instance.public_key_openssh
}