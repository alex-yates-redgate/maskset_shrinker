# Config
$maskSet = "C:\git\maskset_shrinker\source.DMSMaskSet"
$out = "C:\deleteme\maskset_shrinker"
$required_tables = @(
    "DM_CUSTOMER",
    "DM_CUSTOMER_NOTES"
)

# DON'T CHANGE ANYTHING BELOW THIS LINE
if (-not (Test-Path $out)){
    New-Item -ItemType Directory -Path $out
}

$startTime = (Get-Date).ToString(“s”)
$startTimeWithoutPunctuation = $startTime.Replace(':','').Replace('-','')
$workingDir = "$out\$startTimeWithoutPunctuation"
$log = "$workingDir\log.txt"
$tableIndex = "$workingDir\index_tables.csv"
$indexIndex = "$workingDir\index_indexes.csv"
$fkIndex = "$workingDir\index_fks.csv"
$triggerIndex = "$workingDir\index_triggers.csv"
$outMaskSet = "$workingDir\out.DMSMaskSet"

Write-Output "$startTime Creating working directory at: $workingDir"
Write-Output "$startTime For detailed log, see: $log"

New-Item -ItemType Directory -Path $workingDir | out-null
New-Item -ItemType File -Path $log | out-null
New-Item -ItemType File -Path $tableIndex | out-null
New-Item -ItemType File -Path $indexIndex | out-null
New-Item -ItemType File -Path $fkIndex | out-null
New-Item -ItemType File -Path $triggerIndex | out-null
New-Item -ItemType File -Path $outMaskSet | out-null

Function Write-Log {
    param (
        $message = ""
    )
    $time = (Get-Date).ToString(“s”)
    Add-Content $log "$time $message"
}

Write-Log "Parameters:"
Write-Log "  maskSet: $maskSet"
Write-Log "  out: $out"
Write-Log "  requiredTables:"
$required_tables | ForEach-Object {
    Write-Log "  - $_"
}

Write-Log
Write-Log "Creating stream reader object to read the mask set line by line."
$stream_reader = New-Object System.IO.StreamReader($maskSet)

Write-Log
Write-Log "Indexing tables."
$totalFoundtablesToKeep = 0
$totalTables = 0
$totalLines = 0
while (($current_line = $stream_reader.ReadLine()) -ne $null) {
    $totalLines++
    $tablesNode = $false
    if ($current_line.Trim() -like "<SchemaTables>"){
        $tablesNode = $true
    }
    if ($current_line.Trim() -like "</SchemaTables>"){
        $tablesNode = $false
    }
    if (($current_line.Trim() -like "<TableName Value=* />") -and ($tablesNode = $true)){
        $tableName = $current_line.Split('"')[1]
        $keepTable = "0"
        if ($required_tables -contains $tableName){
            $keepTable = "1"
            $totalFoundtablesToKeep++
        }
        $totalTables++
        Add-Content $tableIndex "$keepTable,$tableName"
        if ($totalTables % 100 -eq 0){
            Write-Log "  Indexed $totalTables tables. "
        }
    }
}
$stream_reader.Close()

$totalRedundantTables = $totalTables - $tablesToKeep
$totalExpectedTablesToKeep = $required_tables.Length
Write-Log "Indexing tables complete."
Write-Log "  Lines in source mask set: $totalLines"
Write-Log "  Total tables: $totalTables"
Write-Log "  Total required tables expected: $tablesToKeep"
Write-Log "  Total required tables found: $tablesToKeep"
Write-Log "  Total redundant tables: $totalRedundantTables"
Write-Log

Write-Log "Creating new stream reader object to read the mask set line by line."
$masksetReader = New-Object System.IO.StreamReader($maskSet)
$tablesIndexReader = New-Object System.IO.StreamReader($tableIndex)

Write-Log
$currentTime = (Get-Date).ToString(“s”)
$message = "Creating new mask set at: $outMaskSet"
Write-Output "$currentTime $message"

$lineNumber = 0
$copyLine = $true
while (($current_line = $masksetReader.ReadLine()) -ne $null) {
    if ($current_line.trim() -like "<DMSSchemaEntity_Table>"){
        $thisTableIndex = $tablesIndexReader.ReadLine()
        $copyTable = $thisTableIndex.Split(",")[0] 
        $tableName = $thisTableIndex.Split(",")[1]
        if ($copyTable -like "1"){
            Write-Log "Copying $tableName to new masking set."
            $copyLine = $true
        }
        else {
            Write-Log "Skipping $tableName in new masking set."
            $copyLine = $false
        }
    }
    if ($copyLine) {
        Add-Content $outMaskSet "$current_line"
    }
    if ($current_line -like "*</DMSSchemaEntity_Table>*"){
        # This was the last line of the table block, defaulting back to copyLine = true for next line.
        $copyLine = $true
    }
    $lineNumber++
    if ($lineNumber % 1000 -eq 0){
        # Periodic logging of progress
        $percentComplete = [math]::Round(($lineNumber / $totalLines) * 100)
        $currentTime = (Get-Date).ToString(“s”)
        $message = "  Copied $lineNumber lines out of $totalLines. ($percentComplete%)"
        Write-Output "$currentTime $message"
    }
}
$masksetReader.Close()
$tablesIndexReader.Close()

Write-Log "Finished."