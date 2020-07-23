#
$dir = "C:\Packages\"
Set-Location $dir
 
# force TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
 
# download R engine for Windows machine
$url = "https://cran.r-project.org/bin/windows/base/R-3.6.1-win.exe"
$output = "$dir\R-win.exe"
$wc = New-Object System.Net.WebClient
$wc.DownloadFile($url, $output)
Write-Output "Download R-3.6.1 completed"
 
$path = $dir + "R-win.exe"
Start-Process -FilePath $path -ArgumentList "/VerySilent"
Write-Output "Install R-3.6.1 started"

# download RStudio for Windows machine
$url = "http://download1.rstudio.org/desktop/windows/RStudio-1.2.1335.exe"
$output = "$dir\RStudio-1.2.1335.exe"
$wc = New-Object System.Net.WebClient
$wc.DownloadFile($url, $output)
Write-Output "Download RStudio-1.2.1335 completed"
 
$path = $dir + "RStudio-1.2.1335.exe"
Start-Process -FilePath $path -ArgumentList "/S"
Write-Output "Install RStudio-1.2.1335 started"
