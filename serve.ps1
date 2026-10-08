$root = $PSScriptRoot
$l = New-Object System.Net.HttpListener; $l.Prefixes.Add('http://localhost:8765/'); $l.Start()
$types = @{ '.html'='text/html; charset=utf-8'; '.svg'='image/svg+xml'; '.jpg'='image/jpeg'; '.png'='image/png'; '.js'='text/javascript'; '.webmanifest'='application/manifest+json' }
while ($l.IsListening) {
  $c = $l.GetContext(); $p = [Uri]::UnescapeDataString($c.Request.Url.AbsolutePath.TrimStart('/')); if (!$p) { $p = 'index.html' }
  $f = Join-Path $root $p
  if (Test-Path $f -PathType Leaf) { $b = [IO.File]::ReadAllBytes($f); $c.Response.ContentType = $types[[IO.Path]::GetExtension($f)]; $c.Response.OutputStream.Write($b, 0, $b.Length) } else { $c.Response.StatusCode = 404 }
  $c.Response.Close()
}
