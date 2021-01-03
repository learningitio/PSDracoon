function Publish-DracoonDocument {
	[CmdletBinding(SupportsShouldProcess = $true)]
	Param (
		[String]$BaseURL = (Get-PSFConfigValue -FullName "PSDracoon.BaseURL"),

		[pscredential]$Credential = (Get-PSFConfigValue -FullName "PSDracoon.Credential"),

		[String]$ClientID = (Get-PSFConfigValue -FullName "PSDracoon.ClientID"),

		[String]$ClientSecret = (Get-PSFConfigValue -FullName "PSDracoon.ClientSecret"),

		[String]$RoomID = (Get-PSFConfigValue -FullName "PSDracoon.RoomID"),

		[String]$BasePath = (Get-PSFConfigValue -FullName "PSDracoon.BasePath"),

		[Switch]$EnableException
	)
	
	begin {

		$APIUrl = $BaseUrl + "/api"


		# Hier liegen die PDFs mit den Ergebnissen
		$ergebnisLocation = Join-Path -Path $BasePath -ChildPath "Ergebnisse"
		# CSV mit den Metadaten
		$Metadatendatei = Join-Path -Path $BasePath -ChildPath "Metadaten\Metadaten.csv" 
		# Report-CSV
		$csvreport = Join-Path -Path $BasePath -ChildPath "Report.csv"


		
		# Abholen des AnmeldeTokens
		try {
			$token = Get-Token -ClientID $ClientId -ClientSecret $ClientSecret -Credential $Credential -BaseURL $BaseURL
		}
		catch {
			Stop-PSFFunction -Message "Beim Abholen des Tokens ist ein Fehler aufgetreten" -ErrorRecord $_ -Cmdlet $PSCmdlet -EnableException $EnableException
			return   
		}
	}
	process {
		
		if (Test-PSFFunctionInterrupt) { return }

		# Import der PDF-Liste
		try {
			$PDFListe = Get-ChildItem -Path $ergebnisLocation -ErrorAction Stop
		}
		catch {
			Stop-PSFFunction -Message "Beim Abrufen der PDF-Liste ist ein Fehler aufgetreten" -ErrorRecord $_ -Cmdlet $PSCmdlet -EnableException $EnableException
			return
		}


		# Import der Metadaten
		try {
			$Metadata = Import-Csv -Path $Metadatendatei -Delimiter ";" -Encoding Default -ErrorAction Stop
		}
		catch {
			Stop-PSFFunction -Message "Beim Abrufen der Metadaten ist ein Fehler aufgetreten" -ErrorRecord $_ -Cmdlet $PSCmdlet -EnableException $EnableException
			return
		}

		# Zählvariable, die erfolgreich hochgeladene Files zählt
		$anzahl = 0

		# PDF-Freigabe für betroffene Personen
		foreach ($PDF in $PDFListe) {
			$PDFName = $PDF.BaseName
			$Person = $Metadata | Where-Object Testnummer -eq $PDFName
			if (-not $Person) { 
				Stop-PSFFunction -Message "Person nicht gefunden für: $($PDF.FullName)" -Cmdlet $PSCmdlet -EnableException $EnableException -Continue
			}

			# Oeffnen des UploadChannels
			Invoke-PSFProtectedCommand -Action "Oeffne Upload-Channel" -Target $PDF -ScriptBlock {
				$uploadURL = Open-UploadChannel -RoomID $RoomID -PDFName $PDFName -APIUrl $APIUrl -Token $Token
			} -PSCmdlet $PSCmdlet -EnableException $EnableException -Continue

			# Uploaden des Falls
			Invoke-PSFProtectedCommand -Action "Lade Dokument hoch" -Target $PDF -ScriptBlock {
				Send-File -File $PDF -RoomID $RoomID -UploadURL $uploadURL
			} -PSCmdlet $PSCmdlet -EnableException $EnableException -Continue
			
			# Schließen des Upload Channels
			Invoke-PSFProtectedCommand -Action "Schliesse Upload-Channel" -Target $PDF -ScriptBlock {
				$NodeID = Close-UploadChannel -UploadURL $UploadUrl
			} -PSCmdlet $PSCmdlet -EnableException $EnableException -Continue

			# Erstellen eines teilbaren Links mit PW (und Mail- und SMSVersand)
			Invoke-PSFProtectedCommand -Action "Sende SMS und Mail" -Target $PDF -ScriptBlock {
				Send-DownloadLink -APIUrl $APIUrl -Token $Token -Mobile $Person.Mobile -Mail $person.Mail -NodeID $NodeID 
			} -PSCmdlet $PSCmdlet -EnableException $EnableException -Continue

			$anzahl++
            

		}

		$report = [PSCustomObject]@{
			Datum        = get-date -Format dd/MM/yyyy
			Uhrzeit      = get-date -Format HH:mm:ss
			UploadAnzahl = $anzahl
		}

		if (-Not (Test-Path $csvreport)) {
			$report | export-csv -Path $csvreport
			Write-PSFMessage -Message "Report-CSV wurde erstellt"
		}
		else {
			$report | export-csv -Path $csvreport -Append
			Write-PSFMessage -Message "Report-CSV wurde ergänzt"
		}
	}

}
