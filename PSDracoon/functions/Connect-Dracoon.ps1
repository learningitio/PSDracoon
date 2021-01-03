function Connect-Dracoon
{
	<#
	.SYNOPSIS
	Short description
	
	.DESCRIPTION
	Long description
	
	.PARAMETER BaseURL
	Parameter description
	
	.PARAMETER Credential
	Parameter description
	
	.PARAMETER ClientID
	Parameter description
	
	.PARAMETER ClientSecret
	Parameter description
	
	.PARAMETER RoomID
	Parameter description
	
	.EXAMPLE
	An example
	
	.NOTES
	General notes
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
