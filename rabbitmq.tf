# On terraform registry search for ec2 spot instance in resources

resource "aws_spot_instance_request" "instance" {
  ami           = data.aws_ami.ami.image_id
  spot_price    = data.aws_ec2_spot_price.spot_price.spot_price
  instance_type = var.INSTANCE_TYPE
  wait_for_fulfillment = true
  subnet_id = var.PRIVATE_SUBNET_IDS[0]
  vpc_security_group_ids = [aws_security_group.main.id]
  iam_instance_profile = aws_iam_instance_profile.allow-secret-manager-read-access.name

  tags = {
    Name = local.TAG_PREFIX
  }
}

resource "aws_ec2_tag" "name-tag" {
  resource_id = aws_spot_instance_request.instance.spot_instance_id
  key = "name"
  value = local.TAG_PREFIX
}

resource "null_resource" "ansible" {
  provisioner "remote-exec" {
    connection {
      user = jsondecode(data.aws_secretsmanager_secret_version.secret.secret_string)["SSH_USER"]
      password = jsondecode(data.aws_secretsmanager_secret_version.secret.secret_string)["SSH_PASS"]
      host = aws_spot_instance_request.instance.private_ip
    }

    inline = [
    "ansible-pull -U http://github.com/dailypractice-all/roboshop-ansible.git roboshop.yml -e HOST=localhost -e ROLE=rabbitmq -e ENV=${var.ENV}",
    ]
  }
}

