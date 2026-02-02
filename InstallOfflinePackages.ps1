param(
    [Parameter(Mandatory=$false)]
    [string]$Directory = "packages",

    [Parameter(Mandatory=$false)]
    [bool]$VerifySignatures = $false
)
function Invoke-ElevatedCommand {
    param(
        [string]$Command,
        [string]$Arguments,
        [string]$Description
    )

    $IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if ($IsAdmin) {
        # Already running as admin, execute directly
        Write-Host "$Description" -ForegroundColor Blue
        $process = Start-Process -FilePath $Command -ArgumentList $Arguments -Wait -PassThru -WindowStyle Hidden
        return $process.ExitCode
    } else {
        # Need elevation for this specific command
        Write-Host "$Description (requesting elevation)" -ForegroundColor Yellow
        $process = Start-Process -FilePath $Command -ArgumentList $Arguments -Verb RunAs -Wait -PassThru -WindowStyle Hidden
        return $process.ExitCode
    }
}

$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if(-not $IsAdmin) {
    Write-Host "Not running as Administrator. Recommended to restart the running of the process with Administrator privlages." -ForegroundColor Yellow
    $result = Read-Host "Continue? [y]es or [no]"
    if($result -eq "n"){
        exit
    }elseif ($result -ne "y") {
        Write-Host "Invalid command, exiting program.."
        exit
    }
}

if($VerifySignatures){
    Write-Host "Unable to disable signature verification. Will cause custom unsigned packages to fail!" -ForegroundColor Yellow
}
else{
# Determine if VerifySignatures is already set or not
    $configOptions = &tcpkg config list 
    $setting = ([regex]::Match($configOptions, 'VerifySignatures:\s*(\w+)')).Groups[1].Value

    if($setting -ne "False"){
        $exitCode = Invoke-ElevatedCommand -Command "tcpkg" -Arguments "config unset -n VerifySignatures" -Description "Disabling signature verification"

        if ($exitCode -ne 0){
            Write-Host "Unable to disable signature verification. Will cause custom unsigned packages to fail!" -ForegroundColor Yellow
        }
    }
}

$packagesPath = Join-Path -path $pwd -ChildPath $Directory

$nupkgFiles = Get-ChildItem -Path "$packagesPath" -Filter "*.nupkg" -Name

if ($nupkgFiles.Count -eq 0) {
    Write-Warning "No packages found in directory: $Directory"
    exit
}
else{
    Write-Host "Found $($nupkgFiles.Count) package(s)/workload(s). Installing.."
}
$processes = Get-Process -Name "*TcXaeShell*" -ErrorAction SilentlyContinue

if ($processes.Count -ne 0) {
    Write-Host "Close all TwinCAT XAE Shells and Visual Studio instances before running." -ForegroundColor Red
    exit
}

$returnCode = Invoke-ElevatedCommand -Command "tcpkg" -Arguments "source add -n `"RestorePackagesSource`" -s `"$packagesPath`"" -Description "Adding package source"
if($returnCode -ne 0){
    Write-Host "Error adding feed. Attempting to continue.." -ForegroundColor Yellow
}
$installed = 0
foreach ($file in $nupkgFiles) {
    
    $name = ([regex]::Match($file, '^(.+?)\.(?:\d+\.\d+\.\d+)\.nupkg$')).Groups[1].Value
    $returnCode = Invoke-ElevatedCommand -Command "tcpkg" -Arguments "install `"$name`" -n `"RestorePackagesSource`" -y" -Description "Installing Package: $file"
    if($returnCode -ne 0){
        Write-Host "Failed to install $file"
    }
    else{
        $installed += 1
    }
}
$returnCode = Invoke-ElevatedCommand -Command "tcpkg" -Arguments "source remove `"RestorePackagesSource`"" -Description "Removing package source"
if ($returnCode -ne 0){
    Write-Host "Failed to remove configured feed." -ForegroundColor Yellow
}
Write-Host "Completed. Installed $installed package(s)/workload(s)" -ForegroundColor Green


