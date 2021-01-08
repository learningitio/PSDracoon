function Send-DownloadLink
{
    <#
    .SYNOPSIS
    Shares uploaded file.
    
    .DESCRIPTION
    Uses New-Password for receiving random password.
    Sends Mail with sharelink to recipient.
    Send SMS with password to file to recipient.
    
    .PARAMETER APIUrl
    Base URL + "/api" -> Auto generated
    
    .PARAMETER Token
    Auth Token generated with Get-Token
    
    .PARAMETER Mobil
    Recipient mobile number imported from metadata
    
    .PARAMETER Mail
    Recipient mail imported from metadata.
    
    .PARAMETER NodeID
    NodeID generated after closing UploadChannel
    
    .EXAMPLE
    Send-DownloadLink -APIUrl $APIUrl -Token $Token -Mobil $Person.Mobil -Mail $person.Mail -NodeID $NodeID
    
    Sends DL-Link with mandatory parameters.
    #>
	[CmdletBinding()]
	param (
		[String]
        $APIUrl,
        
        [String]
        $Token,

        [String]
        $Mobil,

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
            $Mobil

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
