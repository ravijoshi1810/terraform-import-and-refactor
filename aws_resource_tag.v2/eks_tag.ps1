param (
    [string[]]$eksClusters,
    [string[]]$eksNodeInstanceIds,
    [string]$awsAccountId,
    [string]$tagKey,
    [string]$tagValue,
    [string]$eksClustersFile,
    [string]$eksNodesFile
)

function TagEKS {
    param (
        [string[]]$eksClusters,
        [string[]]$eksNodeInstanceIds,
        [string]$awsAccountId,
        [string]$tagKey,
        [string]$tagValue,
        [string]$eksClustersFile,
        [string]$eksNodesFile
    )
    foreach ($eksCluster in $eksClusters) {
        aws eks tag-resource --resource-arn arn:aws:eks:{$awsRegion}:$awsAccountId:cluster/$eksCluster --tags Key=$tagKey,Value=$tagValue
        "$awsAccountId,$eksCluster,$tagKey=$tagValue" | Out-File -FilePath $eksClustersFile -Append
    }
    
    foreach ($eksNodeInstanceId in $eksNodeInstanceIds) {
        aws ec2 create-tags --resources $eksNodeInstanceId --tags Key=$tagKey,Value=$tagValue
        "$awsAccountId,$eksNodeInstanceId,$tagKey=$tagValue" | Out-File -FilePath $eksNodesFile -Append
    }
}
