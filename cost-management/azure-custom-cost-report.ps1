<#

	=========================================================================
	THIS CODE-SAMPLE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER 
	EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES 	
	OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.	

	This sample is not supported under any Microsoft standard support program
	or service. The code sample is provided AS IS without warranty of any 
	kind. 

	Microsoft further disclaims all implied warranties including, without 
	limitation, any implied warranties of merchantability or of fitness for 
	a particular purpose. The entire risk arising out of the use or 
	performance of the sample and documentation remains with you. In no event 
	shall Microsoft, its authors, or anyone else involved in the creation, 
	production, or delivery of the script be liable for any damages 
	whatsoever (including, without limitation, damages for loss of business 
	profits, business interruption, loss of business information, or other 
	pecuniary loss) arising out of  the use of or inability to use the sample or 
	documentation, even if Microsoft has been advised of the possibility 
	of such damages.
	=========================================================================

#>



<#

    .SYNOPSIS
    With this script the billing data can be downloaded and processed and a custom cost report can be created.

    .DESCRIPTION
    With this script the billing data can be downloaded and processed and a custom cost report can be created.

    The usage detail report contains 40 different properties per cost item and all fields can be used in this script.

    Available fields and their index are listed below:

        AccountId[0]
        AccountName[1]
        AccountOwnerEmail[2]
        AdditionalInfo[3]
        ConsumedQuantity[4]
        ConsumedService[5]
        ConsumedServiceId[6]
        Cost[7]
        CostCenter[8]
        Date[9]
        DepartmentId[10]
        DepartmentName[11]
        InstanceId[12]
        MeterCategory[13]
        MeterId[14]
        MeterName[15]
        MeterRegion[16]
        MeterSubCategory[17]
        Product[18]
        ProductId[19]
        ResourceGroup[20]
        ResourceLocation[21]
        ResourceLocationId[22]
        ResourceRate[23]
        ServiceAdministratorId[24]
        ServiceInfo1[25]
        ServiceInfo2[26]
        StoreServiceIdentifier[27]
        SubscriptionGuid[28]
        SubscriptionId[29]
        SubscriptionName[30]
        Tags[31]
        UnitOfMeasure[32]
        PartNumber[33]
        ResourceGuid[34]
        OfferId[35]
        ChargesBilledSeparately[36]
        Location[37]
        ServiceName[38]
        ServiceTier[39]

    .PARAMETER EnrollmentNr
    The enrollment number of the enterprise agreement with Microsoft. The enrollment number can be viewed in the EA portal (https://ea.azure.com/).

    .PARAMETER AccessKey
    The access key for the enterprise agreement. The access key can be generated, viewed and renewed in the EA portal (https://ea.azure.com/).

    Attention: The access key must be renewed every 6 month. If the key has expired, this script no longer works. 

    .PARAMETER BillingPeriod
    Use yyyyMM to specify the billing period. If the costs for January 2020 have to be reported, the billing period 202001 must be specified.

    .PARAMETER TagList
    If tags should be added and processed as well, then this parameter can be used to add the relevant tag names. If there is a tag name like "Environment", then this tag name can be added in the 'TagList' field.
    The script will add a property with the tag name in 'TagList' and will add the value(s). This allows to report tags or to group all the costs per tags, if needed (needs few adjustments).

    .PARAMETER UsageDetailData
    This parameter specifies the path and the name for the file that will be downloaded from the EA portal (original raw data).

    If the parameter 'SkipDownload' is set to '$True', then the raw data must be present locally. This parameter specifies the path and the name to the local raw data file.

    .PARAMETER Report
    Specify the path and the file name for the final custom cost report. 
    
    .PARAMETER UpscaleFactor
    With this parameter the sum can be increased by factor x to include internal costs, for example. The default value is 1 to export the real costs.
    
    .PARAMETER SkipDownload
    This parameter can be used to skip the download of the raw data from the EA portal and is mostly used for testing purposes. 

    The default setting is $false, so the raw data file will be downloaded from the EA portal.

    If the raw data exists locally, then specify the path and file name with the parameter 'UsageDetailData' and set the parameter 'SkipDownload' to '$True'. The local file will be used.
    
    .PARAMETER CultureInfo
    Specify the culture info for the final report.

    Use "de-de" for german or "en-us" for english formats. 

    More information can be found at https://docs.microsoft.com/en-us/dotnet/api/system.globalization.culturetypes?view=netframework-4.7.2.

    .PARAMETER Delimiter
    Specify the delimiter for the customized report. The default value is set to ",".

    .EXAMPLE
    The easiest way is to store all necessary parameters as a default value in the param block.
    
    "Azure Custom Report.ps1"

    .EXAMPLE
    The parameters can be added while starting the script as well.

    "Azure Custom Report.ps1" -EnrollmentNo "123456" -AccessKey "asdfjkl..." -BillingPeriod "201811" -Export "C:\Temp\MyReport.csv"

    .EXAMPLE
    "Azure Custom Report.ps1" -EnrollmentNo "123456" -AccessKey "asdfjkl..." -BillingPeriod "201811" -TagList @("Environment","SLA") -Export "C:\Temp\MyReport.csv" -CultureInfo "de-de" -Delimiter ";"

#>



param (

  [Parameter(Mandatory = $False)][string]$EnrollmentNo = "", 
  [Parameter(Mandatory = $False)][string]$Accesskey = "",
  [Parameter(Mandatory = $False)][string]$BillingPeriod = "202009", 
  [Parameter(Mandatory = $False)][string[]]$TagList = @(), 
  [Parameter(Mandatory = $False)][string]$UsageDetailData = "C:\Temp\UsageDetailData.csv",
  [Parameter(Mandatory = $False)][string]$Report = "C:\Temp\Azure Custom Report.csv",
  [Parameter(Mandatory = $False)][decimal]$UpscaleFactor = 1,	
  [Parameter(Mandatory = $False)][boolean]$SkipDownload = $False,	
  [Parameter(Mandatory = $False)][string]$CultureInfo = "en-us",
  [Parameter(Mandatory = $False)][string]$Delimiter = ","

)



$Error.Clear()

If(!($EnrollmentNo -and $AccessKey)){
    Throw "Enrollment number or access key is missing ..."
}



If([System.IO.Directory]::Exists([System.IO.Path]::GetDirectoryName($UsageDetailData)) -eq $false){
    Throw "Path $([System.IO.Path]::GetDirectoryName($UsageDetailData)) doesn't exist ..."
}



If([System.IO.Directory]::Exists([System.IO.Path]::GetDirectoryName($Report)) -eq $false){
    Throw "Path $([System.IO.Path]::GetDirectoryName($Report)) doesn't exist ..."
}



If($SkipDownload -eq $false){
    $URL = "https://consumption.azure.com/v3/enrollments/" + $EnrollmentNo + "/usagedetails/download?billingPeriod=" + $BillingPeriod + ""
    $AuthHeaders = @{"authorization"="bearer $AccessKey";"api-version"="1.0"}
    Invoke-WebRequest $URL -Headers $AuthHeaders -OutFile $UsageDetailData -ErrorAction Stop
}



$arrUsageDetails = @()
$StreamReader = @()
$StreamReader = New-Object System.IO.StreamReader $UsageDetailData

For($I = 0; $I -lt 3; $I++){
    $StreamReader.ReadLine() | Out-Null
}



While($StreamReader.EndOfStream -eq $False){

    ### If additional fields are necessary, they can be added at the end of the next line
    $objUsageDetails = New-Object System.Object | Select-Object -Property Subscription, AccountName, DepartmentName, Sum
    $TagList | Foreach-Object {$objUsageDetails | Add-Member -MemberType NoteProperty -Name $_ -Value ""}
    $Stream = ($StreamReader.ReadLine()) -Replace ",(?=[^{]*})",";" -replace """","" -split ","
    
    ### Next line can be copied and pasted to add more fields, see available fields and their index in the help section
    $objUsageDetails.Subscription = [string]$Stream[30]
    $objUsageDetails.AccountName = [string]$Stream[1]
    $objUsageDetails.DepartmentName = [string]$Stream[11]
    $objUsageDetails.Sum = [string]$Stream[7] 

    If($TagList){
        If($Stream[31].Length -gt 0){
            $Tag = $Stream[31] -replace "{","" -replace "}","" -replace " ","" -split ";"
            For($Counter = 0; $Counter -lt $Tag.Count; $Counter++){
                Try{
                    If($Tag[$Counter].Substring(0, $Tag[$Counter].IndexOf(":")) -in $TagList){
                        $objUsageDetails.($Tag[$Counter].Substring(0, $Tag[$Counter].IndexOf(":"))) = $Tag[$Counter].Substring($Tag[$Counter].IndexOf(":") +1)
                    }
                }
                Catch{
                        
                }
            }
        }
    }

    $arrUsageDetails += $objUsageDetails

}
$StreamReader.Close()



$Culture = New-Object System.Globalization.CultureInfo($CultureInfo)
$arrUsageDetails | Group-Object -Property Subscription | ForEach-Object -Process {
    
    [PSCustomObject]@{
        ### Next line can be copied and pasted to add more fields, use the property name as specified in line 201
		    SubscriptionName = $_.Values[0]
        AccountName = $_.Group[0].AccountName
        DepartmentName = $_.Group[0].DepartmentName
        BillingPeriod = $BillingPeriod
        Sum = $([System.Math]::Round(([decimal]($_.Group.Sum | Measure-Object -Sum).Sum * $UpscaleFactor), 2).ToString($Culture))
    }

} | Export-Csv -Path $Report -Delimiter "," -NoTypeInformation -Force



If($Error.Count -eq 0){
    Write-Host "Script completed successfully..."
}
