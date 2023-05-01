#!/bin/bash

# Set variables
KEY_NAME="cloud-computing-ex1-$(date +'%N')"
KEY_PEM="$KEY_NAME.pem"
SEC_GRP="my-sg-$(date +'%N')"
UBUNTU_AMI="ami-0577c11149d377ab7"

# Create key pair
# echo "Creating key pair $KEY_PEM to connect to instances and saving locally"
aws ec2 create-key-pair --key-name $KEY_NAME --query 'KeyMaterial' --output text > $KEY_PEM
chmod 400 $KEY_PEM

# Create security group
# echo "Creating security group $SEC_GRP"
aws ec2 create-security-group --group-name $SEC_GRP --description "Access my instances" 

# Get the public IP address
MY_IP=$(curl ipinfo.io/ip)

# Set up firewall rules
# echo "Setting up firewall rules for SSH and HTTP access from $MY_IP only"
aws ec2 authorize-security-group-ingress --group-name $SEC_GRP --port 22 --protocol tcp --cidr $MY_IP/32
aws ec2 authorize-security-group-ingress --group-name $SEC_GRP --port 5000 --protocol tcp --cidr 0.0.0.0/32

# Launch EC2 instance
# echo "Launching Ubuntu 20.04 instance"
RUN_INSTANCES=$(aws ec2 run-instances --image-id $UBUNTU_AMI --instance-type t3.micro --key-name $KEY_NAME --security-groups $SEC_GRP)
INSTANCE_ID=$(echo $RUN_INSTANCES | grep -oP '(?<="InstanceId": ")[^"]*' | cut -d '"' -f 1)

# Wait for the instance to be created
# echo "Waiting for instance creation..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

# Get the public IP address of the instance
PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)

# Deploy the Flask app
# echo "Deploying Flask app to $PUBLIC_IP"
scp -i $KEY_PEM -o "StrictHostKeyChecking=no" -o "ConnectionAttempts=60" app.py ubuntu@$PUBLIC_IP:/home/ubuntu/
ssh -i $KEY_PEM -o "StrictHostKeyChecking=no" -o "ConnectionAttempts=10" ubuntu@$PUBLIC_IP <<EOF
    sudo apt update
    sudo apt install python3-flask -y
    nohup flask run --host 0.0.0.0 &>/dev/null &
    exit
EOF

echo "Deployment complete!"
