function Get-Token
{
    <#
    .SYNOPSIS
    Requests a token from Dracoon API
    
    .DESCRIPTION
    Requests an authentication token by Calling Dracoon API (HTTP-Post)
    
    .PARAMETER ClientID
    Client ID of user
    
    .PARAMETER ClientSecret
    Client Secret of user
    
    .PARAMETER Credential
    User Credential
    
    .PARAMETER BaseURL
    URI of Dracoon Tenant
    
    .EXAMPLE
    Get-Token -ClientID $ClientId -ClientSecret $ClientSecret -Credential $Credential -BaseURL $BaseURL

    Receives token with mandatory parameters.
    #>
	[CmdletBinding()]
	param (
        [Parameter(Mandatory = $true)]
		[String]
		$ClientID,

        [Parameter(Mandatory = $true)]
		[String]
		$ClientSecret,

        [Parameter(Mandatory = $true)]
		[PSCredential]
		$Credential,

        [Parameter(Mandatory = $true)]
		[String]
		$BaseUrl

    )
    $TokenUrl = $BaseUrl + '/oauth/token'
    # Login über OAuth
    $Base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $ClientId,$ClientSecret)))
 
    $Body = @{
        "grant_type" = "password"
        "username" = $Credential.Username
        "password" = $Credential.GetNetworkCredential().Password
    }
    
    try {
        $Response = Invoke-WebRequest -URI $TokenUrl -Method Post -ContentType "application/x-www-form-urlencoded" -Body $Body -Headers @{Authorization=("Basic {0}" -f $Base64AuthInfo)} -ErrorAction Stop
    }
    catch {throw}

    [String]$Status = $response.StatusCode
    $Status = $Status.Remove(1,2)
    $Content = ConvertFrom-Json $Response.content
    $Token = $Content.access_token #Der Zugriffstoken, mit dem alle folgenden Aktionen auf DRACOON ausgeführt werden, wird in die Variable $Token gespeichert
    switch($status){
            
        1 {
            Write-PSFMessage -Message "HTTP Status: informational response – the request was received, continuing process"
        }
        2 {
            Write-PSFMessage -Message "HTTP Status: successful – the request was successfully received, understood, and accepted"
        }
        3 {
            Write-PSFMessage -Level Warning -Message "HTTP Status: redirection – further action needs to be taken in order to complete the request"
        }
        4 {
            Write-PSFMessage -Level Warning -Message "HTTP Status: client error – the request contains bad syntax or cannot be fulfilled"
        }
        5 {
            Write-PSFMessage -Level Warning -Message "HTTP Status: server error – the server failed to fulfil an apparently valid request"
        }
                      
        Default {
            Write-PSFMessage -Level Warning -Message "HTTP Status: UNKNOWN ERROR!"
        }
    }

    if (-not $Token){
        throw "no Token received"
    }
    
    $Token
}
