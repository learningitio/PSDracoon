# PSDracoon
Powershell Module for handling tasks on Dracoon-Software (https://www.dracoon.com).
The module is completely plattform independant and can be run on MacOS, Windows and Linux.

## How to Install
In order to acquire the latest version of the module from a machine that has internet connectivity,
simply run the following PowerShell line:

```powershell
Install-Module -Name PSDracoon -Force
```

Afterwards you can setup the module by using following Command:

```powershell
Connect-Dracoon
```

You have to enter authentication details and your personal Dracoon IDs. These information will be saved securely on your client only by using PSFConfig (PSFramework Module).

## Usecases
The primary use case at the current state is to share clinical test results to patients. Therefor following command is used:

```powershell
Publish-DracoonDocument
```
You can find the needed directory-structure at your user's AppData folder.

**Windows**
C:\Users\USERNAME\AppData

**MacOS**
/Users/USERNAME/.local/share/

**Linux**
/Users/USERNAME/.local/share/
