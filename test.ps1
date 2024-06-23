# Log in to your Azure account
Connect-AzAccount

# Set the parameters
$ResourceGroupName = "yourResourceGroupName"
$VMName = "yourVMName"
$TimeSpan = 30 # Specify the time span in days

# Get the VM resource ID
$vm = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName
$resourceId = $vm.Id

# Get the start and end times for the metrics
$EndTime = Get-Date
$StartTime = $EndTime.AddDays(-$TimeSpan)

# Function to fetch metric data
function Get-MetricData {
    param (
        [string]$ResourceId,
        [string]$MetricName,
        [datetime]$StartTime,
        [datetime]$EndTime
    )

    $metrics = Get-AzMetric -ResourceId $ResourceId `
                            -TimeGrain "PT1H" `
                            -StartTime $StartTime `
                            -EndTime $EndTime `
                            -MetricName $MetricName

    return $metrics.Data
}

# Fetch CPU metrics
$cpuMetrics = Get-MetricData -ResourceId $resourceId -MetricName "Percentage CPU" -StartTime $StartTime -EndTime $EndTime
$averageCpu = ($cpuMetrics | Measure-Object Average -Property Average).Average
$maxCpu = ($cpuMetrics | Measure-Object Maximum -Property Maximum).Maximum
$minCpu = ($cpuMetrics | Measure-Object Minimum -Property Minimum).Minimum

# Fetch Memory metrics
$memoryMetrics = Get-MetricData -ResourceId $resourceId -MetricName "Available Memory Bytes" -StartTime $StartTime -EndTime $EndTime
$averageMemory = ($memoryMetrics | Measure-Object Average -Property Average).Average
$maxMemory = ($memoryMetrics | Measure-Object Maximum -Property Maximum).Maximum

# Output the results
Write-Output "CPU Metrics for VM $VMName in Resource Group $ResourceGroupName:"
Write-Output "Average CPU: $averageCpu%"
Write-Output "Maximum CPU: $maxCpu%"
Write-Output "Minimum CPU: $minCpu%"

Write-Output "`nMemory Metrics for VM $VMName in Resource Group $ResourceGroupName:"
Write-Output "Average Available Memory: $averageMemory bytes"
Write-Output "Maximum Available Memory: $maxMemory bytes"

# Identify underutilized VMs
$cpuThreshold = 20 # Define your threshold for CPU underutilization
$memoryThreshold = 0.8 # Define your threshold for Memory underutilization (80% or more utilization)

$vmSize = Get-AzVMSize -ResourceGroupName $ResourceGroupName -VMName $VMName
$totalMemory = $vmSize.MemoryInMB * 1024 * 1024 # Convert MB to bytes
$usedMemoryPercentage = (($totalMemory - $averageMemory) / $totalMemory) * 100

if ($averageCpu -lt $cpuThreshold -and $usedMemoryPercentage -lt $memoryThreshold) {
    Write-Output "VM $VMName is underutilized."
} else {
    Write-Output "VM $VMName is not underutilized."
}
