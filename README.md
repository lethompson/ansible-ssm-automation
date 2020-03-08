# Ansible & AWS System Manager Integration 

![Ansible-SSM](https://github.com/lethompson/ansible-ssm-automation/blob/master/Ansible.png)


## 1. Pre-Requisites

i. IAM Role - i.e ``` ManagedInstance-ssm-role ``` - with managed permissions


*  ``` AmazonEC2RoleforSSM ``` - To allow AWS Systems Manager to have permission to perform actions on the instances

## 2. Bootstrap Target Instances


For the target instance, lets use RedHat 7.x Linux instance

i. Assign the IAM Role created ``` ManagedInstance-ssm-role ```

ii. Include the bootstrap script in your terraform code ``` install_ansible.sh ```

``` 
#!/bin/bash
yum update -y
yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent
rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum -y install ansible

```

iii. Terraform script to spin up RedHat 7.3 Linux instances with the bootstrap script included

### ec2-instance-machine.tf
```
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
```

### Security Group for Linux EC2 instance
#### ec2-instance-machine.tf

```
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
```

