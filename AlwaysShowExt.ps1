If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
    Start-Process PowerShell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
    Exit	
}


function Run-Trusted([String]$command) {

    Stop-Service -Name TrustedInstaller -Force -ErrorAction SilentlyContinue
    #get bin path to revert later
    $service = Get-WmiObject -Class Win32_Service -Filter "Name='TrustedInstaller'"
    $DefaultBinPath = $service.PathName
    #convert command to base64 to avoid errors with spaces
    $bytes = [System.Text.Encoding]::Unicode.GetBytes($command)
    $base64Command = [Convert]::ToBase64String($bytes)
    #change bin to command
    sc.exe config TrustedInstaller binPath= "cmd.exe /c powershell.exe -encodedcommand $base64Command" | Out-Null
    #run the command
    sc.exe start TrustedInstaller | Out-Null
    #set bin back to default
    sc.exe config TrustedInstaller binpath= "`"$DefaultBinPath`"" | Out-Null
    Stop-Service -Name TrustedInstaller -Force -ErrorAction SilentlyContinue

}


$value = Get-ItemPropertyValue -Path 'registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name HideFileExt -ErrorAction SilentlyContinue
if ($value -ne 0 -or $null -eq $value) {
    Write-Host 'Enabling Show File Extensions' -ForegroundColor Green
    Reg.exe add 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' /v 'HideFileExt' /t REG_DWORD /d '0' /f *>$null
}


$regPath = 'registry::HKEY_CLASSES_ROOT'

$items = (Get-ChildItem -Path $regPath).Name
$neverShowExtPaths = @()
foreach ($item in $items) {
    $path = ((Get-ChildItem -Path "registry::$item" -Depth 0) | Where-Object { $_.Property -like 'NeverShowExt' }).Name
    if ($path -ne $null) {
        $neverShowExtPaths += $path
    }
}

if ($neverShowExtPaths.Length -eq 0) {
    Write-Host 'No Extensions Hidden!' -ForegroundColor Green
}
else {
    $count = 0
    foreach ($path in $neverShowExtPaths) {
        if ($null -ne $path) {
            $name = $path -replace 'HKEY_CLASSES_ROOT\\' , ''
            Write-Host "Unhiding: $name" 
            $count++
            $command = "Remove-ItemProperty -Path `"registry::$path`" -Name 'NeverShowExt' -Force"
            Run-Trusted -command $command
        
        }
    }
    Write-Host "$count File Extensions Unhidden!" -ForegroundColor Green
}


