# __generated__ by Terraform
# Please review these resources and move them into your main configuration files.

resource "aws_volume_attachment" "vol-0f0534d099b1fcff7" {
  device_name = "/dev/xvdf"
  instance_id = "i-xxxxxxxxxxxxxxxxx"
  volume_id   = "vol-0f0534d099b1fcff7"
}

resource "aws_volume_attachment" "vol-008d72649b3ec8cd3" {
  device_name = "/dev/xvde"
  instance_id = "i-xxxxxxxxxxxxxxxxx"
  volume_id   = "vol-008d72649b3ec8cd3"
}

resource "aws_ebs_volume" "vol-0765af5e7f98e4ff2" {
  availability_zone    = "eu-west-1b"
  encrypted            = true
  iops                 = 3000
  kms_key_id           = "arn:aws:kms:eu-west-1:xxxxxxxxxxxx:key/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  multi_attach_enabled = false
  size                 = 30
  tags = {
    IACImported = "Yes"
    device_name = "/dev/sdc"
  }

  throughput = 125
  type       = "gp3"
}

resource "aws_volume_attachment" "vol-0765af5e7f98e4ff2" {
  device_name = "/dev/sdc"
  instance_id = "i-xxxxxxxxxxxxxxxxx"
  volume_id   = "vol-0765af5e7f98e4ff2"
}

resource "aws_ebs_volume" "vol-008d72649b3ec8cd3" {
  availability_zone    = "eu-west-1b"
  encrypted            = true
  iops                 = 3000
  kms_key_id           = "arn:aws:kms:eu-west-1:xxxxxxxxxxxx:key/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  multi_attach_enabled = false
  size                 = 20
  tags = {
    Name                 = "codifyme-web -instance1"
    environment          = "Dev"
    application          = "GenericApp"
    managed_by           = "Terraform"
    criticality          = "low"
  }

  throughput = 125
  type       = "gp3"
}

resource "aws_ebs_volume" "vol-0f0534d099b1fcff7" {
  availability_zone    = "eu-west-1b"
  encrypted            = true
  iops                 = 3000
  kms_key_id           = "arn:aws:kms:eu-west-1:xxxxxxxxxxxx:key/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  multi_attach_enabled = false
  size                 = 20
  tags = {
    Name                 = "codifyme-web -instance1"
    environment          = "Dev"
    application          = "GenericApp"
    managed_by           = "Terraform"
    criticality          = "low"
  }

  throughput = 125
  type       = "gp3"
}

resource "aws_route53_record" "codifyme-web -instance1" {
  name    = "codifyme-web -instance1.example.com"
  records = ["172.31.94.99"]
  ttl     = 300
  type    = "A"
  zone_id = "Zxxxxxxxxxxxxxxxxx"
}

resource "aws_instance" "codifyme-web -instance1" {
  ami                                  = "ami-xxxxxxxxxxxxxxxxx"
  associate_public_ip_address          = false
  availability_zone                    = "eu-west-1b"
  disable_api_stop                     = false
  disable_api_termination              = false
  ebs_optimized                        = false
  get_password_data                    = false
  hibernation                          = false
  iam_instance_profile                 = "GenericInstanceProfile"
  instance_initiated_shutdown_behavior = "stop"
  instance_type                        = "t2.medium"
  key_name                             = "codifyme-key"
  monitoring                           = false
  private_ip                           = "172.31.94.99"
  source_dest_check                    = true
  subnet_id                            = "subnet-xxxxxxxxxxxxxxxxx"
  tags = {
    Name                 = "codifyme-web -instance1"
    environment          = "Dev"
    application          = "GenericApp"
    managed_by           = "Terraform"
    criticality          = "low"
  }

  tenancy                = "default"
  user_data              = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  vpc_security_group_ids = ["sg-xxxxxxxxxxxxxxxxx"]

  enclave_options {
    enabled = false
  }

  maintenance_options {
    auto_recovery = "default"
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_protocol_ipv6          = "disabled"
    http_put_response_hop_limit = 1
    http_tokens                 = "optional"
    instance_metadata_tags      = "disabled"
  }

  private_dns_name_options {
    enable_resource_name_dns_a_record    = false
    enable_resource_name_dns_aaaa_record = false
    hostname_type                        = "ip-name"
  }

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    iops                  = 100
    kms_key_id            = "arn:aws:kms:eu-west-1:xxxxxxxxxxxx:key/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    tags = {
      Name                 = "codifyme-root-vol"
      environment          = "Dev"
      application          = "GenericApp"
      managed_by           = "Terraform"
      criticality          = "low"
    }

    volume_size = 10
    volume_type = "gp2"
  }
}
