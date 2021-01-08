function Publish-DracoonDocument {
	<#
	.SYNOPSIS
	Shares Dracoon Documents depending on Metadata file (Common UseCase: sharing test results)
	
	.DESCRIPTION
	Generates Path Variables (within standard directory: /%Appdata%/PSDracoon/):
		Ergebnisse: 	/%Appdata%/PSDracoon/Ergebnisse/
		Metadaten: 		/%Appdata%/PSDracoon/Metadaten/Metadaten.csv
		Report:			/%Appdata%/PSDracoon/Report.csv

	begin:
	- Receives authentication token
	process:
	- Import PDF-List
	- Import Metafiles
	- Open UploadChannel
	- Upload File
	- Close UploadChannel
	- Sharing Link and password (Mail and SMS)
	
	.PARAMETER BaseURL
	BaseURL - Imported from standard config (Connect-Dracoon)
	
	.PARAMETER Credential
	Credential - Imported from standard config (Connect-Dracoon)
	
	.PARAMETER ClientID
	ClientID - Imported from standard config (Connect-Dracoon)
	
	.PARAMETER ClientSecret
	ClientSecret - Imported from standard config (Connect-Dracoon)
	
	.PARAMETER RoomID
	RoomID - Imported from standard config (Connect-Dracoon)
	
	.PARAMETER BasePath
	BasePath - Imported from standard config (Set within PSDracoon/internal/configurations/configuration.ps1)
	
	.PARAMETER EnableException
	Exception Handling

	.PARAMETER Confirm
	If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

	.PARAMETER Whatif
	If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.
	
	.EXAMPLE
	Publish-DracoonDocument

	Uploads files.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
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
				Send-DownloadLink -APIUrl $APIUrl -Token $Token -Mobil $Person.Mobil -Mail $person.Mail -NodeID $NodeID
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
