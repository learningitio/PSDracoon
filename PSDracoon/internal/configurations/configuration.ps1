<#
This is an example configuration file

By default, it is enough to have a single one of them,
however if you have enough configuration settings to justify having multiple copies of it,
feel totally free to split them into multiple files.
#>

<#
# Example Configuration
Set-PSFConfig -Module 'PSDracoon' -Name 'Example.Setting' -Value 10 -Initialize -Validation 'integer' -Handler { } -Description "Example configuration setting. Your module can then use the setting using 'Get-PSFConfigValue'"
#>
Set-PSFConfig -Module 'PSDracoon' -Name 'BaseURL' -Value "" -Initialize -Validation 'String' -Description "Dracoon Tenant URL"
Set-PSFConfig -Module 'PSDracoon' -Name 'Credential' -Value $null -Initialize -Validation 'Credential' -Description "Credentials of requesting user"
Set-PSFConfig -Module 'PSDracoon' -Name 'ClientID' -Value "" -Initialize -Validation 'String' -Description "ClientID"
Set-PSFConfig -Module 'PSDracoon' -Name 'ClientSecret' -Value "" -Initialize -Validation 'String' -Description "ClientSecret"
Set-PSFConfig -Module 'PSDracoon' -Name 'RoomID' -Value "" -Initialize -Validation 'String' -Description "RoomID"
Set-PSFConfig -Module 'PSDracoon' -Name 'BasePath' -Value (Join-Path -Path (Get-PSFPath -Name AppData) -ChildPath "PSDracoon") -Initialize -Validation 'String' -Description "BasePath"



Set-PSFConfig -Module 'PSDracoon' -Name 'Import.DoDotSource' -Value $false -Initialize -Validation 'bool' -Description "Whether the module files should be dotsourced on import. By default, the files of this module are read as string value and invoked, which is faster but worse on debugging."
Set-PSFConfig -Module 'PSDracoon' -Name 'Import.IndividualFiles' -Value $false -Initialize -Validation 'bool' -Description "Whether the module files should be imported individually. During the module build, all module code is compiled into few files, which are imported instead by default. Loading the compiled versions is faster, using the individual files is easier for debugging and testing out adjustments."