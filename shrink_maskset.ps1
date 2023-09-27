$ErrorActionPreference = "stop"

# Config
$maskSet = "C:\git\maskset_shrinker\source.DMSMaskSet"
$out = "C:\deleteme\maskset_shrinker"
$required_tables = @(
    "DM_CUSTOMER",
    "DM_CUSTOMER_NOTES"
)
$batchSize = 1000
$readLogFrequency = 10000
$writeLogFrequency = 1000

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

Function Get-ResourceUtilization {
    $memory = (Get-Counter '\Memory\Available MBytes').CounterSamples.CookedValue
    $cpu = [math]::Round((Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue)
    return "Available memory: $memory GB. CPU utilization: $cpu%."
}

Write-Log "Parameters:"
Write-Log "  maskSet: $maskSet"
Write-Log "  out: $out"
Write-Log "  requiredTables:"
$required_tables | ForEach-Object {
    Write-Log "  - $_"
}

Write-Log
Write-Log "Baseline resource utilization:"
$resources = Get-ResourceUtilization
Write-Log "  $resources"

Write-Log
Write-Log "Creating stream reader object to read the mask set line by line."
$stream_reader = New-Object System.IO.StreamReader($maskSet)

Write-Log
Write-Log "Indexing mask set."
$lineNumber = 0
$totalFoundTablesToKeep = 0
$totalFoundIndexesToKeep = 0
$totalFoundFksToKeep = 0
$totalTables = 0
$totalIndexes = 0
$totalFks = 0
$totalLines = 0
$indexName = ""
$fkChildConstraintName = ""
$fkChildTableName = ""
$fkParentTableName = ""
$indexTableName = ""
$keyLines = @(
    "<SchemaTables>",
    "</SchemaTables>",
    "<SchemaIndexes>",
    "</SchemaIndexes>",
    "<SchemaForeignKeys>",
    "</SchemaForeignKeys>",
    "<SchemaTriggers>",
    "</SchemaTriggers>"
)
$keyLineNumber = 0
$keyLineNumbers = @()

while ($null -ne ($current_line = $stream_reader.ReadLine())) {
    $lineNumber++
    
    

    if ($current_line.Trim() -like $keyLines[$keyLineNumber] ){
        $foundLine = $keyLines[$keyLineNumber]
        Write-Log "  Found line: $foundLine at line number $lineNumber"
        $keyLineNumber++
        $keyLineNumbers += $lineNumber
    }

    # SchemaTables node
    if ($keyLineNumber -eq 1){
        if ($current_line.Trim() -like "<TableName Value=*"){
            $tableName = $current_line.Split('"')[1]
            $keepTable = "0"
            if ($required_tables -contains $tableName){
                $keepTable = "1"
                $totalFoundTablesToKeep++
            }
            $totalTables++
            Add-Content $tableIndex "$keepTable,$tableName"
            if ($totalTables % $batchSize -eq 0){
                Write-Log "  Indexed $totalTables tables. Keeping $totalFoundTablesToKeep."

            }
        }
    }

    # SchemaIndexes node
    if ($keyLineNumber -eq 3){
        if ($current_line.Trim() -like "<IndexName Value=* />"){
            $indexName = $current_line.Split('"')[1]
        }
        if ($current_line.Trim() -like "<IndexTableName Value=* />"){
            $indexTableName = $current_line.Split('"')[1]
        }
        if ($current_line.Trim() -like "</DMSSchemaEntity_Index>"){
            $keepIndex = "0"
            if ($required_tables -contains $indexTableName){
                $keepIndex = "1"
                $totalFoundIndexesToKeep++
            }
            $totalIndexes++
            Add-Content $indexIndex "$keepIndex,$indexName"
            if ($totalIndexes % $batchSize -eq 0){
                Write-Log "  Indexed $totalIndexes indexes. Keeping $totalFoundIndexesToKeep."
            }
        }
    }

    # SchemaFks node
    if ($keyLineNumber -eq 5){
        if ($current_line.Trim() -like "<FKChildConstraintName Value=* />"){
            $fkChildConstraintName = $current_line.Split('"')[1]
        }
        if ($current_line.Trim() -like "<FKChildTableName Value=* />"){
            $fkChildTableName = $current_line.Split('"')[1]
        }
        if ($current_line.Trim() -like "<FKParentTableName Value=* />"){
            $fkParentTableName = $current_line.Split('"')[1]
        }
        if ($current_line.Trim() -like "</DMSSchemaEntity_ForeignKey>"){
            $keepFk = "0"
            if (($required_tables -contains $fkChildTableName) -or ($required_tables -contains $fkParentTableName)){
                $keepFk = "1"
                $totalFoundFksToKeep++
            }
            $totalFks++
            Add-Content $fkIndex "$keepFk,$fkChildConstraintName,$fkChildTableName,$fkParentTableName"
            if ($totalTables % $batchSize -eq 0){
                Write-Log "  Indexed $totalFks FKs. Keeping $totalFoundFksToKeep."
            }
        }
    }
    
}
$totalLines = $lineNumber
$stream_reader.Close()

$schemaTablesNodeSize = $keyLineNumbers[1] - $keyLineNumbers[0]
$schemaIndexesNodeSize = $keyLineNumbers[3] - $keyLineNumbers[2]
$schemaFksNodeSize = $keyLineNumbers[5] - $keyLineNumbers[4]
$schemaTriggersNodeSize = $keyLineNumbers[7] - $keyLineNumbers[6]
$otherRows = $totalLines - ($schemaTablesNodeSize + $schemaIndexesNodeSize + $schemaFksNodeSize + $schemaTriggersNodeSize)
$estimatedOutputRows = [math]::Round($otherRows + $schemaTriggersNodeSize + ($schemaTablesNodeSize * $totalFoundTablesToKeep / $totalTables) + ($schemaIndexesNodeSize * $totalFoundIndexesToKeep / $totalIndexes) + ($schemaFksNodeSize * $totalFoundFksToKeep / $totalFks))
$estimatedShrinkFactor = 100 - [math]::Round(($estimatedOutputRows / $totalLines) * 100)

$indexMessage = @"

Indexing complete.
  Total rows in source masking set: $totalLines
  
  schemaTables node rows:           $schemaTablesNodeSize
  schemaIndexes node rows:          $schemaIndexesNodeSize
  schemaFks node rows:              $schemaFksNodeSize
  schemaTriggers node rows:         $schemaTriggersNodeSize
  Other rows:                       $otherRows

  Total tables:           $totalTables. (Keeping $totalFoundTablesToKeep.)
  Total indexes:          $totalIndexes. (Keeping $totalFoundIndexesToKeep.)
  Total foreign keys:     $totalFks. (Keeping $totalFoundFksToKeep.)

  Estimated size of output mask set: $estimatedOutputRows rows. ($estimatedShrinkFactor% smaller.)

"@

Write-Log $indexMessage
Write-Output $indexMessage

Write-Log
Write-Log "Creating new stream reader object to read the mask set line by line."
$masksetReader = New-Object System.IO.StreamReader($maskSet)
$tablesIndexReader = New-Object System.IO.StreamReader($tableIndex)
$indexesIndexReader = New-Object System.IO.StreamReader($indexIndex)
$fksIndexReader = New-Object System.IO.StreamReader($fkIndex)
$triggersIndexReader = New-Object System.IO.StreamReader($triggerIndex)

Write-Log
$currentTime = (Get-Date).ToString(“s”)
$message = "Creating new mask set at: $outMaskSet"
Write-Output "$currentTime $message"

$sourceLineNumber = 0
$outLineNumber = 0
$copyLine = $true
while (($current_line = $masksetReader.ReadLine()) -ne $null) {
    if (($sourceLineNumber -gt $keyLineNumbers[0]) -and ($sourceLineNumber -lt $keyLineNumbers[1])){
        # table node
        if ($current_line.trim() -like "<DMSSchemaEntity_Table>"){
            $thisTableIndex = $tablesIndexReader.ReadLine()
            $copyTable = $thisTableIndex.Split(",")[0] 
            $tableName = $thisTableIndex.Split(",")[1]
            # Write-Log "  Reading table: $tableName at line $sourceLineNumber. Copy set to: $copyTable."
            if ($copyTable -like "0"){
                $copyLine = $false
            }
        }
        if ($copyLine) {
            Add-Content $outMaskSet "$current_line"
            $outLineNumber++
        }
        if ($current_line.trim() -like "</DMSSchemaEntity_Table>"){
            # reached the end of the table node, setting $copyLine back to true for next run
            $copyLine = $true
        }
    }
    elseif (($sourceLineNumber -gt $keyLineNumbers[2]) -and ($sourceLineNumber -lt $keyLineNumbers[3])){
        # index node
        if ($current_line.trim() -like "<DMSSchemaEntity_Index>"){
            $thisIndexIndex = $indexesIndexReader.ReadLine()
            $copyIndex = $thisIndexIndex.Split(",")[0] 
            $indexName = $thisIndexIndex.Split(",")[1]
            # Write-Log "  Reading index: $indexName at line $sourceLineNumber. Copy set to: $copyIndex."
            if ($copyIndex -like "0"){
                $copyLine = $false
            }
        }
        if ($copyLine) {
            Add-Content $outMaskSet "$current_line"
            $outLineNumber++
        }
        if ($current_line.trim() -like "</DMSSchemaEntity_Index>"){
            # reached the end of the table node, setting $copyLine back to true for next run
            $copyLine = $true
        }
    }  
    elseif (($sourceLineNumber -gt $keyLineNumbers[4]) -and ($sourceLineNumber -lt $keyLineNumbers[5])){
        # fk node
        if ($current_line.trim() -like "<DMSSchemaEntity_ForeignKey>"){
            $thisFkIndex = $fksIndexReader.ReadLine()
            $copyFk = $thisFkIndex.Split(",")[0] 
            $fkName = $thisFkIndex.Split(",")[1]
            # Write-Log "  Reading index: $fkName at line $sourceLineNumber. Copy set to: $copyFk."
            if ($copyFk -like "0"){
                $copyLine = $false
            }
        }
        if ($copyLine) {
            Add-Content $outMaskSet "$current_line"
            $outLineNumber++
        }
        if ($current_line.trim() -like "</DMSSchemaEntity_ForeignKey>"){
            # reached the end of the table node, setting $copyLine back to true for next run
            $copyLine = $true
        }        
    }
    else {
        # either a trigger node, or something else. Copy always.
        Add-Content $outMaskSet "$current_line"
        $outLineNumber++
    }

    $sourceLineNumber++
    if (($sourceLineNumber % $readLogFrequency -eq 0) -or ($outLineNumber % $writeLogFrequency -eq 0)){
        # Periodic logging of progress
        $readPercentComplete = [math]::Round(($sourceLineNumber / $totalLines) * 100)
        $writePercentComplete = [math]::Round(($outLineNumber / $estimatedOutputRows) * 100)
        $currentTime = (Get-Date).ToString(“s”)
        $resourceMessage = Get-ResourceUtilization
        $progressMessage = "  Read $sourceLineNumber / $totalLines ($readPercentComplete%). Written $outLineNumber / (estimated) $estimatedOutputRows ($writePercentComplete%). $resourceMessage"
        Write-Output "$currentTime $progressMessage"
        Write-Log "$progressMessage"
    }
}

# Final progress update
$readPercentComplete = [math]::Round(($sourceLineNumber / $totalLines) * 100)
$writePercentComplete = [math]::Round(($outLineNumber / $estimatedOutputRows) * 100)
$currentTime = (Get-Date).ToString(“s”)
$resourceMessage = Get-ResourceUtilization
$progressMessage = "  Read $sourceLineNumber / $totalLines ($readPercentComplete%). Written $outLineNumber / (estimated) $estimatedOutputRows ($writePercentComplete%). $resourceMessage"
Write-Output "$currentTime $progressMessage"
Write-Log "$progressMessage"

$masksetReader.Close()
$tablesIndexReader.Close()

Write-Output "$currentTime Finished."
Write-Log "Finished."
