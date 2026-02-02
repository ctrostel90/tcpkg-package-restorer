# TcPkg Package Restorer

A tool to help ease installing many packages/workloads on a computer. Installs all packages/workloads under the packages folder.

To use:

1. Place desired packages and workloads in packages folder
2. Ensure All XAE shells and Visual Studio instances are closed
3. Run the InstallOfflinePackages.ps1 as an Administrator

## Options

### Directory

If a custom directory is desired to be used the `-Directory` argument can be used.

`InstallOfflinePackages.ps1 -Directory "C:/MyCustomDirectory/Location/Here"`

### VerifySignature

The script will by default check the VerifySignatures option in TcPkg. If it is set, it will attempt to unset it. This can be disabled by using the `VerifySignatures` paramter.

`InstallOfflinePackages.ps1 -VerifySignatures $True`
