function Send-File {

    

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]
        $File,

        [Parameter(Mandatory = $true)]
        [String]
        $RoomID,

        [Parameter(Mandatory = $true)]
        [String]
        $UploadURL
    )

    try {
        $null = Invoke-RestMethod $UploadUrl -ContentType "application/octet-stream" -Method Post -InFile $File.FullName -ErrorAction Stop
    }
    catch {
        throw
    }

    
    
    # Check, ob Datei vorhanden

    $parameter = @{
        "depth_level"   = "-1" #Bei der Einstellung -1 wird der ganze Ast ab der Stelle "parent_id" nach unten durchsucht
        "search_string" = $File.BaseName
        filter          = "type:eq:file"
        "parent_id"     = $RoomID #Das ist der Raum, in dem auf DRACOON die Testergebnisse abgelegt werden
    }

    $AccountUrl = $APIUrl + "/v4/nodes/search"
    try {
        $Response = Invoke-WebRequest -URI $AccountUrl -Method Get -ContentType "application/json" -Headers @{Authorization = ("Bearer {0}" -f $Token) } -Body $parameter -ErrorAction Stop
        $content = ConvertFrom-Json $Response.content -ErrorAction Stop
    }
    catch {
        throw
    }

    $inhalt = $content.items
    $status = @($inhalt).count

    switch ($status) {            

        0 {
            Write-PSFMessage -Level Warning -Message "FEHLER: Dokument $($File.FullName) konnte nicht hochgeladen werden!!" -Target $File
            throw "FEHLER: Dokument $($File.FullName) konnte nicht hochgeladen werden!!"
        }
        1 {
            Write-PSFMessage -Message "Dokument $($File.FullName) wurde erfolgreich hochgeladen!" -Target $File
        }
        2 {
            Write-PSFMessage -Level Host -Message "Dokument $($File.FullName) liegt doppelt vor! Bitte prüfen" -Target $File
        }             
        Default {
            Write-PSFMessage -Level Host -Message "Dokument $($File.FullName) liegt mehr als zwei mal vor! Bitte prüfen" -Target $File
        }            
    }

}
