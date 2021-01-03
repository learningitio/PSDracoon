function writeToLog
{
	[CmdletBinding()]
	param (
		[String]
		$LogText,

		[String]
		$log
	)
    [String]$logTime = get-date -Format HH:mm:ss
    $LogText = $logTime + "    " + $LogText 
    $count1 = $error.count
    try {
        Add-Content $log -Value $LogText -ErrorAction Ignore
    } 
    catch {
        Add-Content $log -Value $LogText -ErrorAction Ignore
    }

    $count2 = $error.count

    if ($count1 -eq 0 -and $count2 -gt 0){
        $error.clear()
    }

    Write-Host $LogText
}
