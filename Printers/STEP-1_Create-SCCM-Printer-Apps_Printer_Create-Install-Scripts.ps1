#------------------------------------------------
# Create SCCM Printer Scripts.
# Created by: GMaddox - 09-06-2021
# Last Edit by: GMaddox - 10-01-2021
#------------------------------------------------


# Sets working directory.
$Source = "$PSScriptRoot"
# Imports the MFP list.
$MasterList = "$Source\Source Files\printers.csv"
# Loads the Install Template.
$InstallTemplate = Get-Content "$Source\Source Files\Install_Printer_TEMPLATE.cmd"
# Loads the UnInstall Template.
$UnInstallTemplate = Get-Content "$Source\Source Files\UnInstall_Printer_TEMPLATE.cmd"
# Saves the MFP List as a variable.
$PrinterList = Import-Csv $MasterList 
#Specifies the path for the log file.
$LogPath = "$Source\Script_Creation_Log.txt"

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
$Log = "Starting Script Creation Script.`r`n" 
$Log += Log-DateStamp
$Log += "-----------------------------`r`n"

# Creates Log file.
$Log | Out-File -FilePath $LogPath -Force

# Creates Install & UnInstall Scripts.
foreach ($Line in $PrinterList) {
    # Loads the Printer Name as a variable.
    $PrinterName = $Line.'Printer Name'
    # Loads the Server Name as a variable.
    $Server = $Line.'Server Name'.Replace(" (local)","")
    # Loads the Driver Name as a variable.
    $Driver = $Line.'Driver Name'
    # Sets the Output path as a variable.
    $Output = "$Source\Printer Install Scripts\$PrinterName"

    # Creates the Output Directory.
    try{
        # Creating Output Directory.
        $Log += "#######################################`r`n"
        Write-Host "Creating output directory for: $PrinterName"
        $Log += "Creating output directory for: $PrinterName`r`n"
        $Log | Out-File -FilePath $LogPath #-Force
        New-Item -Path "$Output" -ItemType Directory -Force -ErrorAction stop
        }
    catch{
        $Oops = $error[0].ToString()
        $Log += "WARNING: Error creating the output directory named `"$PrinterName`" at location: `"$Output`".  Error Detail: `"$Oops`"`r`n"
        $Log += Log-DateStamp
        $Log += "-----------------------------`r`n"
        $Log | Out-File -FilePath $LogPath #-Force
        }

# Creates Install Scripts.
    # Updates the Template with the new info and outputs the file to the Output directory.
    try{
        # Creating Install script.
        Write-Host "Creating Install script for: $PrinterName"
        $Log += "Creating Install script for: $PrinterName`r`n"
        $Log | Out-File -FilePath $LogPath #-Force

        $InstallTemplate.Replace("REPLACEME","\\$Server\$PrinterName") | Out-File "$Output\Install_Printer_$PrinterName.cmd" -Force -Encoding ASCII -ErrorAction stop
        }
    catch{
        $Oops = $error[0].ToString()
        $Log += "WARNING: Error creating the Install Script named `"Install_Printer_$PrinterName.cmd`" at location: `"$Output`".  Error Detail: `"$Oops`"`r`n"
        $Log += Log-DateStamp
        $Log += "-----------------------------`r`n"
        $Log | Out-File -FilePath $LogPath #-Force
        }

# Creates Uninstall Scripts.
    # Updates the Template with the new info and outputs the file to the Output directory.
    try{
        # Creating UnInstall script.
        Write-Host "Creating UnInstall script for: $PrinterName"
        $Log += "Creating UnInstall script for: $PrinterName`r`n"
        $Log | Out-File -FilePath $LogPath #-Force

        $UnInstallTemplate.Replace("REPLACEME","\\$Server\$PrinterName") | Out-File "$Output\UnInstall_Printer_$PrinterName.cmd" -Force -Encoding ASCII -ErrorAction stop
        }
    catch{
        $Oops = $error[0].ToString()
        $Log += "WARNING: Error creating the UnInstall Script named `"UnInstall_Printer_$PrinterName.cmd`" at location: `"$Output`".  Error Detail: `"$Oops`"`r`n"
        $Log += Log-DateStamp
        $Log += "-----------------------------`r`n"
        $Log | Out-File -FilePath $LogPath #-Force
        }

    #Load an ERROR value into the variables to prevent duplicate files.
    $PrinterName = "ERROR"
    $Server = "ERROR"
    $Driver = "ERROR"
    $Output = "ERROR"
}

$Log += "#######################################`r`n"
$Log += "----End Package Script----`r`n"
$Log += Log-DateStamp
$Log += "-----------------------------`r`n"
$Log | Out-File -FilePath $LogPath -Force
