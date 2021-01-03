function Send-DownloadLink
{
	[CmdletBinding()]
	param (
		[String]
        $APIUrl,
        
        [String]
        $Token,

        [String]
        $Mobile,

        [String]
        $Mail,

		[String]
		$NodeID
	)
    # Link und SMS
    $password = New-Password

    $parameter= @{
        showCreatorName = $true
        nodeId = $NodeID
        password = $password
        textMessageRecipients = @(
            $Mobile

        )   
    }

    # Erstelle Sharelink und Sende SMS
    try {
        $Response = Invoke-WebRequest -URI "$APIUrl/v4/shares/downloads" -Method Post -ContentType "application/json" -Headers @{Authorization=("Bearer {0}" -f $Token)} -Body (ConvertTo-Json $parameter) -ErrorAction Stop
        $content = ConvertFrom-Json $Response.content -ErrorAction Stop
        $LinkID = $content.id
    }
    catch {
        throw
    }
    Write-PSFMessage -Message "Der im System erzeugte Downloadlink hat die ID $LinkID und ist mit dem Passwort $password geschützt."


    # Mailnotification
    try {
        $null = Invoke-WebRequest -URI "$APIUrl/v4/user/subscriptions/download_shares/$LinkID" -Method Post -ContentType "application/json" -Headers @{Authorization=("Bearer {0}" -f $Token)} -ErrorAction Stop
    }
    catch {
        throw
    }

      
    # Mailversand
    $Parameter= @{
        body = "Powered by DRACOON - Entwickelt von Philip Lorenz"
        recipients = @(
            $Mail
        )   
    }

    $parameter = ConvertTo-Json -Depth 3 ($parameter)
    try {
        $null = Invoke-WebRequest -URI "$APIUrl/v4/shares/downloads/$LinkID/email" -Method Post -ContentType "application/json; charset=utf-8" -Headers @{Authorization=("Bearer {0}" -f $Token)} -Body $Parameter -ErrorAction Stop
    }
    catch {
        throw
    }
    Write-PSFMessage -Message "Es wurde eine Mail an $mail versendet."

}
