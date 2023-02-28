while($true) {
    Write-Host "***** Checking QB processes *****" -ForegroundColor Green
    # Check if QBWebConnector process is running
    $qbwebconnector = Get-Process "QBWebConnector" -ErrorAction SilentlyContinue
    if (!$qbwebconnector) {
    Write-Host "***** start QBWebConnector process *****" -ForegroundColor Green
        Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        # Start QBWebConnector if it is not running
        Start-Process "C:\Program Files (x86)\Common Files\Intuit\QuickBooks\QBWebConnector\QBWebConnector.exe"
    }
    # Check if QB process is running
    $qb = Get-Process "QBW32" -ErrorAction SilentlyContinue
    if (!$qb) {
        Write-Host "***** start QuickBooks process *****" -ForegroundColor Green
        Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        # Start QB if it is not running
        Start-Process "C:\Program Files (x86)\Intuit\QuickBooks Enterprise Solutions 21.0\QBW32EnterpriseWholesale.exe"
    }
    # Wait for 30 minutes
    Start-Sleep -Seconds (30 * 60)
}