# Tiny static file server for Buddy Week on http://127.0.0.1:8765
# Listens only on this laptop; accepts any Host header so `tailscale serve` can proxy to it.
$root = $PSScriptRoot
$types = @{ '.html'='text/html; charset=utf-8'; '.svg'='image/svg+xml'; '.jpg'='image/jpeg'; '.png'='image/png'; '.js'='text/javascript'; '.css'='text/css'; '.webmanifest'='application/manifest+json' }
$server = New-Object System.Net.Sockets.TcpListener ([System.Net.IPAddress]::Loopback), 8765
$server.Start()
Write-Host "Buddy Week running at http://localhost:8765  (Ctrl+C to stop)"
while ($true) {
  $client = $server.AcceptTcpClient()
  try {
    $stream = $client.GetStream(); $stream.ReadTimeout = 2000; $stream.WriteTimeout = 5000
    $reader = New-Object System.IO.StreamReader $stream
    $line = $reader.ReadLine()
    while (($h = $reader.ReadLine()) -ne $null -and $h -ne '') { }
    $path = 'index.html'
    if ($line -match '^\S+\s+(\S+)') { $p = [Uri]::UnescapeDataString(($matches[1] -split '\?')[0].TrimStart('/')); if ($p) { $path = $p } }
    $file = [IO.Path]::GetFullPath((Join-Path $root $path))
    if ($file.StartsWith($root) -and (Test-Path $file -PathType Leaf)) {
      $body = [IO.File]::ReadAllBytes($file); $status = '200 OK'; $type = $types[[IO.Path]::GetExtension($file)]
      if (!$type) { $type = 'application/octet-stream' }
    } else {
      $body = [Text.Encoding]::UTF8.GetBytes('Not found'); $status = '404 Not Found'; $type = 'text/plain'
    }
    $head = [Text.Encoding]::ASCII.GetBytes("HTTP/1.1 $status`r`nContent-Type: $type`r`nContent-Length: $($body.Length)`r`nCache-Control: no-cache`r`nConnection: close`r`n`r`n")
    $stream.Write($head, 0, $head.Length); $stream.Write($body, 0, $body.Length); $stream.Flush()
  } catch { } finally { $client.Close() }
}
