function Close-UploadChannel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $UploadUrl
    )
    
    $Parameter = @{
        "resolutionStrategy" = "overwrite"
    }

    try {
        $Response = Invoke-WebRequest -URI $UploadUrl -Method Put -ContentType "application/json"  -Body (convertTo-Json $Parameter) -ErrorAction Stop
        $File = ConvertFrom-Json $Response.content -ErrorAction Stop
    }
    catch {
        throw
    }

    $NodeID = $File.id
    Write-PSFMessage -Message "Die Datei wurde als neuer Knoten mit der ID $NodeID angelegt."

    $NodeID

}
