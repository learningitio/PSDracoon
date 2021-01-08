function Open-UploadChannel
{
    <#
    .SYNOPSIS
    Opens Upload-Channel.
    
    .DESCRIPTION
    Opens Upload-Channel.
    
    .PARAMETER RoomID
    Online Space which will be used.
    
    .PARAMETER PDFName
    PDF which will be uploaded
    
    .PARAMETER APIUrl
    Base URL + "/api" -> Auto generated
    
    .PARAMETER Token
    Auth Token generated with Get-Token
    
    .EXAMPLE
    Open-UploadChannel -RoomID $RoomID -PDFName $PDFName -APIUrl $APIUrl -Token $Token
    
    Opens Uploadchannel with mandatory parameters.
    #>
	[CmdletBinding()]
	param (
        [Parameter(Mandatory = $true)]
		[String]
		$RoomID,

        [Parameter(Mandatory = $true)]
		[String]
		$PDFName,

        [Parameter(Mandatory = $true)]
		[String]
		$APIUrl,

        [Parameter(Mandatory = $true)]
		[String]
		$Token
	)
    $Parameter= @{
        "parentId" = $RoomID
        "name"     = $PDFName
    }
    $Response = $null
    $AccountUrl = $APIUrl + "/v4/nodes/files/uploads"
    try {
        $Response = Invoke-WebRequest -URI $AccountUrl -Method Post -ContentType "application/json" -Headers @{Authorization=("Bearer {0}" -f $Token)} -Body (convertTo-Json $Parameter) -ErrorAction Stop
    }
    catch {
        throw
    }

    $content = ConvertFrom-Json $Response.content
    
    [String]$Status = $response.StatusCode
    $Status = $Status.Remove(1,2)

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

    if (-not $content.uploadUrl){
        throw "No Upload-URL received"
    }

    $content.uploadUrl
   
}
