# Builds the release APK on this PC.
# TEMP/JAVA_TOOL_OPTIONS work around Java 25 failing with
# "Unable to establish loopback connection" when TEMP is a short 8.3 path.
New-Item -ItemType Directory -Force C:\dev\tmp\uds | Out-Null
$env:TEMP = 'C:\dev\tmp'
$env:TMP = 'C:\dev\tmp'
$env:JAVA_TOOL_OPTIONS = '-Djdk.net.unixdomain.tmpdir=C:\dev\tmp\uds -Djava.io.tmpdir=C:\dev\tmp'
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
$env:PATH = "C:\dev\tools\flutter\bin;C:\msys64\usr\bin;$env:PATH"
Set-Location $PSScriptRoot
flutter build apk --release --split-per-abi
Get-ChildItem build\app\outputs\flutter-apk\*.apk | Select-Object Name, @{n = 'MB'; e = { [math]::Round($_.Length / 1MB, 1) } }
