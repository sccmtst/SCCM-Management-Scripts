
try {
    Stop-Service -Name CcmExec -ErrorAction Stop
}
catch {
    Write-Error "Could not stop CcmExec Service: $_"
}

$Cache = Get-WmiObject -Namespace 'ROOT\CCM\SoftMgmtAgent' -Class CacheConfig
$Cache.Size = '5000'
$Cache.Put()
Start-Service -Name CcmExec