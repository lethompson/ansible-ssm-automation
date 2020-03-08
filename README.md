# Ansible & AWS System Manager Integration 

![Ansible-SSM](https://github.com/lethompson/ansible-ssm-automation/blob/master/Ansible.png)


## 1. Pre-Requisites

i. IAM Role - i.e ``` ManagedInstance-ssm-role ``` - with managed permissions


*  ``` AmazonEC2RoleforSSM ``` - To allow AWS Systems Manager to have permission to perform actions on the instances

## 2. Bootstrap Target Instances


For the target instance, lets use RedHat 7.x Linux instance

i. Assign the IAM Role created ``` ManagedInstance-ssm-role ```

### iam_role_ssm.tf 
#### Terraform code creates the following for the Redhat 7.x Linux AWS EC2 instance
- Create the role
- Create the policy
- Attach the policy to the role
- Attach the role to instance profile

``` 
resource "aws_iam_role" "ec2_ssm_access_role" {
  name               = "ManagedInstance-ssm-role"
  assume_role_policy = "${file("assumerolepolicy.json")}"
}

resource "aws_iam_policy" "policy" {
  name        = "test-policy"
  description = "A test policy"
  policy      = "${file("policyssm.json")}"
}

resource "aws_iam_policy_attachment" "test-attach" {
  name       = "test-attachment"
  roles      = ["${aws_iam_role.ec2_ssm_access_role.name}"]
  policy_arn = "${aws_iam_policy.policy.arn}"
}

resource "aws_iam_instance_profile" "test_profile" {
  name  = "test_profile"
  roles = ["${aws_iam_role.ec2_ssm_access_role.name}"]
}
``` 


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

### variables.tf

```
variable "region" {
  default = "us-east-1"
}
variable "AmiLinux" {
  type = "map"
  default = {
    us-east-1 = "ami-b63769a1" # Virginia
  }
  description = "have only added one region"
}

variable "default_resource_group" {
  description = "Default value to be used in resources' Group tag."
  default     = "ssm-ansible"
}

variable "default_created_by" {
  description = "Default value to be used in resources' CreatedBy tag."
  default     = "terraform"
}

variable "aws_region" {
  default = "us-east-1"
}

variable "web_server_port" {
default = 80
}
```

iv. Deploying the AWS infrastructure via Terraform
 ### Steps to run the terraform code to deploy the AWS Infrastructure
 
 ```
 > terraform init
 ```
 
 ```
 > terraform validate
 ```
 
 ```
 > terraform plan -out=tfplan
 ```
 
 ```
 > terraform apply tfplan
 ```
### Running Linux EC2 instance

![Running-EC2-Instance](https://github.com/lethompson/ansible-ssm-automation/blob/master/SSM-Project1.PNG)


 ### To destroy the AWS infrastructure deployed from the terraform code
  
 ```
 > terraform destroy
 ```
 
 ## 3. Create SSM State Manager
 
 * Choose ```Managed Instances ``` from the ``` System Manger Services ```
 
 ![ManagedInstance](https://github.com/lethompson/ansible-ssm-automation/blob/master/SSM-Project5.PNG)
 
 * Choose ``` State Manager ``` from the ``` System Manager Services ```
 * Click on ``` Create Association ```
 * Select the ``` AWS-RunAnsiblePlaybook ```
 
 ![ManagedInstance2](https://github.com/lethompson/ansible-ssm-automation/blob/master/SSM-Project7.PNG)
 
 ### Manually insert the ansible playbook (linux_playbook_httpd.yml) to install apache on the Linux server using System Manager 
 
 ```
 ---
# This playbook will install Apache Web Server with php and mysql support
- name: linux_deploy_httpd
  hosts: all
  tasks:
  - name: Install HTTPD
    yum:
      name: "{{ item }}"
      state: latest
    loop:
     - httpd
    when: ansible_os_family == "RedHat"

  - name: Setting default HTTP Server page
    shell: echo "<h1>welcome to Ensono Ansible Playbook Demo</h1>" >> /var/www/html/index.html

  - name: Start Apache Webserver
    service:
      name: httpd
      state: restarted

  - name: enable apache on startup and start service for redhat or centos
    service: name=httpd enabled=yes state=started
    when: ansible_os_family == "RedHat"
 ```
 ![ManagedInstance2b](https://github.com/lethompson/ansible-ssm-automation/blob/master/SSM-Project8.PNG)
 
 * For ``` Targets ``` Choose Manually selecting instance
 * In the Parameters Section, paste the playbook YAML directly.
 * Define the max errors as ``` 1 ```. This means that if the execution encounters 1 ``` error ``` it will stop on the remaining targets.
 
 ![ManagedInstance3](https://github.com/lethompson/ansible-ssm-automation/blob/master/SSM-Project9.PNG)
 
 ![ManagedInstance4](https://github.com/lethompson/ansible-ssm-automation/blob/master/SSM-Project10.PNG)
 
 ## 4. Testing the solution
 ### Copy the AWS EC2 public ip and paste in any web browser
 ![ManagedInstance5](https://github.com/lethompson/ansible-ssm-automation/blob/master/SSM-Project16.PNG)
 
 
