#######################################################
#                                                     #
# Erstellt von Christoph Dengler, Firma DRACOON       #
# Überarbeitet von Philip Lorenz (www.learning-it.io) #
#                                                     #
#######################################################


###############
# Static Vars #
###############

# Auf dem Filesystem
# Hier liegen die Logfiles
$logLocation = "C:\Corona_Use_Case\"
# Hier liegen die PDFs mit den Ergebnissen
$ergebnisLocation = "C:\Corona_Use_Case\Covid_Ergebnisse"
# CSV mit den Metadaten
$Metadatendatei = "C:\Corona_Use_Case\Covid_Metadaten\Metadaten.csv" 
# Bereits hochgeladene Dokumente
# $uploaded = "C:\Corona_Use_Case\versendeteDateien"
# Report-CSV
$csvreport = "C:\Corona_Use_Case\Report.csv"


# AuthInfos
$BaseUrl = "" # zum Beispiel: "https://123456.dracoon.cloud"
$APIUrl = $BaseUrl + "/api"
$TokenUrl = $BaseUrl + '/oauth/token'
$Username = ""
$Password = ""
$ClientId = ""
$ClientSecret = ""

# DracoonStuff
# Raum, der in DRACOON vorbereitet wurde
[String]$raumId = 9067


###############
# Functions   #
###############

<#
generateRandom
createLog
writeToLog
getToken
getErgebnisList
loadMetaData
openUploadChannel
uploadFile
closeUploadChannel
createShareLinkSMSandMail
#>

# Funktion:
# - Optischer Trenner für das Logfile
function logCutter($log) {
    writeToLog "#################################################################" $log
    writeToLog "#################################################################" $log
}


# Funktion:
# - Generiert Random Passwort für ShareLink
function generateRandom(){
    $Alphabets = 'a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z'
    $numbers = 0..9
    $specialCharacters = "!,#,),+,@,_"
    $array = @()
    $array += $Alphabets.Split(',') | Get-Random -Count 4
    $array[0] = $array[0].ToUpper()
    $array[-1] = $array[-1].ToUpper()
    $array += $numbers | Get-Random -Count 3
    $array += $specialCharacters.Split(',') | Get-Random -Count 3
    return ($array | Get-Random -Count $array.Count) -join ""
}

# Funktion:
# - Erstellt ein Logfile (eins pro Tag)
# - Gibt Pfad des Files zurück
# Übergabevariablen sind: 
# - logLocation: Ordner, in dem die LogFiles erstellt werden
function createLog([String]$logLocation){
    [String]$currentDate = get-date -Format yyyyMMdd
    $logFile = "Logfile" + $currentDate + ".log"
    $testPath = $logLocation + $logFile
    if (-Not (Test-Path $testPath)) {  
        New-Item -ItemType File -Path $logLocation -Name $logFile -Value "---BEGIN OF LOGFILE---`r`n"
    }
    else {
        Write-Host "Logfile fuer diesen Tag besteht bereits!" -ForegroundColor Green
    }
    $returnpath = ((Get-ChildItem C:\Corona_Use_Case\$logfile) | select *).FullName
    return $returnpath
}

# Funktion:
# - Schreibt in das LogFile 
# Übergabevariablen sind: 
# - logText: Text der geschrieben werden soll
# - logFile: Location des Logfiles (Rückgabewert von Fkt createLog)
function writeToLog([String]$logText, [String]$log){
    [String]$logTime = get-date -Format HH:mm:ss
    $logText = $logTime + "    " + $logText 
    $count1 = $error.count
    try {
        Add-Content $log -Value $logText -ErrorAction Ignore
    } 
    catch {
        Add-Content $log -Value $logText -ErrorAction Ignore
    }

    $count2 = $error.count

    if ($count1 -eq 0 -and $count2 -gt 0){
        $error.clear()
    }

    Write-Host $logText
}

# Funktion:
# - oAuth Authentifizierung - gibt anschließend den Token zurück
# Übergabevariablen sind: 
# - clientID
# - clientSecret
# - username
# - password
# - TokenUrl
# - TokenUrl
# - logFile: Location des Logfiles (Rückgabewert von Fkt createLog)
function getToken([String]$clientID, [String]$clientSecret, [String]$username, [String]$password, [String]$TokenUrl, [String]$log){
    # Login über OAuth
    $Base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $ClientId,$ClientSecret)))
 
    $Body = @{
        "grant_type" = "password" 
        "username" = $Username
        "password" = $Password 
    }

    $Response = Invoke-WebRequest -URI $TokenUrl -Method Post -ContentType "application/x-www-form-urlencoded" -Body $Body -Headers @{Authorization=("Basic {0}" -f $Base64AuthInfo)}
    [String]$Status = $response.StatusCode
    $Status = $Status.Remove(1,2)
    $Content = ConvertFrom-Json $Response.content
    $Token = $Content.access_token #Der Zugriffstoken, mit dem alle folgenden Aktionen auf DRACOON ausgeführt werden, wird in die Variable $Token gespeichert
    Write-Host "$log" -ForegroundColor Green
    switch($status){            
            
        1 {
            writeToLog "getToken: HTTP Status: informational response – the request was received, continuing process" $log
        }
        2 {
            writeToLog "getToken: HTTP Status: successful – the request was successfully received, understood, and accepted" $log
        }   
        3 {
            writeToLog "getToken: HTTP Status: redirection – further action needs to be taken in order to complete the request" $log
        }   
        4 {
            writeToLog "getToken: HTTP Status: client error – the request contains bad syntax or cannot be fulfilled" $log
        }   
        5 {
            writeToLog "getToken: HTTP Status: server error – the server failed to fulfil an apparently valid request" $log
        } 
                      
        Default {
            writeToLog "getToken: HTTP Status: UNKNOWN ERROR!" $log
        }            
    }  
    
    return $Token
}

# Funktion:
# - Holt sich Filenames der Ergebnisse
# Übergabevariablen sind: 
# - ergebnisLocation
function getErgebnisList([String]$ergebnisLocation, [String]$logLocation, [String]$log){
   $ergebnisPDFListe = (Get-ChildItem $ergebnisLocation).Name
   writeToLog "Liste mit den Ergebnis PDFs geladen" $log
   return $ergebnisPDFListe
}

# Funktion:
# - Importiert die Metadaten
# - Gibt Metadaten als Array zurück
# Übergabevariablen sind: 
# - Metadatendatei
# - logLocation
function loadMetaData([String]$Metadatendatei, [String]$logLocation, [String]$log){
    $Metadaten = Import-Csv $Metadatendatei -Delimiter ';' -Encoding Default
    writeToLog "CSV mit den Metadaten importiert" $log
    return $Metadaten
}

# Funktion:
# - Öffnet den Uploadchannel
# - Gibt Upload URL zurück
# Übergabevariablen sind: 
# - raumID
# - PDFName
# - APIUrl
# - AccountUrl
# - Token
# - Logfile
function openUploadChannel([String] $raumID, [String]$PDFName, [String] $APIUrl, [String]$Token, [String]$Logfile) {
    $Parameter= @{
        "parentId" = $RaumId 
        "name"     = $PDFName
    }
    $Response = $null
    $AccountUrl = $APIUrl + "/v4/nodes/files/uploads"
    $Response = Invoke-WebRequest -URI $AccountUrl -Method Post -ContentType "application/json" -Headers @{Authorization=("Bearer {0}" -f $Token)} -Body (convertTo-Json $Parameter)
    $content = ConvertFrom-Json $Response.content
    $uploadUrl = $content.uploadUrl
    $uploadId = $content.uploadID    
    
    [String]$Status = $response.StatusCode
    $Status = $Status.Remove(1,2)

    switch($status){            
            
        1 {
            writeToLog "openUploadChannel: HTTP Status: informational response – the request was received, continuing process" $Logfile
        }
        2 {
            writeToLog "openUploadChannel: HTTP Status: successful – the request was successfully received, understood, and accepted" $Logfile
        }   
        3 {
            writeToLog "openUploadChannel: HTTP Status: redirection – further action needs to be taken in order to complete the request" $Logfile
        }   
        4 {
            writeToLog "openUploadChannel: HTTP Status: client error – the request contains bad syntax or cannot be fulfilled" $Logfile
        }   
        5 {
            writeToLog "openUploadChannel: HTTP Status: server error – the server failed to fulfil an apparently valid request" $Logfile
        } 
                      
        Default {
            writeToLog "openUploadChannel: HTTP Status: UNKNOWN ERROR!" $Logfile
        }            
    } 

    return $content.uploadUrl
   
}

# Funktion:
# - Lädt die gewählte Datei hoch
# - Gibt Boolean zurück, ob File erfolgreich hochgeladen
# Übergabevariablen sind: 
# - ergebnisLocation
# - PDFName
# - uploadURL
# - Logfile
function uploadFile([String]$ergebnisLocation, [String]$PDFName, [String]$uploadURL, [String]$Logfile) {

    $fullFilePath = $ergebnisLocation + $PDF.Name
    $result = Invoke-RestMethod $uploadUrl -ContentType "application/octet-stream" -Method Post -InFile "C:\Corona_Use_Case\Covid_Ergebnisse\$PDFName.pdf"
    
    
    # Check, ob Datei vorhanden

    $parameter= @{
        "depth_level" = "-1" #Bei der Einstellung -1 wird der ganze Ast ab der Stelle "parent_id" nach unten durchsucht
        "search_string" = $PDFName
        filter = "type:eq:file"
        "parent_id" = $RaumId #Das ist der Raum, in dem auf DRACOON die Testergebnisse abgelegt werden
    }


    $AccountUrl = $APIUrl + "/v4/nodes/search"
    $Response = Invoke-WebRequest -URI $AccountUrl -Method Get -ContentType "application/json" -Headers @{Authorization=("Bearer {0}" -f $Token)} -Body $parameter 
    $content = ConvertFrom-Json $Response.content
    $inhalt = $content.items

    $status = $inhalt.count

        switch($status){            

            0 {
                writeToLog "uploadFile: FEHLER: File $PDFName konnte nicht hochgeladen werden!!" $Logfile
                exit
            }
   
            1 {
                writeToLog "uploadFile: Die PDF $PDFName wurde erfolgreich hochgeladen!" $Logfile
            }
            2 {
                writeToLog "uploadFile: Die PDF $PDFName liegt doppelt vor! Bitte prüfen" $Logfile
            }             
            Default {
                writeToLog "uploadFile: Die PDF $PDFName liegt mehr als zwei mal vor! Bitte prüfen" $Logfile
            }            
 
        }

}

# Funktion:
# - Schliesst den Upload Channel
# - Gibt FileID zurück
# Übergabevariablen sind: 
# - UploadUrl
# - Logfile
function closeUploadChannel([String]$UploadUrl, [String]$Logfile) {
    $Parameter= @{
        "resolutionStrategy" = "overwrite"
    }

    $Response = Invoke-WebRequest -URI $UploadUrl -Method Put -ContentType "application/json"  -Body (convertTo-Json $Parameter)
    $File =  ConvertFrom-Json $Response.content
    $NodeID = $File.id
    writeToLog "Die Datei wurde als neuer Knoten mit der ID $NodeID angelegt." $log

    return $NodeID

}

# Funktion:
# - Erzeugt einen teilbaren Link mit Passwortschutz
# - Sendet SMS mit PW an getestete Person
# - Sendet Mail mit Link zum PDF an getestete Person
# Übergabevariablen sind: 
# - Metadaten
# - APIUrl
# - logFile
# - FileID
function createShareLinkSMSandMail([Array]$Metadaten, [String]$APIUrl, [String]$logFile, [String]$FileID) {
    # Link und SMS
    $password = generateRandom

    $parameter= @{
                showCreatorName = $true
        nodeId = $NodeID
        password = $password
        textMessageRecipients = @(
            $Person.Mobil
        )   
    }

    # Erstelle Sharelink und Sende SMS
    $AccountURL = $APIUrl + "/v4/shares/downloads"
    $Response = Invoke-WebRequest -URI $AccountUrl -Method Post -ContentType "application/json" -Headers @{Authorization=("Bearer {0}" -f $Token)} -Body (ConvertTo-Json $parameter) 

    #Informationen für Log aus Response lesen
    $content = ConvertFrom-Json $Response.content
    $LinkID = $content.id

    writeToLog "Der im System erzeugte Downloadlink hat die ID $LinkID und ist mit dem Passwort $password geschützt." $logFile

    #Hier muss jetzt der Downloadshare noch mit der Mailnotification versorgt werden
    $AccountURL = $APIUrl + "/v4/user/subscriptions/download_shares/" + $LinkID
    $Response = Invoke-WebRequest -URI $AccountUrl -Method Post -ContentType "application/json" -Headers @{Authorization=("Bearer {0}" -f $Token)}
      
    # Mailversand
    $mail = $Person.Mail
    $Parameter= @{
        body = "Powered by DRACOON - Entwiäöckelt von Christoph Dengler"
        recipients = @(
            $mail
        )   
    }

    $AccountURL = $APIUrl + "/v4/shares/downloads/" +$LinkID + "/email"
    $parameter = ConvertTo-Json -Depth 3 ($parameter)
    $Response = Invoke-WebRequest -URI $AccountUrl -Method Post -ContentType "application/json; charset=utf-8" -Headers @{Authorization=("Bearer {0}" -f $Token)} -Body $Parameter
    writeToLog "Es wurde eine Mail an $mail versendet." $log

}





###############
# LOGIX       #
###############


# Erstellen der LogDatei
try {
    $log = createLog $logLocation
}
catch {
    writeToLog "Beim Anlegen des LogFiles ist ein Fehler aufgetreten: $_.Exception.Message" $log
    exit
}

# Log Cutten
 logCutter $log

# Casen eines Powershell Bugs
$logtype = ($log.GetType()).Name
if ($logtype -eq "String"){}
if ($logtype -eq "Object[]"){
    $log = $log.Fullname
}

# Abholen des AnmeldeTokens
try {
    $token = getToken $ClientId $ClientSecret $Username $Password $TokenUrl $log
}
catch {
    writeToLog "Beim Abholen des Tokens ist ein Fehler aufgetreten: $_.Exception.Message" $log
    exit   
}

# Import der PDF-Liste
try {
    $PDFListe = getErgebnisList $ergebnisLocation $logLocation $log
}
catch {
    writeToLog "Beim Abrufen der PDF-Liste ist ein Fehler aufgetreten: $_.Exception.Message" $log
    exit
}


# Import der Metadaten
try {
    $Metadata = loadMetaData $Metadatendatei $logLocation $log
}
catch {
    writeToLog "Beim Abrufen der Metadaten ist ein Fehler aufgetreten: $_.Exception.Message" $log
    exit
}

# Zählvariable, die erfolgreich hochgeladene Files zählt
$anzahl = 0

# PDF-Freigabe für betroffene Personen
foreach ($PDF in $PDFListe){
    $PDFName = $PDF.Replace(".pdf","")
    foreach ($Person in $Metadata){
        if ($PDFName -eq $Person.Testnummer){
            # Oeffnen des UploadChannels
            try {
                $uploadURL = openUploadChannel $raumID $PDFName $APIUrl $Token $log
            }
            catch {
                 writeToLog "Beim Öffnen des Upload-Channels ist ein Fehler aufgetreten: $_.Exception.Message" $log
                 exit 
            }
            # Uploaden des Falls
            try {
                uploadFile $ergebnisLocation $PDFName $uploadURL $log
            }
            catch {
                writeToLog "Beim Hochladen des Testergebnisses $PDFName ist ein Fehler aufgetreten: $_.Exception.Message" $log
                exit
            }
            # Schließen des Upload Channels
            try {
                $NodeID = closeUploadChannel $UploadUrl $log
            }
            catch {
                writeToLog "Beim Schließen des UploadChannels ist ein Fehler aufgetreten: $_.Exception.Message" $log
                exit  
            }

            # Verschieben der hochgeladenen Datei
            #$currentPDFPath = "C:\Corona_Use_Case\Covid_Ergebnisse" + "\" + $PDF
            #Move-Item -Path $currentPDFPath -Destination $uploaded

            # Erstellen eines teilbaren Links mit PW (und Mail- und SMSVersand)
            try{
                createShareLinkSMSandMail $Metadaten $APIUrl $log $NodeID
            }
            catch {
                writeToLog "Beim Öffnen des Upload-Channels ist ein Fehler aufgetreten: $_.Exception.Message" $log
                exit 
            }

            $anzahl++
            
        }
    }
}

# Check der Error-Var
if ($error.count -gt 0){
    writeToLog "Diese(r) Fehler sind aufgetreten: $error" $log
}


# Update der Report-CSV
[String]$logDate = get-date -Format dd/MM/yyyy
[String]$logTime = get-date -Format HH:mm:ss


$object = New-Object psobject
$object | Add-Member NoteProperty Datum $logDate
$Object | Add-Member NoteProperty Uhrzeit $logTime
$Object | Add-Member NoteProperty UploadAnzahl $anzahl
$report = $object


if (-Not (Test-Path $csvreport)){
    $report | export-csv -Path $csvreport
    writeToLog "Report-CSV wurde erstellt" $log
}
else {
    $report | export-csv -Path $csvreport -Append
    writeToLog "Report-CSV wurde ergänzt" $log
}


