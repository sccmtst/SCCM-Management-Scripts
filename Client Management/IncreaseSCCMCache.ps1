$Cache = Get-WmiObject -Namespace 'ROOT\CCM\SoftMgmtAgent' -Class CacheConfig
$Cache.Size = '5000'
$Cache.Put()
Restart-Service -Name CcmExec