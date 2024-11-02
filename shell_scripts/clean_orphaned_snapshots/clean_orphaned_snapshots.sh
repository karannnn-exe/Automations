#!/bin/bash
set -euo pipefail
# Uncomment the next line during testing for verbose output
# set -x

<< comments
This Bash script identifies and deletes orphaned Amazon EC2 snapshots in your AWS account.
Orphaned snapshots are those that are not associated with any Amazon Machine Images (AMIs) and are no longer needed.
comments

# Variables
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION="us-west-2"
PARALLEL_DELETIONS="10"

# Functions
# Finding orphaned snapshots
find_orphaned_snapshots() {
    echo "Finding orphaned snapshots..."

    # Get all snapshot IDs in the account
    snapshot_ids=$(aws ec2 describe-snapshots --owner-ids "$AWS_ACCOUNT_ID" --query 'Snapshots[*].SnapshotId' --output text --region "$REGION")
    if [[ -z $snapshot_ids ]]; then
	    echo "No snapshots found in account."
	    return
    fi

    # Get snapshot IDs from available ami images
    ami_snapshots=$(aws ec2 describe-images --filters Name=state,Values=available --owners "$AWS_ACCOUNT_ID" --query "Images[].BlockDeviceMappings[].Ebs.SnapshotId" --output text --region "$REGION")

    echo "$snapshot_ids" | tr '\t' '\n' | sort > ./all_snapshots.txt
    echo "$ami_snapshots" | tr '\t' '\n' | sort | uniq > ./ami_snapshots.txt

    # Identify orphaned snapshots
    comm -23 ./all_snapshots.txt ./ami_snapshots.txt > ./delete_snapshots.txt
}

# Check if there are orphaned snapshots
check_orphaned_snapshots() {
    if [[ ! -s ./delete_snapshots.txt ]]; then
        echo "No orphaned snapshots found."
        exit 0
    fi
    echo -e "Following orphaned snapshots will be deleted:\n$(cat ./delete_snapshots.txt)\n"
}

# Deleting snapshots
delete_snapshot() {
    local snapshot_id=$1
    if aws ec2 delete-snapshot --snapshot-id "$snapshot_id" --region "$REGION"; then
        echo "Deleted snapshot: $snapshot_id"
    else
        echo "Failed to delete snapshot: $snapshot_id" >> ./failed_snapshots.txt
    fi
}

# Check deletion status of all snapshots
check_deletion_status() {
    if [[ -f ./failed_snapshots.txt ]]; then
        echo -e "\nSome snapshots failed to delete.Failed Snapshots are:"
        cat ./failed_snapshots.txt
    else
        echo "Successfully deleted all orphaned snapshots."
    fi
}

# Defining Main Function
main() {
    find_orphaned_snapshots
    check_orphaned_snapshots

    # Export necessary variables for parallel processing
    export -f delete_snapshot
    export REGION
    cat ./delete_snapshots.txt | xargs -P "$PARALLEL_DELETIONS" -I {} bash -c 'delete_snapshot "$@"' _ {}    
    check_deletion_status
}

# Calling Main Function
main
