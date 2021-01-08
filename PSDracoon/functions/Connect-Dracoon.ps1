function Connect-Dracoon
{
	<#
	.SYNOPSIS
	Saves config-data for PSDracoon (authentication details, etc.)
	
	.DESCRIPTION
	Tries to obtain Dracoon Authentication Token. If successful: Saves config-data for PSDracoon (authentication details, etc.)
	
	.PARAMETER BaseURL
	Tenant URI
	
	.PARAMETER Credential
	Authentication Credentials
	
	.PARAMETER ClientID
	ClientID (Generated within Dracoon Application)
	
	.PARAMETER ClientSecret
	ClientSecret (Generated within Dracoon Application)
	
	.PARAMETER RoomID
	RoomID: Defines Online Space

	.PARAMETER EnableException
	Exception Handling
	
	.EXAMPLE
	Connect-Dracoon -ClientID $ClientId -ClientSecret $ClientSecret -Credential $Credential -BaseURL $BaseURL
	
	Enrolls basic configuration.
	#>

	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[String]$BaseURL,

		[Parameter(Mandatory = $true)]
		[pscredential]$Credential,

		[Parameter(Mandatory = $true)]
		[String]$ClientID,

		[Parameter(Mandatory = $true)]
		[String]$ClientSecret,

		[Parameter(Mandatory = $true)]
		[String]$RoomID,

		[Switch]$EnableException
	)
	
	process
	{
		try {
			$null = Get-Token -ClientID $ClientId -ClientSecret $ClientSecret -Credential $Credential -BaseURL $BaseURL
		}
		catch {
			Stop-PSFFunction -Message "Anmeldung fehlgeschlagen! Bitte Zugangsdaten und Netzwerkverbindung prüfen!" -ErrorRecord $_ -Cmdlet $PSCmdlet -EnableException $EnableException
			return
		}

		Set-PSFConfig -Module 'PSDracoon' -Name 'BaseURL' -Value $BaseURL -PassThru | Register-PSFConfig
		Set-PSFConfig -Module 'PSDracoon' -Name 'Credential' -Value $Credential -PassThru | Register-PSFConfig
		Set-PSFConfig -Module 'PSDracoon' -Name 'ClientID' -Value $ClientID -PassThru | Register-PSFConfig
		Set-PSFConfig -Module 'PSDracoon' -Name 'ClientSecret' -Value $ClientSecret -PassThru | Register-PSFConfig
		Set-PSFConfig -Module 'PSDracoon' -Name 'RoomID' -Value $RoomID -PassThru | Register-PSFConfig
	
	}

}
