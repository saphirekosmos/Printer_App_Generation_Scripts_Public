#------------------------------------------------
# Create SCCM Non MFP Printer Apps
# Created by: GMaddox - 09-06-2021
# Last Edit by: GMaddox - 10-01-2021
#------------------------------------------------

#------------------------------------------------
# Sets Path Variables.
#------------------------------------------------

# WARNING: You will need to update these for your own setup:
    #Specifies the Site Server.
    $SCCMDrive = "ABC:\"
    #Content location.
    $PackageDirectory = "\\SITESERVER\source\Printer_Deploy\Printers"
    #Around Line 115: $DetectScript = "foreach ($Key in (Get-ChildItem `"HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Connections\`")) { if ((Get-ItemProperty -Path $key.PSPath -Name `"Printer`").`"Printer`" -eq `"\\PRINTSERVER\$PrinterName`") {Write-Output `"True`"}}"

#Specifies the directory the script is ran from.
$FileSource = "$PSScriptRoot"
#Specifies the path for the log file.
$LogPath = "$FileSource\SCCM_App_Creation_Log.txt"

#Clears log.
$Log = $Null

#------------------------------------------------
# Sets Functions.
#------------------------------------------------

# Function to get the date for logging.
function Log-DateStamp {
    $DateStamp = Get-Date
    Write-Output "$DateStamp `r`n"
}

#------------------------------------------------
# Script Start.
#------------------------------------------------

#Start a log.
$Log = "Starting Package Script`r`n"
$Log += Log-DateStamp
$Log += "-----------------------------`r`n"
$Log | Out-File -FilePath $LogPath -Force

# Try/Catch block for importing the SCCM Module. 
try{
    #Import SCCM Module
    Import-Module "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1" -ErrorAction Stop
    if (-not (Test-Path -Path $SCCMDrive))
        {
        $Log+="SCCM PowerShell cmdlets provider is not initialized for this account, on this machine. Please open the SCCM console and select 'Connect with PowerShell' at least once before using this script on thise machine.`r`n"
        throw "SCCM PSProvider does not have a drive assigned"
        }
    }
catch{
    #End script if we could not add module
    $Log += "Failed to add required module!`r`n"
    $Log += "----End Package Script----`r`n"
    $Log | Out-File -FilePath $LogPath -Append
    exit 1
    }

#Loads  Source folders as a variable for a For-Each Loop.
$Log += "Loading source folders.`r`n"
$Log += Log-DateStamp
$Log += "-----------------------------`r`n"

$Printers = Get-ChildItem "$FileSource\Printer Install Scripts" -Directory

#For Loop to create all the apps.
$Log += "Beginning bulk App Creation.`r`n"
$Log += Log-DateStamp
$Log += "-----------------------------`r`n"

# For each block that loops through the folders in the Script root and makes apps for each one.
foreach ($Printer in $Printers) {

    #------------------------------------------------
    # Sets variables for the App creation.
    #------------------------------------------------
    #Sets the printer name based on the folder name.
    $PrinterName = $Printer.Name
    #Specifies the App name.
    $ApplicationName = "Printer: $PrinterName"
    #Specifies the app description.
    $ProductDecription = "Adds the $PrinterName Printer."
    #Specifies the publisher of the app.
    $Publisher = "ITSS"
    #Specifies the app version.
    $Version = "1"
    #Specifies the User who made/owns the app.
    $SCCMAdmin = [Environment]::UserName
    #Specifies the path for an icon file.
    $IconPath = "$FileSource\Source Files\Printer.png"
    #Specifies the location in SCCM that the app will be placed in.
    $AppLocation = "$SCCMDrive\Application\Printers"
    #Specifies the DPs to distribute to.
    $TargetDPs = "All Distribution Points"
    #Specifies the Maximun runtime for the app.
    $RuntimeMax = 15
    #Specifies the Estimated runtime for the app.
    $RuntimeEstimated = 1
    #Specifies any dependencies for the app.
    $AppDependency = "Print Drivers: Non-MFP Printers"
    #Specifies a dependency group name for the app.
    $DependencyGroup = "Print Drivers"

    # Sets the Install and uninstalls commands for the app.
    $InstallCommand = "Install_Printer_$PrinterName.cmd"
    $UnInstallCommand = "UnInstall_Printer_$PrinterName.cmd"
    #Sets the $Key variable for the detection method to show properly in the string.
    $Key='$key'
    # Script Detectioni Rule for the App.
    $DetectScript = "foreach ($Key in (Get-ChildItem `"HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Connections\`")) { if ((Get-ItemProperty -Path $key.PSPath -Name `"Printer`").`"Printer`" -eq `"\\PRINTSERVER\$PrinterName`") {Write-Output `"True`"}}"

    #Specifies the collection to deploy to. 
    #$TargetCollection="All Windows Workstations"

    # Logs the start of a new applicatiom Build.
    $Log += "###################################################`r`n"
    $Log += "Initiating App creation for: `"$ApplicationName`"`r`n"
    $Log += Log-DateStamp
    $Log += "###################################################`r`n"

    #Echos the start of the app creation.
    Write-Host "Initiating App creation for: `"$ApplicationName`"" -ForegroundColor DarkGreen

    #Copies over the source files. 
    try{
        # Tests if both the install and uninstll script exist, if either is mssing it copies. If both are present it doesn't copy. 
        if ( (Test-Path -Path "filesystem::$PackageDirectory\$PrinterName\Install_Printer_$PrinterName.cmd") -and (Test-Path -Path "filesystem::$PackageDirectory\$PrinterName\UnInstall_Printer_$PrinterName.cmd"))
        {
            $Log += "ERROR: Copying source files for `"$ApplicationName`" failed. Source directory already exists.`r`n"
            $Log += Log-DateStamp
            $Log += "-----------------------------`r`n"
            Write-Host "Source directory already exists."
        }
        else{
            $Log += "Copying source filed for `"$ApplicationName`"`r`n"
            $Log += Log-DateStamp
            $Log += "-----------------------------`r`n"

            # Makes new Directory
            New-Item -Path "Microsoft.PowerShell.Core\FileSystem::$PackageDirectory\" -Name "$PrinterName" -ItemType "directory"
            # Copies the folder and items over.
            Copy-Item -Path "Microsoft.PowerShell.Core\FileSystem::$FileSource\Printer Install Scripts\$PrinterName\*" -Destination "Microsoft.PowerShell.Core\FileSystem::$PackageDirectory\$PrinterName\" -Recurse -errorAction stop
        }
    }
        catch{
            $Oops = $error[0].ToString()
            $Log += "WARNING: Error copying source files to the source directory. Error Detail: `"$Oops`"`r`n"
            $Log += Log-DateStamp
            $Log += "-----------------------------`r`n"
            }

    #Try/Catch block for overall app creation.
    try{
    $Log += "Creating `"$ApplicationName`"`r`n"
    $Log += Log-DateStamp
    $Log += "-----------------------------`r`n"

    #Change to SCCM powershell provider, SCCM cmdlets generally do not work otherwise, however, some cmdlets may fail in the SCCM drive. Keep this in mind, you may need to switch between providers
    CD $SCCMDrive

        #Creates a new application. (Won't deploy, won't distribute, won't create deployment type. Just the application info)
    try{
        $MyNewApp = New-CMApplication -Name $ApplicationName -Description $ProductDecription -LocalizedDescription $ProductDecription -Publisher $Publisher -SoftwareVersion $Version -LocalizedName $ApplicationName -Owner $SCCMAdmin -SupportContact $SCCMAdmin -IconLocationFile $IconPath -ErrorAction stop
    }
    catch{
        $Oops = $error[0].ToString()
        $Log += "WARNING: Error creating App named `"$ApplicationName`". Error Detail: `"$Oops`"`r`n"
        $Log += Log-DateStamp
        $Log += "-----------------------------`r`n"
        }

    #Moves the application.
    $Log += "Moving `"$ApplicationName`"`r`n"
    $Log += Log-DateStamp
    $Log += "-----------------------------`r`n"

    try{
        $MyNewApp | Move-CMObject -FolderPath "$($SCCMDrive)Application\Printers" -ErrorAction stop
        }
    catch{
        $Oops = $error[0].ToString()
        $Log += "WARNING: Error moving App named `"$ApplicationName`". Error Detail: `"$Oops`"`r`n"
        $Log += Log-DateStamp
        $Log += "-----------------------------`r`n"
        }

    #Adds a deployment type to the new application, this won't distribute or deploy it
    $Log += "Creating Deployment Type `"$ApplicationName`"`r`n"
    $Log += Log-DateStamp
    $Log += "-----------------------------`r`n"

    try{
        Add-CMScriptDeploymentType -ApplicationName $ApplicationName -ContentLocation "$PackageDirectory\$PrinterName" -ContentFallback -EnableBranchCache -InstallCommand $InstallCommand -UninstallCommand $UninstallCommand -UninstallOption SameAsInstall -LogonRequirementType WhetherOrNotUserLoggedOn -SlowNetworkDeploymentMode Download -UserInteractionMode Hidden -InstallationBehaviorType InstallForSystem -DeploymentTypeName "Install_$PrinterName" -ScriptLanguage PowerShell -ScriptText $DetectScript -EstimatedRuntimeMins $RuntimeEstimated -MaximumRuntimeMins $RuntimeMax -ErrorAction Stop
        }
    catch{
        $Oops = $error[0].ToString()
        $Log += "WARNING: Error creating deployment type for App named `"$ApplicationName`". Error Detail: `"$Oops`"`r`n"
        $Log += Log-DateStamp
        $Log += "-----------------------------`r`n"
        }

        #Adds a deployment dependancy the new application.
    $Log += "Creating deployment dependancy for `"$ApplicationName`"`r`n"
    $Log += Log-DateStamp
    $Log += "-----------------------------`r`n"

    try{
        #This line can be removed it you don't need to ensure that drivers are already installe don the machine. 
        Get-CMDeploymentType -ApplicationName $ApplicationName | New-CMDeploymentTypeDependencyGroup -GroupName $DependencyGroup | Add-CMDeploymentTypeDependency -DeploymentTypeDependency (Get-CMDeploymentType -ApplicationName $AppDependency) -IsAutoInstall $true -ErrorAction stop
    }
    catch{
        $Oops = $error[0].ToString()
        $Log += "WARNING: Error creating deployment dependancy for App named `"$ApplicationName`". Error Detail: `"$Oops`"`r`n"
        $Log += Log-DateStamp
        $Log += "-----------------------------`r`n"
        }

    #Distribute the content, doesnt deploy
    $Log += "Distributing `"$ApplicationName`"`r`n"
    $Log += Log-DateStamp
    $Log += "-----------------------------`r`n"

    try{
        Start-CMContentDistribution -ApplicationName $ApplicationName -DistributionPointGroupName $TargetDPs -ErrorAction stop
        }
    catch{
        $Oops = $error[0].ToString()
        $Log += "WARNING: Error Distributing App named `"$ApplicationName`". Error Detail: `"$Oops`"`r`n"
        $Log += Log-DateStamp
        $Log += "-----------------------------`r`n"
        }

    }
    catch{
        $Log +=  "Failed to create package. $($_.ToString())"
        $Log += Log-DateStamp
        $Log += "-----------------------------`r`n"
    }
}
    
    #Return to filesystem provider
    cd "$($env:SystemDrive)\"

    $Log += "----End Package Script----`r`n"
    $Log += Log-DateStamp
    $Log += "-----------------------------`r`n"
    $Log | Out-File -FilePath $LogPath -force
