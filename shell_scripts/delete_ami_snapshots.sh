#Script to delete ami and  it's corresponding  snapshots.
#It takes ami id as input

#!/bin/bash  
echo -e "$1" > /tmp/ami.txt  
for i in `cat /tmp/ami.txt`;do aws ec2 describe-images --image-ids $i | grep -i snapshotid | awk '{print $4}'  > /tmp/snapshot.txt;  
echo -e "Following are the snapshots associated with it :\n`cat /tmp/snapshot.txt`\n ";  
echo -e "Starting  De-registeration of AMI... \n";  
#Deregistering the AMI  
aws ec2 deregister-image --image-id $i  
deregister=$?  
 if [ $deregister -eq 0 ];then  
   echo "Sucessfully Deregistered the AMI..."  
 else  
   echo "Deregister failed"  
 fi

echo -e "\now i am going to Delete the associated snapshots.... \n"  

#Deleting snapshots attached to AMI  
 for j in `cat /tmp/snapshot.txt`;do aws ec2 delete-snapshot --snapshot-id $j ; done  
 snap=$?  
 if [ $snap -eq 0 ];then  
   echo "Sucessfully Deleted all associated Snapshots..."  
 else  
   echo "Snapshot Deletion failed"  
 fi  
 
 done  


###########################################################
