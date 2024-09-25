# Obtiene las conexiones TCP en estado de escucha y agrupa por puerto
$connections = Get-NetTCPConnection -State Listen | 
    Group-Object -Property LocalPort |
    Select-Object @{Name='Puerto';Expression={$_.Name}}, 
                  @{Name='ID';Expression={$_.Group | Select-Object -First 1 -ExpandProperty OwningProcess}} |
    Sort-Object Puerto

# Itera sobre cada puerto para obtener el nombre del proceso
$results = $connections | ForEach-Object {
    $processId = $_.ID
    
    # Ejecuta tasklist para obtener la información del proceso
    $processInfo = tasklist /FI "PID eq $processId" /FO LIST
    
    # Extrae el nombre del proceso desde "Nombre de imagen:"
    $processNameLine = $processInfo | Where-Object { $_ -match "^Nombre de imagen:" }
    $processName = if ($processNameLine) { ($processNameLine -replace "^Nombre de imagen:\s+", "").Trim() } else { "N/A" }
    
    # Crea un objeto personalizado con los resultados
    [PSCustomObject]@{
        Puerto     = $_.Puerto
        Aplicacion = $processName
        ID         = $processId
    }
}

# Muestra los resultados en una ventana de PowerShell
$results | Out-GridView -Title "Conexiones TCP en Escucha"

# Exporta los resultados a un archivo de texto
$results | Format-Table -AutoSize | Out-File -FilePath "puertos_abiertos.txt" -Encoding UTF8
