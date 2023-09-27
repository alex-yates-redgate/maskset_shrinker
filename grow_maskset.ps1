<#
    Script to artificially increase the size of a mask set by inserting more tables.
    New tables are created by copying the DM_CUSTOMER table node, with a guid for the table name.
    Total number of tables added is defined by the $multiplyer variable. For example, if $multiplyer = 10, 10 new tables will be added after each existing table.
#>

# Config
$maskSet = "C:\git\maskset_shrinker\source.DMSMaskSet"
$out = "C:\deleteme\maskset_shrinker"
$multiplyer = 20

# DON'T CHANGE ANYTHING BELOW THIS LINE


if (-not (Test-Path $out)){
    New-Item -ItemType Directory -Path $out
}

$startTime = (Get-Date).ToString(“s”)
$startTimeWithoutPunctuation = $startTime.Replace(':','').Replace('-','')
$workingDir = "$out\$startTimeWithoutPunctuation"
$log = "$workingDir\log.txt"
$outMaskSet = "$workingDir\out-big.DMSMaskSet"

Write-Output "$startTime Creating working directory at: $workingDir"
Write-Output "$startTime For detailed log, see: $log"

New-Item -ItemType Directory -Path $workingDir | out-null
New-Item -ItemType File -Path $log | out-null
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


Write-Log "Creating new stream reader object to read the mask set line by line."
$masksetReader = New-Object System.IO.StreamReader($maskSet)

Write-Log
$currentTime = (Get-Date).ToString(“s”)
$message = "Creating new mask set at: $outMaskSet"
Write-Output "$currentTime $message"

$lineNumber = 0
$copyLine = $true
while (($current_line = $masksetReader.ReadLine()) -ne $null) {
    if ($current_line.trim() -like "<DMSSchemaEntity_Table>"){
        for ($i = 0; $i -lt $multiplyer; $i++){
            $guid = [guid]::NewGuid()
            $tableName = $guid.ToString()
            $newTableNode = @"
              <DMSSchemaEntity_Table>
                <N2KSQLServerEntity_Table>
                  <N2KSQLServerEntity />
                  <TableName Value="$tableName" />
                  <RowCountInDB Value="100" />
                  <IsTmp Value="False" />
                  <IsGTmp Value="False" />
                  <N2KSQLServerCollection_Column>
                    <DMSSchemaEntity_Column>
                      <N2KSQLServerEntity_Column>
                        <N2KSQLServerEntity />
                        <ColumnName Value="customer_id" />
                        <IsNullable Value="False" />
                        <IsIdentity Value="False" />
                        <ColumnDefault Value="" />
                        <DataType Value="varchar" />
                        <OrdinalPosition Value="1" />
                        <CharacterMaximumLength Value="10" />
                      </N2KSQLServerEntity_Column>
                      <PlanType Value="WANTMASK_UNKNOWN" />
                      <PlanComments Value="" />
                    </DMSSchemaEntity_Column>
                    <DMSSchemaEntity_Column>
                      <N2KSQLServerEntity_Column>
                        <N2KSQLServerEntity />
                        <ColumnName Value="customer_firstname" />
                        <IsNullable Value="True" />
                        <IsIdentity Value="False" />
                        <ColumnDefault Value="" />
                        <DataType Value="varchar" />
                        <OrdinalPosition Value="2" />
                        <CharacterMaximumLength Value="60" />
                      </N2KSQLServerEntity_Column>
                      <PlanType Value="WANTMASK_UNKNOWN" />
                      <PlanComments Value="" />
                    </DMSSchemaEntity_Column>
                    <DMSSchemaEntity_Column>
                      <N2KSQLServerEntity_Column>
                        <N2KSQLServerEntity />
                        <ColumnName Value="customer_lastname" />
                        <IsNullable Value="True" />
                        <IsIdentity Value="False" />
                        <ColumnDefault Value="" />
                        <DataType Value="varchar" />
                        <OrdinalPosition Value="3" />
                        <CharacterMaximumLength Value="60" />
                      </N2KSQLServerEntity_Column>
                      <PlanType Value="WANTMASK_UNKNOWN" />
                      <PlanComments Value="" />
                    </DMSSchemaEntity_Column>
                    <DMSSchemaEntity_Column>
                      <N2KSQLServerEntity_Column>
                        <N2KSQLServerEntity />
                        <ColumnName Value="customer_gender" />
                        <IsNullable Value="True" />
                        <IsIdentity Value="False" />
                        <ColumnDefault Value="" />
                        <DataType Value="varchar" />
                        <OrdinalPosition Value="4" />
                        <CharacterMaximumLength Value="1" />
                      </N2KSQLServerEntity_Column>
                      <PlanType Value="WANTMASK_UNKNOWN" />
                      <PlanComments Value="" />
                    </DMSSchemaEntity_Column>
                    <DMSSchemaEntity_Column>
                      <N2KSQLServerEntity_Column>
                        <N2KSQLServerEntity />
                        <ColumnName Value="customer_company_name" />
                        <IsNullable Value="True" />
                        <IsIdentity Value="False" />
                        <ColumnDefault Value="" />
                        <DataType Value="varchar" />
                        <OrdinalPosition Value="5" />
                        <CharacterMaximumLength Value="60" />
                      </N2KSQLServerEntity_Column>
                      <PlanType Value="WANTMASK_UNKNOWN" />
                      <PlanComments Value="" />
                    </DMSSchemaEntity_Column>
                    <DMSSchemaEntity_Column>
                      <N2KSQLServerEntity_Column>
                        <N2KSQLServerEntity />
                        <ColumnName Value="customer_street_address" />
                        <IsNullable Value="True" />
                        <IsIdentity Value="False" />
                        <ColumnDefault Value="" />
                        <DataType Value="varchar" />
                        <OrdinalPosition Value="6" />
                        <CharacterMaximumLength Value="60" />
                      </N2KSQLServerEntity_Column>
                      <PlanType Value="WANTMASK_UNKNOWN" />
                      <PlanComments Value="" />
                    </DMSSchemaEntity_Column>
                    <DMSSchemaEntity_Column>
                      <N2KSQLServerEntity_Column>
                        <N2KSQLServerEntity />
                        <ColumnName Value="customer_region" />
                        <IsNullable Value="True" />
                        <IsIdentity Value="False" />
                        <ColumnDefault Value="" />
                        <DataType Value="varchar" />
                        <OrdinalPosition Value="7" />
                        <CharacterMaximumLength Value="60" />
                      </N2KSQLServerEntity_Column>
                      <PlanType Value="WANTMASK_UNKNOWN" />
                      <PlanComments Value="" />
                    </DMSSchemaEntity_Column>
                    <DMSSchemaEntity_Column>
                      <N2KSQLServerEntity_Column>
                        <N2KSQLServerEntity />
                        <ColumnName Value="customer_country" />
                        <IsNullable Value="True" />
                        <IsIdentity Value="False" />
                        <ColumnDefault Value="" />
                        <DataType Value="varchar" />
                        <OrdinalPosition Value="8" />
                        <CharacterMaximumLength Value="60" />
                      </N2KSQLServerEntity_Column>
                      <PlanType Value="WANTMASK_UNKNOWN" />
                      <PlanComments Value="" />
                    </DMSSchemaEntity_Column>
                    <DMSSchemaEntity_Column>
                      <N2KSQLServerEntity_Column>
                        <N2KSQLServerEntity />
                        <ColumnName Value="customer_email" />
                        <IsNullable Value="True" />
                        <IsIdentity Value="False" />
                        <ColumnDefault Value="" />
                        <DataType Value="varchar" />
                        <OrdinalPosition Value="9" />
                        <CharacterMaximumLength Value="60" />
                      </N2KSQLServerEntity_Column>
                      <PlanType Value="WANTMASK_UNKNOWN" />
                      <PlanComments Value="" />
                    </DMSSchemaEntity_Column>
                    <DMSSchemaEntity_Column>
                      <N2KSQLServerEntity_Column>
                        <N2KSQLServerEntity />
                        <ColumnName Value="customer_telephone" />
                        <IsNullable Value="True" />
                        <IsIdentity Value="False" />
                        <ColumnDefault Value="" />
                        <DataType Value="varchar" />
                        <OrdinalPosition Value="10" />
                        <CharacterMaximumLength Value="60" />
                      </N2KSQLServerEntity_Column>
                      <PlanType Value="WANTMASK_UNKNOWN" />
                      <PlanComments Value="" />
                    </DMSSchemaEntity_Column>
                    <DMSSchemaEntity_Column>
                      <N2KSQLServerEntity_Column>
                        <N2KSQLServerEntity />
                        <ColumnName Value="customer_zipcode" />
                        <IsNullable Value="True" />
                        <IsIdentity Value="False" />
                        <ColumnDefault Value="" />
                        <DataType Value="varchar" />
                        <OrdinalPosition Value="11" />
                        <CharacterMaximumLength Value="60" />
                      </N2KSQLServerEntity_Column>
                      <PlanType Value="WANTMASK_UNKNOWN" />
                      <PlanComments Value="" />
                    </DMSSchemaEntity_Column>
                    <DMSSchemaEntity_Column>
                      <N2KSQLServerEntity_Column>
                        <N2KSQLServerEntity />
                        <ColumnName Value="credit_card_type_id" />
                        <IsNullable Value="True" />
                        <IsIdentity Value="False" />
                        <ColumnDefault Value="" />
                        <DataType Value="varchar" />
                        <OrdinalPosition Value="12" />
                        <CharacterMaximumLength Value="2" />
                      </N2KSQLServerEntity_Column>
                      <PlanType Value="WANTMASK_UNKNOWN" />
                      <PlanComments Value="" />
                    </DMSSchemaEntity_Column>
                    <DMSSchemaEntity_Column>
                      <N2KSQLServerEntity_Column>
                        <N2KSQLServerEntity />
                        <ColumnName Value="customer_credit_card_number" />
                        <IsNullable Value="True" />
                        <IsIdentity Value="False" />
                        <ColumnDefault Value="" />
                        <DataType Value="varchar" />
                        <OrdinalPosition Value="13" />
                        <CharacterMaximumLength Value="60" />
                      </N2KSQLServerEntity_Column>
                      <PlanType Value="WANTMASK_UNKNOWN" />
                      <PlanComments Value="" />
                    </DMSSchemaEntity_Column>
                  </N2KSQLServerCollection_Column>
                </N2KSQLServerEntity_Table>
                <PlanType Value="WANTMASK_UNKNOWN" />
                <PlanComments Value="" />
              </DMSSchemaEntity_Table>
"@
            Add-Content $outMaskSet "$newTableNode"
        }
        
    }
    Add-Content $outMaskSet "$current_line"
    $lineNumber++
    if ($lineNumber % 1000 -eq 0){
        # Periodic logging of progress
        $currentTime = (Get-Date).ToString(“s”)
        $message = "  Copied $lineNumber lines out of $totalLines."
        Write-Output "$currentTime $message"
        Write-Log "$message"
    }
}
$masksetReader.Close()


Write-Log "Finished."
Write-Output "Finished."