# Change log for YetAnotherCMLogger module

## 1.0.0.3 June 08, 2022

- Changed Write-YaCMLogEntry2 to Write-YaCMLogEntry; accidental change during testing. 

## 1.0.0.2 June 07, 2022

- Added File name value for Set-YaCMLogFileName; useful when Intune generates a random caller file name.
- Fixed Synopsis on Set-YaCMLogFileName; missing ParentPath
- Fixed Passthru option on  Set-YaCMLogFileName; changed to switch
- Changed Write-YaCMLogEntry output to Encoding UTF8; fixed verbose output from pipeline

## 1.0.0.0 June 05, 2022

- Initial upload
