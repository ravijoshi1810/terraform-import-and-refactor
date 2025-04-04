$global:TagRDSImported = $true
function TagRDS {
    param (
        [string[]]$rdsInstanceIds,
        [string]$awsRegion,
        [string]$awsAccountId,
        [string]$tagKey,
        [string]$tagValue,
        [string]$rdsRunningFile,
        [string]$rdsStoppedFile,
        [string]$statusUnknownFile,
        [string]$rdsFile
    )
    write-host "value for awsAccountId is $awsAccountId"
    foreach ($rdsInstanceId in $rdsInstanceIds) {
        $rdsStatus = aws rds describe-db-instances --db-instance-identifier $rdsInstanceId --query "DBInstances[*].DBInstanceStatus" --output text
        if ($rdsStatus -eq "available") {
            write-host debug awsregion and account id $awsRegion $awsAccountId
            aws rds add-tags-to-resource --resource-name arn:aws:rds:${awsRegion}:${awsAccountId}:db:${rdsInstanceId} --tags Key=$tagKey,Value=$tagValue
            "$awsAccountId,$rdsInstanceId,$rdsStatus,$tagKey=$tagValue" | Out-File -FilePath $rdsFile -Append
            "$awsAccountId,$rdsInstanceId,$rdsStatus,$tagKey=$tagValue" | Out-File -FilePath $rdsRunningFile -Append
        } elseif ($rdsStatus -eq "stopped") {
            aws rds add-tags-to-resource --resource-name arn:aws:rds:${awsRegion}:${awsAccountId}:db:${rdsInstanceId} --tags Key=$tagKey,Value=$tagValue
            "$awsAccountId,$rdsInstanceId,$rdsStatus,$tagKey=$tagValue" | Out-File -FilePath $rdsFile -Append
            "$awsAccountId,$rdsInstanceId,$rdsStatus,$tagKey=$tagValue" | Out-File -FilePath $rdsStoppedFile -Append
        } else {
            Write-Host "RDS instance $rdsInstanceId is in an unknown state: $rdsStatus. Logging to status unknown file."
            "$awsAccountId,$rdsInstanceId,$rdsStatus" | Out-File -FilePath $statusUnknownFile -Append
        }
    }
}
