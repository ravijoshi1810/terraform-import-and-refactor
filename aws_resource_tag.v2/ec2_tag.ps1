function TagEC2 {
    param (
        [string[]]$instanceIds,
        [string]$awsAccountId,
        [string]$tagKey,
        [string]$tagValue,
        [string]$outputFile,
        [string]$runningFile,
        [string]$stoppedFile,
        [string]$eksNodeFile
    )
    foreach ($instanceId in $instanceIds) {
        $instanceState = aws ec2 describe-instances --instance-ids $instanceId --query "Reservations[*].Instances[*].State.Name" --output text
        $instanceName = aws ec2 describe-instances --instance-ids $instanceId --query "Reservations[*].Instances[*].Tags[?Key=='Name'].Value" --output text
        
        if ($instanceState -eq "running") {
            aws ec2 create-tags --resources $instanceId --tags Key=$tagKey,Value=$tagValue
            "$awsAccountId,$instanceId,$instanceName,$instanceState,$tagKey=$tagValue" | Out-File -FilePath $outputFile -Append
            "$awsAccountId,$instanceId,$instanceName,$instanceState,$tagKey=$tagValue" | Out-File -FilePath $runningFile -Append
        } elseif ($instanceState -eq "stopped") {
            aws ec2 create-tags --resources $instanceId --tags Key=$tagKey,Value=$tagValue
            "$awsAccountId,$instanceId,$instanceName,$instanceState,$tagKey=$tagValue" | Out-File -FilePath $outputFile -Append
            "$awsAccountId,$instanceId,$instanceName,$instanceState,$tagKey=$tagValue" | Out-File -FilePath $stoppedFile -Append
        } elseif ($instanceState -eq "terminated") {
            Write-Host "Instance $instanceId is terminated. Skipping."
        } else {
            Write-Host "Instance $instanceId is in an unknown state: $instanceState. Logging to EKS node file."
            "$awsAccountId,$instanceId,$instanceName,$instanceState,$tagKey=$tagValue" | Out-File -FilePath $eksNodeFile -Append
        }
    }
}
