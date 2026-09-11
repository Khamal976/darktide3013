# Darktide 3013 setup for zapret-discord-youtube (Flowseal) 1.9+ / 1.10.x
# Creates darktide*.bat next to every general*.bat and adds the game's domains to the user hostlist.
# Generated bats self-elevate (auto UAC) and run winws in a VISIBLE window.
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

# self-elevation, injected right after "@echo off"
$elevate = @(
  'net session >nul 2>&1 && goto :dt_admin_ok',
  'powershell -NoProfile -Command "Start-Process -Verb RunAs -FilePath ''%~f0''"',
  'exit /b',
  ':dt_admin_ok'
)
# shown only if winws exits (foreground run); ASCII so it is readable on any console
$exitmsg = @(
  '',
  'echo.',
  'echo ==================================================================',
  'echo  winws has STOPPED - zapret is NOT active now.',
  'echo  Try another strategy: darktide (ALT).bat, ALT2, ALT3 ... ALT11.',
  'echo  If every strategy stops at once, reboot Windows and run again.',
  'echo ==================================================================',
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
  # b) run winws in the foreground (visible window) instead of minimized
  $text = $text.Replace('start "zapret: %~n0" /min "%BIN%winws.exe"', '"%BIN%winws.exe"')
  # c) rebuild line by line: self-elevate, kill previous winws, add STUN-first UDP profile
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
  foreach ($m in $exitmsg) { $out.Add($m) }
  # d) if the strategy has a game-filter UDP profile, use the STUN payload there too (community fix)
  $result = ($out -join "`r`n") -replace 'ACTIVE_GAME_UDP\.bin', 'stun.bin'
  [System.IO.File]::WriteAllText($dst, $result, $utf8)
  $made++
  Say ("[ok] " + (Split-Path -Leaf $dst))
}
Say ''
Say ("Done: " + $made + " darktide*.bat created.")
Say 'How to use: double-click darktide.bat. Accept the UAC prompt. A window opens and stays.'
Say '  Lines like "windivert initialized. capture is started." = it works, keep the window open, launch the game.'
Say '  If the window shows "winws has STOPPED" and pauses, try darktide (ALT).bat, ALT2, ALT3 and so on.'
Say 'Как пользоваться: запустите darktide.bat двойным щелчком, согласитесь на UAC. Откроется окно и останется.'
Say '  Строки вида "windivert initialized. capture is started." = работает: не закрывайте окно, запускайте игру.'
Say '  Если окно пишет "winws has STOPPED" и ждёт нажатия — пробуйте darktide (ALT).bat, ALT2, ALT3 и т.д.'
