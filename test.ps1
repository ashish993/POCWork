# Log in to your Azure account
Connect-AzAccount

# Set the parameters
$ResourceGroupName = "yourResourceGroupName"
$TimeSpan = 30 # Specify the time span in days

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

# Function to get VM metrics and identify underutilization
function Get-VMMetrics {
    param (
        [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine]$VM
    )
    
    $resourceId = $VM.Id
    $vmSize = Get-AzVMSize -Location $VM.Location | Where-Object { $_.Name -eq $VM.HardwareProfile.VmSize }
    $totalMemory = $vmSize.MemoryInMB * 1024 * 1024 # Convert MB to bytes

    # Fetch CPU metrics
    $cpuMetrics = Get-MetricData -ResourceId $resourceId -MetricName "Percentage CPU" -StartTime $StartTime -EndTime $EndTime
    $averageCpu = ($cpuMetrics | Measure-Object Average -Property Average).Average
    $maxCpu = ($cpuMetrics | Measure-Object Maximum -Property Maximum).Maximum
    $minCpu = ($cpuMetrics | Measure-Object Minimum -Property Minimum).Minimum

    # Fetch Memory metrics
    $memoryMetrics = Get-MetricData -ResourceId $resourceId -MetricName "Available Memory Bytes" -StartTime $StartTime -EndTime $EndTime
    $averageMemory = ($memoryMetrics | Measure-Object Average -Property Average).Average
    $maxMemory = ($memoryMetrics | Measure-Object Maximum -Property Maximum).Maximum

    # Calculate memory usage percentage
    $usedMemoryPercentage = (($totalMemory - $averageMemory) / $totalMemory) * 100

    # Identify underutilized VMs
    $cpuThreshold = 20 # Define your threshold for CPU underutilization
    $memoryThreshold = 20 # Define your threshold for Memory underutilization (80% or more utilization)

    $isUnderutilized = $averageCpu -lt $cpuThreshold -and $usedMemoryPercentage -lt $memoryThreshold

    # Recommend new size if underutilized
    $recommendedSize = $null
    if ($isUnderutilized) {
        $recommendedSize = Get-AzVMSize -Location $VM.Location | Where-Object { $_.NumberOfCores -lt $vmSize.NumberOfCores } | Sort-Object -Property NumberOfCores, MemoryInMB | Select-Object -First 1
    }

    return [PSCustomObject]@{
        VMName = $VM.Name
        AverageCPU = [math]::Round($averageCpu, 2)
        MaxCPU = [math]::Round($maxCpu, 2)
        MinCPU = [math]::Round($minCpu, 2)
        AverageMemoryUsage = [math]::Round(($totalMemory - $averageMemory) / 1MB, 2)
        MaxMemoryUsage = [math]::Round(($totalMemory - $maxMemory) / 1MB, 2)
        IsUnderutilized = $isUnderutilized
        RecommendedSize = if ($recommendedSize) { $recommendedSize.Name } else { "N/A" }
    }
}

# Get all VMs in the resource group
$vms = Get-AzVM -ResourceGroupName $ResourceGroupName

# Get metrics for all VMs
$vmMetrics = $vms | ForEach-Object { Get-VMMetrics -VM $_ }

# Display results in a table format
$vmMetrics | Format-Table -Property VMName, AverageCPU, MaxCPU, MinCPU, AverageMemoryUsage, MaxMemoryUsage, IsUnderutilized, RecommendedSize -AutoSize

# Export the results to a CSV file
$vmMetrics | Export-Csv -Path "VM_Metrics_Report.csv" -NoTypeInformation
