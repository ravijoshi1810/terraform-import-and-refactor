param (
    [string[]]$s3Buckets,
    [string]$awsAccountId,
    [string]$tagKey,
    [string]$tagValue,
    [string]$s3File
)

function TagS3 {
    param (
        [string[]]$s3Buckets,
        [string]$awsAccountId,
        [string]$tagKey,
        [string]$tagValue,
        [string]$s3File
    )
    foreach ($s3Bucket in $s3Buckets) {
        aws s3api put-bucket-tagging --bucket $s3Bucket --tagging "TagSet=[{Key=$tagKey,Value=$tagValue}]"
        "$awsAccountId,$s3Bucket,$tagKey=$tagValue" | Out-File -FilePath $s3File -Append
    }
}
