

class File {
    [string]$RelativeFilePath
    [string]$FullFilePath
    [string]$FileHash
}

class FileComparison{
    [string]$Folder1RelativeFilePath
    [string]$Folder1FullFilePath
    [string]$Folder2RelativeFilePath
    [string]$Folder2FullFilePath
    [bool]$DifferenceExists
}

$Folder1Path=""
$Folder2Path=""

$Folder1FileList=[System.Collections.Generic.List[File]]::new()
$Folder2FileList=[System.Collections.Generic.List[File]]::new()
$FileComparisonList=[System.Collections.Generic.List[FileComparison]]::new()
$FilesToOpen=[string]::new()

#folder 1
(Get-ChildItem -Path $Folder1Path -Recurse -Attributes !Directory | Where-Object { $_.FullName -notlike "*\bin\*" -and $_.FullName -notlike "*\obj\*" }) | ForEach-Object {
    $File=[File]::new()
    $File.RelativeFilePath=$_.FullName.Replace($Folder1Path, "")
    $File.FullFilePath=$_.FullName
    $File.FileHash=((Get-FileHash -Path $_.FullName).Hash)
    $Folder1FileList.Add($File)
}

#folder 2
(Get-ChildItem -Path $Folder2Path -Recurse -Attributes !Directory | Where-Object { $_.FullName -notlike "*\bin\*" -and $_.FullName -notlike "*\obj\*" }) | ForEach-Object {
    $File=[File]::new()
    $File.RelativeFilePath=$_.FullName.Replace($Folder2Path, "")
    $File.FullFilePath=$_.FullName
    $File.FileHash=((Get-FileHash -Path $_.FullName).Hash)
    $Folder2FileList.Add($File)
}

#check for files in Folder1 but not in Folder2
foreach ($File in $Folder1FileList)
{
    if (-not ($File.RelativeFilePath -in ($Folder2FileList | Select-Object -ExpandProperty "RelativeFilePath")))
    {
        $FileComparison=[FileComparison]::new()
        $FileComparison.Folder1RelativeFilePath=$File.RelativeFilePath
        $FileComparison.Folder1FullFilePath=$File.FullFilePath
        $FileComparison.Folder2RelativeFilePath="<none>"
        $FileComparison.Folder2FullFilePath="<none>"
        $FileComparison.DifferenceExists=$true
        $FileComparisonList.Add($FileComparison)
    }
}

#check for files in Folder2 but not in Folder1
foreach ($File in $Folder2FileList)
{
    if (-not ($File.RelativeFilePath -in ($Folder1FileList | Select-Object -ExpandProperty "RelativeFilePath")))
    {
        $FileComparison=[FileComparison]::new()
        $FileComparison.Folder1RelativeFilePath="<none>"
        $FileComparison.Folder1FullFilePath="<none>"
        $FileComparison.Folder2RelativeFilePath=$File.RelativeFilePath
        $FileComparison.Folder2FullFilePath=$File.FullFilePath
        $FileComparison.DifferenceExists=$true
        $FileComparisonList.Add($FileComparison)
    }
}

#check for files that are in both but have a different hash
foreach ($Folder1File in $Folder1FileList)
{
    foreach ($Folder2File in $Folder2FileList)
    {
        if (($Folder1File.RelativeFilePath -eq $Folder2File.RelativeFilePath) -and ($Folder1File.FileHash -ne $Folder2File.FileHash))
        {
            $FileComparison=[FileComparison]::new()
            $FileComparison.Folder1RelativeFilePath=$Folder1File.RelativeFilePath
            $FileComparison.Folder1FullFilePath=$Folder1File.FullFilePath
            $FileComparison.Folder2RelativeFilePath=$Folder2File.RelativeFilePath
            $FileComparison.Folder2FullFilePath=$Folder2File.FullFilePath
            $FileComparison.DifferenceExists=$true
            $FileComparisonList.Add($FileComparison)        
        }
    }
}

($FileComparisonList | Select-Object -Property "Folder1RelativeFilePath", "Folder2RelativeFilePath", "DifferenceExists", "Folder1FullFilePath", "Folder2FullFilePath" | Out-GridView -PassThru) | ForEach-Object {
    if ($_.Folder1FullFilePath -ne "<none>" -and $_.Folder2FullFilePath -ne "<none>")
    {
        $FilesToOpen+="`"$($_.Folder1FullFilePath)`" `"$($_.Folder2FullFilePath)`""
    }
}
Start-Process "C:/Program Files/Notepad++/notepad++.exe" -ArgumentList "-multiInst $FilesToOpen -nosession"