## Unhide ALL File Extensions In Windows

This PowerShell script will unhide file extensions in Windows 10 and 11. It first checks if the HideFileExt reg key is set. It then finds all the file extensions that contain the `NeverShowExt` property and removes it with Trusted Installer privileges.

### Why

These special file extensions can be exploited by threat actors to run malicious code without your knowledge. 

### How to Use

*Run From PowerShell Console*

```PowerShell
iwr 'https://raw.githubusercontent.com/zoicware/AlwaysShowExt/main/AlwaysShowExt.ps1' | iex
```