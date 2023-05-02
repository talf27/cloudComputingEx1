#!/bin/bash

# Set variables
KEY_NAME="cloud-computing-ex1-$(date +'%N')"
KEY_PEM="$KEY_NAME.pem"
SEC_GRP="my-sg-$(date +'%N')"
UBUNTU_22_04_AMI="ami-064087b8d355e9051"

# Creating key pair and securing it
echo "Creating key pair $KEY_PEM to connect to instances and saving locally"
aws ec2 create-key-pair --key-name $KEY_NAME --query 'KeyMaterial' --output text > $KEY_PEM
chmod 400 $KEY_PEM

# Creating security group
echo "Creating security group $SEC_GRP"
aws ec2 create-security-group --group-name $SEC_GRP --description "Access my instances"

# Getting my public IP address
MY_IP=$(curl ipinfo.io/ip)
echo "My IP address is: $MY_IP"

echo \n"----------------------------------------------------------------------------------------------------"\n

# Setting up firewall rules
echo "Setting up firewall rules for SSH from $MY_IP only and HTTP access for all addresses"
aws ec2 authorize-security-group-ingress --group-name $SEC_GRP --port 22 --protocol tcp --cidr $MY_IP/32
aws ec2 authorize-security-group-ingress --group-name $SEC_GRP --port 5000 --protocol tcp --cidr 0.0.0.0/0

echo \n"----------------------------------------------------------------------------------------------------"\n

# Launching EC2 instance
echo "Launching Ubuntu EC2 instance"
RUN_INSTANCES=$(aws ec2 run-instances --image-id $UBUNTU_22_04_AMI --instance-type t3.micro --key-name $KEY_NAME --security-groups $SEC_GRP)
INSTANCE_ID=$(echo $RUN_INSTANCES | grep -oP '(?<="InstanceId": ")[^"]*' | cut -d '"' -f 1)

# Waiting for the instance to be created
echo "Waiting for instance creation..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

# Getting the public IP address of the instance
PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)

echo "New instance $INSTANCE_ID @ $PUBLIC_IP was created!"

echo \n"----------------------------------------------------------------------------------------------------"\n

# Deploying the Flask app
echo "Deploying Flask app to $PUBLIC_IP and setting up production environment (ignore the additional output...)"
scp -i $KEY_PEM -o "StrictHostKeyChecking=no" -o "ConnectionAttempts=60" app.py ubuntu@$PUBLIC_IP:/home/ubuntu/
ssh -i $KEY_PEM -o "StrictHostKeyChecking=no" -o "ConnectionAttempts=10" ubuntu@$PUBLIC_IP <<EOF
    sudo apt update
    sudo apt install python3-flask -y
    # run app
    nohup flask run --host 0.0.0.0 &>/dev/null &
    exit
EOF

echo \n"----------------------------------------------------------------------------------------------------"\n
echo "Deployment completed! checking the endpoints - outputs example:"
echo "car with plate number '123-123-123' enters to parking lot number 382:"
curl -X POST "http://$PUBLIC_IP:5000/entry?plate=123-123-123&parkingLot=382"
echo "\n\n"
echo "entered car exits the parking lot with no charge: (Try run the command: curl -X POST \"http://$PUBLIC_IP:5000/exit?ticketId=1\" later to see charge by hours)"
curl -X POST "http://$PUBLIC_IP:5000/exit?ticketId=1"