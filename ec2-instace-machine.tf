resource "aws_instance" "my-test-instance" {
  ami             = "${lookup(var.AmiLinux, var.region)}"
  instance_type   = "t2.micro"
  iam_instance_profile = "${aws_iam_instance_profile.test_profile.name}" 
  vpc_security_group_ids =  ["${aws_security_group.instance.id}"]
  key_name      = "ansible-ssm-demo-key"
  user_data     = "${file("install_ansible.sh")}"


  tags {
    Name = "ssm-ansible-test-instance"
    OSPlatform = "Rhel 7.3"
  }
}


resource "aws_security_group" "instance" {
   name = "ansible-ssm-security-group-v2"

   # Inbound HTTP from anywhere
   ingress {
     from_port   = "${var.web_server_port}"
     to_port     = "${var.web_server_port}"
     protocol    = "tcp"
     cidr_blocks = ["0.0.0.0/0"]

   }

    ingress {
      from_port = 22
      to_port   = 22
      protocol  = "tcp"
      cidr_blocks = ["0.0.0.0/0"]

    }

    ingress {
      from_port = 443
      to_port   = 443
      protocol  = "tcp"
      cidr_blocks = ["0.0.0.0/0"]

    }

   egress {
     from_port   = 0
     to_port     = 0
     protocol    = "-1"
     cidr_blocks = ["0.0.0.0/0"]

   }
}
