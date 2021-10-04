
#------------------------------------------------
# Create SCCM MFP Printer App Deployment.
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
    $PackageDirectory = "\\SITESERVER\source\Printer_Deploy\MFP-Printers"

#Specifies the directory the script is ran from.
$FileSource = "$PSScriptRoot"
#Specifies the path for the log file.
$LogPath = "$FileSource\Deployment_MFPPrinters_Log_Prod.txt"
# Sets the location of the master list of printers/buildings.
$MasterList = "$FileSource\Source Files\MFPPrintersPorts.csv"
# Imports the master list of printers and buildings used to specify the deployments.
$PrinterList = Import-Csv $MasterList 

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
$Log = "Starting Deployment Script`r`n"
$Log += Log-DateStamp
$Log += "-----------------------------`r`n"
$Log | Out-File -FilePath $LogPath -Force

#Loads SCCM modules.
$Log += "Loading SCCM modules.`r`n"
$Log += Log-DateStamp
$Log += "-----------------------------`r`n"

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
#For Loop to create all the apps.
$Log += "Beginning bulk App Deployments.`r`n"
$Log += Log-DateStamp
$Log += "-----------------------------`r`n"

# For each block that loops through the folders in the Script root and makes apps for each one.
foreach ($Printer in $PrinterList) {

    # Cahnges working directory to the SCCM server.
    CD $SCCMDrive

    #------------------------------------------------
    # Sets variables for the App creation.
    #------------------------------------------------

    #Sets the Printer name Variable.
    $PrinterName = $Printer.'Printer Name' 
    # Sets the expected application name based off of the printer name.
    $ApplicationName = "MFP-Printer: $PrinterName"
    # Sets the Building Name.
    $Building = $Printer.Building
    # Sets the collection name based off of the building name.
    $TargetCollection = "Printers - $Building"

    Write-Host "Deploying Application: `"$ApplicationName`" to Collection: `"$TargetCollection`" with the `"Install`" action.`r`n"

    try{
        
        # Deploys the Application as an available install that is available immediately. 
        New-CMApplicationDeployment -CollectionName $TargetCollection -Name $ApplicationName -AvailableDateTime ([DateTime]::Now) -DeployAction Install -DeployPurpose Available -OverrideServiceWindow $false -TimeBaseOn LocalTime -UseMeteredNetwork $true -UserNotification DisplaySoftwareCenterOnly -ErrorAction Stop

        Write-Host "Application: `"$ApplicationName`" Deployed to Collection: `"$TargetCollection`" successfully.`r`n"
        Write-Host "________________________________`r`n"

        $Log += "Application: `"$ApplicationName`" Deployed to Collection: `"$TargetCollection`" successfully.`r`n"
        $Log += "________________________________`r`n"
        }
    catch{
        $Oops = $error[0].ToString()
        $Log += "WARNING: Error Deploying App named `"$ApplicationName`". Error Detail: `"$Oops`"`r`n"
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