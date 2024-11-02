```
# Script To Delete Orphaned Snapshots

This Bash script identifies and deletes orphaned Amazon EC2 snapshots in your AWS account. Orphaned snapshots are those that are not associated AMI's and are no longer needed.

## Features

- Finds all snapshots in the specified AWS account.
- Identifies which snapshots are orphaned (i.e., not linked to any available AMIs).
- Deletes orphaned snapshots in parallel for efficiency.
- Logs any failures during the deletion process.

## Prerequisites

- AWS CLI installed and configured with appropriate permissions to access EC2 resources.
- Bash shell environment.
- Basic understanding of shell scripting and AWS terminology.

## Variables

- `AWS_ACCOUNT_ID`: Automatically retrieved AWS account ID.
- `REGION`: AWS region to operate in (default: `us-west-2`).
- `PARALLEL_DELETIONS`: Number of snapshots to delete in parallel (default: `10`).

## Usage

1. Clone or download the script.
2. Make the script executable:
   ```bash
   chmod +x orphaned_snapshot_cleaner.sh
   ```
3. Run the script:
   ```bash
   ./orphaned_snapshot_cleaner.sh
   ```

## Temporary Files

The script creates temporary files for processing:
- `./all_snapshots.txt`: List of all snapshots.
- `./ami_snapshots.txt`: List of snapshot IDs associated with available AMIs.
- `./snapshots.txt`: List of orphaned snapshots.
- `./failed_snapshots.txt`: Logged failures during the deletion process.

These files are automatically deleted at the end of the script execution.

## Important Notes

- Use this script with caution. Deleting snapshots is irreversible.
- It is recommended to review the list of orphaned snapshots before deletion, which is displayed in the terminal.

## Author

[Karandeep Singh]
Reach To Me On Linkedin: www.linkedin.com/in/karandeep-singh-597519173
```
