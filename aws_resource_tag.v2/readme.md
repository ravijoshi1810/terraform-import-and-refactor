# AWS Resource Tagging Script

This PowerShell script, `aws_tag_main.ps1`, is designed to tag various AWS resources such as EC2 instances, RDS instances, ELBs, S3 buckets, and EKS clusters. It provides a streamlined way to manage and apply tags to AWS resources based on user-specified options.

## Features

- Tags AWS resources with a specified key-value pair.
- Supports tagging for:
    - EC2 instances
    - RDS instances
    - ELBs
    - S3 buckets
    - EKS clusters
- Automatically creates necessary folders and initializes output files.
- Logs tagged resources for easy tracking.
- Validates AWS CLI configuration and retrieves AWS account and region details.

## Prerequisites

1. **AWS CLI**: Ensure the AWS CLI is installed and configured with appropriate credentials and region.
2. **PowerShell**: The script is written in PowerShell and requires a compatible environment to execute.
3. **Resource Files**: The script expects text files containing resource identifiers (e.g., instance IDs, bucket names) in the same directory:
     - `ec2_instance_ids.txt`
     - `rds_instance_ids.txt`
     - `elb_names.txt`
     - `s3_buckets.txt`
     - `eks_clusters.txt`
     - `eks_node_instance_ids.txt`

## Usage

Run the script with one or more of the following switches to specify the resources to tag:

```powershell
./aws_tag_main.ps1 -TagEC2 -TagRDS -TagELB -TagS3 -TagEKS
```

### Parameters

- `-TagEC2`: Tags EC2 instances.
- `-TagRDS`: Tags RDS instances.
- `-TagELB`: Tags ELBs.
- `-TagS3`: Tags S3 buckets.
- `-TagEKS`: Tags EKS clusters.
- `-TagAll`: Tags all supported resources.

### Examples

To tag EC2 instances and RDS instances:

```powershell
./aws_tag_main.ps1 -TagEC2 -TagRDS
```

To tag all supported resources:

```powershell
./aws_tag_main.ps1 -TagAll
```

## Output

The script generates the following output files in their respective folders:

- `tagged_instances.csv`: Consolidated log of all tagged resources.
- `running_instances.csv`: Tagged EC2 instances in the running state.
- `stopped_instances.csv`: Tagged EC2 instances in the stopped state.
- `eks_node_file.csv`: Excluded EKS node instances.
- `rds_instances.csv`: Tagged RDS instances.
- `elb_instances.csv`: Tagged ELBs.
- `s3_buckets.csv`: Tagged S3 buckets.
- `eks_clusters.csv`: Tagged EKS clusters.
- `eks_nodes.csv`: Tagged EKS node instances.

## Script Workflow

1. **Parameter Validation**: Ensures at least one tagging option is specified.
2. **AWS Account and Region Retrieval**: Fetches the AWS account ID and region using the AWS CLI.
3. **Folder and File Initialization**: Creates necessary folders and initializes output files.
4. **Resource Tagging**: Calls individual tagging scripts (`ec2_tag.ps1`, `rds_tag.ps1`, etc.) to tag resources based on the specified switches.
5. **Logging**: Logs tagged resources into output files for tracking.

## Error Handling

- If no tagging option is specified, the script exits with an error.
- If AWS CLI is not configured correctly, the script exits with an error.
- If a required tagging script (e.g., `rds_tag.ps1`) fails to import, the script exits with an error.

## Dependencies

The script imports the following PowerShell scripts for tagging specific resources:

- `ec2_tag.ps1`
- `rds_tag.ps1`
- `elb_tag.ps1`
- `s3_tag.ps1`
- `eks_tag.ps1`

Ensure these scripts are present in the same directory as `aws_tag_main.ps1`.

## Notes

- The script uses the tag key `IACImported` with the value `No` by default. Modify these values in the script if needed.
- Ensure the text files containing resource identifiers are properly formatted, with one identifier per line.

## License

This script is provided as-is without any warranty. Use it at your own risk.