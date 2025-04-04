param (
    [switch]$TagEC2,
    [switch]$TagRDS,
    [switch]$TagELB,
    [switch]$TagS3,
    [switch]$TagEKS,
    [switch]$TagAll
)

# Function to check if any of the specific tagging switches or the 'TagAll' switch is provided
function IsTaggingRequested {
    param (
        [switch]$TagEC2,
        [switch]$TagRDS,
        [switch]$TagELB,
        [switch]$TagS3,
        [switch]$TagEKS,
        [switch]$TagAll
    )
    return $TagEC2 -or $TagRDS -or $TagELB -or $TagS3 -or $TagEKS -or $TagAll
}

# Validate the parameters
if (-not (IsTaggingRequested -TagEC2 $TagEC2 -TagRDS $TagRDS -TagELB $TagELB -TagS3 $TagS3 -TagEKS $TagEKS -TagAll $TagAll)) {
    Write-Error "No tagging option specified. Please specify at least one of -TagEC2, -TagRDS, -TagELB, -TagS3, -TagEKS, or -TagAll."
    exit 2
}

try {
    # Retrieve the AWS account ID
    $awsAccountId = aws sts get-caller-identity --query 'Account' --output text
    Write-Host "AWS Account ID: $awsAccountId"
} catch {
    Write-Error "Failed to retrieve AWS account ID. Ensure AWS CLI is configured correctly."
    exit 1
}

try {
    # Retrieve the AWS region
    $awsRegion = aws configure get region
    Write-Host "AWS Region: $awsRegion"
} catch {
    Write-Error "Failed to retrieve AWS region. Ensure AWS CLI is configured correctly."
    exit 1
}

# Define the path to the text file with instance IDs
$instanceIdsFile = ".\ec2_instance_ids.txt"
$rdsInstanceIdsFile = ".\rds_instance_ids.txt"
$elbNamesFile = ".\elb_names.txt"
$s3BucketsFile = ".\s3_buckets.txt"
$eksClustersFile = ".\eks_clusters.txt"
$eksNodeInstanceIdsFile = ".\eks_node_instance_ids.txt"

$tagKey = "IACImported"
$tagValue = "No"

# Read instance IDs from the file, ensuring each line is treated as a separate ID
$instanceIds = if (Test-Path -Path $instanceIdsFile) { Get-Content -Path $instanceIdsFile | ForEach-Object { $_.Trim() } } else { @() }
$rdsInstanceIds = if (Test-Path -Path $rdsInstanceIdsFile) { Get-Content -Path $rdsInstanceIdsFile | ForEach-Object { $_.Trim() } } else { @() }
$elbNames = if (Test-Path -Path $elbNamesFile) { Get-Content -Path $elbNamesFile | ForEach-Object { $_.Trim() } } else { @() }
$s3Buckets = if (Test-Path -Path $s3BucketsFile) { Get-Content -Path $s3BucketsFile | ForEach-Object { $_.Trim() } } else { @() }
$eksClusters = if (Test-Path -Path $eksClustersFile) { Get-Content -Path $eksClustersFile | ForEach-Object { $_.Trim() } } else { @() }
$eksNodeInstanceIds = if (Test-Path -Path $eksNodeInstanceIdsFile) { Get-Content -Path $eksNodeInstanceIdsFile | ForEach-Object { $_.Trim() } } else { @() }

# Define folders for running, stopped instances, and excluded EKS nodes
$runningFolder = ".\ec2_tagging_4import\ec2_running_status"
$stoppedFolder = ".\ec2_tagging_4import\ec2_stopped_status"
$eksNodeFolder = ".\ec2_tagging_4import\eks_node_excluded"
$rdsFolder = ".\rds_tagging_4import"
$elbFolder = ".\elb_tagging_4import"
$s3Folder = ".\s3_tagging_4import"
$eksFolder = ".\eks_tagging_4import"

$outputFile = ".\tagged_instances.csv"

# Define files for running, stopped instances, and EKS nodes
$runningFile = "$runningFolder\running_instances.csv"
$stoppedFile = "$stoppedFolder\stopped_instances.csv"
$eksNodeFile = "$eksNodeFolder\eks_node_file.csv"
$rdsFile = "$rdsFolder\rds_instances.csv"
$rdsRunningFile = "$rdsFolder\rds_running_instances.csv"
$rdsStoppedFile = "$rdsFolder\rds_stopped_instances.csv"
$rdsStatusUnknownFile = "$rdsFolder\rds_unknown.csv"
$elbFile = "$elbFolder\elb_instances.csv"
$s3File = "$s3Folder\s3_buckets.csv"
$eksClustersFile = "$eksFolder\eks_clusters.csv"
$eksNodesFile = "$eksFolder\eks_nodes.csv"

# Create folders if they don't exist
function CreateFolder {
    param (
        [string]$folderPath
    )
    if (-Not (Test-Path -Path $folderPath)) {
        New-Item -ItemType Directory -Path $folderPath
        Write-Host "Created folder: $folderPath"
    } else {
        Write-Host "Folder already exists: $folderPath"
    }
}

CreateFolder -folderPath $runningFolder
CreateFolder -folderPath $stoppedFolder
CreateFolder -folderPath $eksNodeFolder
CreateFolder -folderPath $rdsFolder
CreateFolder -folderPath $elbFolder
CreateFolder -folderPath $s3Folder
CreateFolder -folderPath $eksFolder

# Initialize the output files
function InitializeFile {
    param (
        [string]$filePath,
        [string]$header
    )
    $header | Out-File -FilePath $filePath -Force
    Write-Host "Initialized file: $filePath"
}

InitializeFile -filePath $outputFile -header "AWS Account ID,Instance ID,Name,State,Tag"
InitializeFile -filePath $runningFile -header "AWS Account ID,Instance ID,Name,State,Tag"
InitializeFile -filePath $stoppedFile -header "AWS Account ID,Instance ID,Name,State,Tag"
InitializeFile -filePath $eksNodeFile -header "AWS Account ID,Instance ID,Name,State,Tag"
InitializeFile -filePath $rdsFile -header "AWS Account ID,Instance ID,Name,State,Tag"
InitializeFile -filePath $rdsRunningFile -header "AWS Account ID,Instance ID,Name,State,Tag"
InitializeFile -filePath $rdsStoppedFile -header "AWS Account ID,Instance ID,Name,State,Tag"
InitializeFile -filePath $rdsStatusUnknownFile -header "AWS Account ID,Instance ID,Status"
InitializeFile -filePath $elbFile -header "AWS Account ID,ELB Name,Tag"
InitializeFile -filePath $s3File -header "AWS Account ID,Bucket Name,Tag"
InitializeFile -filePath $eksClustersFile -header "AWS Account ID,Cluster Name,Tag"
InitializeFile -filePath $eksNodesFile -header "AWS Account ID,Node Instance ID,Tag"

# Import AWS service tagging scripts
. .\ec2_tag.ps1
. .\rds_tag.ps1
if (-not $global:TagRDSImported) {
    Write-Error "Failed to import TagRDS.ps1."
    exit 1
}
. .\elb_tag.ps1
. .\s3_tag.ps1
. .\eks_tag.ps1

# Tag and log resources if requested
if ($TagEC2 -or $TagAll) {
    TagEC2 -instanceIds $instanceIds -awsAccountId $awsAccountId -tagKey $tagKey -tagValue $tagValue -outputFile $outputFile -runningFile $runningFile -stoppedFile $stoppedFile -eksNodeFile $eksNodeFile
}

if ($TagRDS -or $TagAll) {
     write-host "value for awsAccountId is $awsAccountId $awsAccountId"
     write-host "value for awsRegion is $awsRegion"
    TagRDS -rdsInstanceIds $rdsInstanceIds -awsRegion $awsRegion -awsAccountId $awsAccountId -tagKey $tagKey -tagValue $tagValue -rdsRunningFile $rdsRunningFile -rdsStoppedFile $rdsStoppedFile -statusUnknownFile $rdsStatusUnknownFile -rdsFile $rdsFile

}

if ($TagELB -or $TagAll) {
    TagELB -elbNames $elbNames -awsAccountId $awsAccountId -tagKey $tagKey -tagValue $tagValue -elbFile $elbFile
}

if ($TagS3 -or $TagAll) {
    TagS3 -s3Buckets $s3Buckets -awsAccountId $awsAccountId -tagKey $tagKey -tagValue $tagValue -s3File $s3File
}

if ($TagEKS -or $TagAll) {
    TagEKS -eksClusters $eksClusters -eksNodeInstanceIds $eksNodeInstanceIds -awsAccountId $awsAccountId -tagKey $tagKey -tagValue $tagValue -eksClustersFile $eksClustersFile -eksNodesFile $eksNodesFile
}

Write-Host "Tagging operation completed."
