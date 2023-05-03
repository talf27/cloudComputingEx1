# cloudComputingEx1

cloud-based system to manage a parking lot, with the actions:
- Entry (record time, license plate and parking lot)
- Exit (return the charge for the time in the parking lot)
- Price – 10$ per hour (by 15 minutes)

-----

The system tracks cars entry & exit from parking lots, as well as computes their charge.\
The system is deployed to AWS on an EC2 instance as standard application\
written in python with Flask.

-----

after cloning the repository:
- *cd ./cloudComputingEx1/*
- run the bash script that deploys the code to the cloud: *./setup.sh*
- you can see the script's output example at the file "output.txt".
