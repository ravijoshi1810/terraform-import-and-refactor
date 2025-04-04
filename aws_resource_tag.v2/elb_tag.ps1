param (
    [string[]]$elbNames,
    [string]$awsAccountId,
    [string]$tagKey,
    [string]$tagValue,
    [string]$elbFile
)

function TagELB {
    param (
        [string[]]$elbNames,
        [string]$awsAccountId,
        [string]$tagKey,
        [string]$tagValue,
        [string]$elbFile
    )
    foreach ($elbName in $elbNames) {
        aws elb add-tags --load-balancer-names $elbName --tags Key=$tagKey,Value=$tagValue
        "$awsAccountId,$elbName,$tagKey=$tagValue" | Out-File -FilePath $elbFile -Append
    }
}
