# Darktide 3013 setup for zapret-discord-youtube (Flowseal) 1.9+ / 1.10.x
# Creates darktide*.bat next to every general*.bat and adds the game's domains to the user hostlist.
# Generated bats self-elevate (auto UAC) and report whether winws actually started.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Say($s) { Write-Host $s }

if (-not (Test-Path (Join-Path $root 'general.bat'))) {
  Say 'ERROR: general.bat not found. Put darktide-setup.bat and darktide-setup.ps1 into the zapret folder (next to general.bat) and run again.'
  Say 'ОШИБКА: general.bat не найден. Положите darktide-setup.bat и darktide-setup.ps1 в папку zapret (рядом с general.bat) и запустите снова.'
  exit 1
}
if (-not (Test-Path (Join-Path $root 'bin\stun.bin'))) {
  Say 'ERROR: bin\stun.bin not found. This setup needs zapret-discord-youtube 1.9 or newer.'
  Say 'ОШИБКА: нет bin\stun.bin. Нужна сборка zapret-discord-youtube 1.9 или новее.'
  exit 1
}

# 1) game domains -> lists\list-general-user.txt
$userList = Join-Path $root 'lists\list-general-user.txt'
$domains = @('atoma.cloud','atoma-discovery.com')
$existing = @()
if (Test-Path $userList) { $existing = [System.IO.File]::ReadAllLines($userList) }
$added = @()
foreach ($d in $domains) { if ($existing -notcontains $d) { $existing += $d; $added += $d } }
[System.IO.File]::WriteAllLines($userList, $existing, $utf8)
if ($added.Count) { Say ("[lists] added to list-general-user.txt: " + ($added -join ', ')) } else { Say '[lists] list-general-user.txt already has the game domains' }

# blocks injected into every generated darktide*.bat
$elevate = @(
  'net session >nul 2>&1 && goto :dt_admin_ok',
  'powershell -NoProfile -Command "Start-Process -Verb RunAs -FilePath ''%~f0''"',
  'exit /b',
  ':dt_admin_ok'
)
$verify = @(
  '',
  'echo.',
  'ping -n 3 127.0.0.1 >nul',
  'tasklist /FI "IMAGENAME eq winws.exe" | find /I "winws.exe" >nul && goto :dt_ok',
  'echo [X] zapret не запустился на этой стратегии.',
  'echo     Закройте это окно и попробуйте другую: darktide (ALT).bat, ALT2, ALT3 и далее.',
  'echo.',
  'pause',
  'exit /b',
  ':dt_ok',
  'echo [OK] zapret работает. Запускайте игру.',
  'echo     Это окно можно закрыть, защита останется в фоне.',
  'echo.',
  'pause'
)
$udpProfile = '--filter-udp=35000-36000 --dpi-desync=fake --dpi-desync-any-protocol=1 --dpi-desync-repeats=10 --dpi-desync-fake-unknown-udp="%BIN%stun.bin" --dpi-desync-cutoff=n4 --new ^'

# 2) darktide*.bat from every general*.bat
$made = 0
Get-ChildItem -Path $root -Filter 'general*.bat' | ForEach-Object {
  $src = $_.FullName
  $dst = Join-Path $root ($_.Name -replace '^general', 'darktide')
  $text = [System.IO.File]::ReadAllText($src, $utf8)
  if ($text -notmatch '--wf-udp=') { Say ("[skip] " + $_.Name + ": no --wf-udp"); return }
  # a) let winws see the hub ports
  $text = $text -replace '--wf-udp=', '--wf-udp=35000-36000,'
  # b) rebuild line by line: self-elevate, kill previous winws, add STUN-first UDP profile
  $lines = $text -split "`r?`n"
  $out = New-Object System.Collections.Generic.List[string]
  $elevated = $false; $killed = $false; $inserted = $false
  foreach ($line in $lines) {
    $out.Add($line)
    if (-not $elevated -and $line -match '^@echo off') { foreach ($e in $elevate) { $out.Add($e) }; $elevated = $true }
    if (-not $killed -and $line -match '^cd /d "%~dp0"') { $out.Add('tasklist /FI "IMAGENAME eq winws.exe" | find /I "winws.exe" >nul && taskkill /IM winws.exe /F >nul'); $killed = $true }
    if (-not $inserted -and $line -match 'winws\.exe' -and $line -match '--wf-udp=') { $out.Add($udpProfile); $inserted = $true }
  }
  if (-not $inserted) { Say ("[skip] " + $_.Name + ": winws line not found"); return }
  foreach ($v in $verify) { $out.Add($v) }
  # c) if the strategy has a game-filter UDP profile, use the STUN payload there too (community fix)
  $result = ($out -join "`r`n") -replace 'ACTIVE_GAME_UDP\.bin', 'stun.bin'
  [System.IO.File]::WriteAllText($dst, $result, $utf8)
  $made++
  Say ("[ok] " + (Split-Path -Leaf $dst))
}
Say ''
Say ("Done: " + $made + " darktide*.bat created.")
Say 'Next: double-click darktide.bat (it asks for admin by itself). It will say [OK] or [X].'
Say 'Дальше: запустите darktide.bat двойным щелчком (права администратора он запросит сам). В конце он напишет [OK] или [X]. Если [X] — попробуйте darktide (ALT).bat, ALT2 и т.д.'
