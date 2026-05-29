Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead('d:\Jobs\Memo\YtuongWeb.docx')
$entry = $zip.Entries | Where-Object { $_.FullName -eq 'word/document.xml' }
$reader = New-Object System.IO.StreamReader($entry.Open())
$xml = $reader.ReadToEnd()
$reader.Close()
$zip.Dispose()
$text = $xml -replace '</w:p>', "`n"
$text = $text -replace '<[^>]+>', ''
$text = [System.Net.WebUtility]::HtmlDecode($text)
$text | Out-File -FilePath 'd:\Jobs\Memo\YtuongWeb_extracted.txt' -Encoding UTF8
Write-Output "DONE"
