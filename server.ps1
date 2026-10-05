$port = 8080
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
try {
    $listener.Start()
    Write-Host "Local server running at: http://localhost:$port/bday.html"
    Write-Host "Press Ctrl+C to stop."

    $mimeTypes = @{
        ".html" = "text/html"
        ".htm"  = "text/html"
        ".css"  = "text/css"
        ".js"   = "application/javascript"
        ".jpg"  = "image/jpeg"
        ".jpeg" = "image/jpeg"
        ".png"  = "image/png"
        ".gif"  = "image/gif"
        ".svg"  = "image/svg+xml"
        ".json" = "application/json"
    }

    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $rawUrl = $request.RawUrl
        if ($rawUrl -eq "/" -or $rawUrl -eq "") {
            $rawUrl = "/bday.html"
        }

        # Remove query strings
        $cleanPath = $rawUrl.Split('?')[0].TrimStart('/')
        $cleanPath = [System.Uri]::UnescapeDataString($cleanPath)
        $localPath = Join-Path (Get-Location) $cleanPath

        if (Test-Path $localPath -PathType Leaf) {
            $ext = [System.IO.Path]::GetExtension($localPath).ToLower()
            $mime = if ($mimeTypes.ContainsKey($ext)) { $mimeTypes[$ext] } else { "application/octet-stream" }
            $response.ContentType = $mime
            
            # CORS and No-Cache headers
            $response.AddHeader("Access-Control-Allow-Origin", "*")
            $response.AddHeader("Cache-Control", "no-cache, no-store, must-revalidate")
            $response.AddHeader("Pragma", "no-cache")
            $response.AddHeader("Expires", "0")

            $bytes = [System.IO.File]::ReadAllBytes($localPath)
            $response.ContentLength64 = $bytes.Length
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $response.StatusCode = 404
            $notFound = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found")
            $response.OutputStream.Write($notFound, 0, $notFound.Length)
        }
        $response.OutputStream.Close()
    }
} finally {
    $listener.Stop()
}
