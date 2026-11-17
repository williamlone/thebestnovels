$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$postsDir = Join-Path $root 'content/posts'
$outFile = Join-Path $root 'data/library.json'

$records = @()
foreach ($file in Get-ChildItem -LiteralPath $postsDir -Filter '*.md' | Sort-Object Name) {
  $raw = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
  if ($raw -notmatch '(?s)^---\s*\r?\n(?<front>.*?)\r?\n---\s*\r?\n(?<body>.*)$') { continue }
  $front = $Matches['front']
  $body = $Matches['body']
  if ($front -match '(?m)^draft:\s*true\s*$') { continue }

  $title = if ($front -match '(?m)^title:\s*"(.+)"\s*$') { $Matches[1] } else { $file.BaseName }
  $order = if ($front -match '(?m)^slug:\s*"(\d+)"\s*$') { [int]$Matches[1] } else { 0 }

  $tags = @()
  foreach ($match in [regex]::Matches($front, '(?m)^\s*-\s*"(.+)"\s*$')) {
    $tags += $match.Groups[1].Value
  }
  if ($tags.Count -eq 0) { continue }

  $book = $tags[0]
  $shortTitle = if ($title.StartsWith($book + ' ')) { $title.Substring($book.Length + 1) } else { $title }
  $isIntro = ($title -eq ($book + ' Introduction'))
  $author = ''
  $summary = ''
  if ($isIntro) {
    foreach ($line in ($body -split '\r?\n')) {
      if ($line.Trim() -match '^by\s+(.+)$') { $author = $Matches[1].Trim(); break }
    }
    $summary = (($body -replace '(?m)^by\s+.*$', '') -replace '\s+', ' ').Trim()
    if ($summary.Length -gt 220) { $summary = $summary.Substring(0, 220).TrimEnd() + '...' }
  }

  $words = @($body -split '\s+' | Where-Object { $_ -ne '' }).Count
  $records += [pscustomobject]@{
    Source  = $file.BaseName
    Book    = $book
    Title   = $shortTitle
    Order   = $order
    Author  = $author
    Summary = $summary
    IsIntro = $isIntro
    Words   = $words
    Empty   = (($body -replace '\s', '').Length -eq 0)
  }
}

$books = [ordered]@{}
$chapters = [ordered]@{}
foreach ($group in ($records | Group-Object Book)) {
  $book = $group.Name
  $ordered = @($group.Group | Sort-Object Order, Source)
  $intro = @($ordered | Where-Object { $_.IsIntro } | Select-Object -First 1)
  $author = if ($intro.Count -gt 0) { $intro[0].Author } else { '' }
  $summary = if ($intro.Count -gt 0) { $intro[0].Summary } else { '' }

  $chapterList = @()
  for ($i = 0; $i -lt $ordered.Count; $i++) {
    $current = $ordered[$i]
    $prev = if ($i -gt 0) { $ordered[$i - 1] } else { $null }
    $next = if ($i -lt $ordered.Count - 1) { $ordered[$i + 1] } else { $null }
    $chapterList += [ordered]@{
      order  = $current.Order
      title  = $current.Title
      url    = "/posts/$($current.Source)/"
      source = $current.Source
    }
    $chapters[$current.Source] = [ordered]@{
      book      = $book
      index     = $i
      order     = $current.Order
      count     = $ordered.Count
      title     = $current.Title
      prevUrl   = if ($prev) { "/posts/$($prev.Source)/" } else { '' }
      prevTitle = if ($prev) { $prev.Title } else { '' }
      nextUrl   = if ($next) { "/posts/$($next.Source)/" } else { '' }
      nextTitle = if ($next) { $next.Title } else { '' }
      words     = $current.Words
      empty     = $current.Empty
    }
  }

  $books[$book] = [ordered]@{
    title    = $book
    author   = $author
    summary  = $summary
    count    = $ordered.Count
    chapters = $chapterList
  }
}

$payload = [ordered]@{ books = $books; chapters = $chapters }
$json = $payload | ConvertTo-Json -Depth 8
[System.IO.File]::WriteAllText($outFile, $json, [System.Text.UTF8Encoding]::new($false))
Write-Host "Wrote $outFile with $($books.Count) books and $($chapters.Count) chapters."
