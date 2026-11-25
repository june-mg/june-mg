# organize-desktop.ps1
# Sorts everything on your Desktop into 5 folders:
#   Projects   - any folders already on the Desktop (including an existing "projects" folder)
#   Documents  - PDFs, Word, Excel, PowerPoint, text files
#   Media      - images, videos, audio, design files
#   Shortcuts  - app shortcuts and web links
#   Inbox      - everything else (zips, installers, unknown files). Sort this weekly.
#
# It only MOVES files. It never deletes anything.
#
# Preview only (changes nothing):  powershell -ExecutionPolicy Bypass -File organize-desktop.ps1
# Do it for real:                  powershell -ExecutionPolicy Bypass -File organize-desktop.ps1 -Run
# Put everything back:             powershell -ExecutionPolicy Bypass -File organize-desktop.ps1 -Undo

param([switch]$Run, [switch]$Undo)

$desk    = [Environment]::GetFolderPath('Desktop')   # handles OneDrive Desktop too
$targets = 'Projects','Documents','Media','Shortcuts','Inbox'
$logPath = Join-Path $desk 'Inbox\_desktop-cleanup-log.csv'

$map = @{
  Documents = '.pdf','.doc','.docx','.txt','.rtf','.odt','.md','.xls','.xlsx','.csv','.ppt','.pptx','.pages','.numbers','.key'
  Media     = '.jpg','.jpeg','.png','.gif','.webp','.heic','.bmp','.tif','.tiff','.svg','.psd','.ai',
              '.mp4','.mov','.avi','.mkv','.webm','.wmv','.mp3','.wav','.m4a','.aac','.flac'
  Shortcuts = '.lnk','.url'
}

if ($Undo) {
  if (-not (Test-Path -LiteralPath $logPath)) { Write-Host "No log found at $logPath. Nothing to undo."; exit }
  $rows = Import-Csv -LiteralPath $logPath
  [array]::Reverse($rows)
  foreach ($r in $rows) {
    if (Test-Path -LiteralPath $r.To) {
      Move-Item -LiteralPath $r.To -Destination $r.From
      Write-Host "Restored: $($r.From)"
    }
  }
  Remove-Item -LiteralPath $logPath
  Write-Host "Undo finished. Empty folders were left in place; delete them by hand if you want."
  exit
}

function Get-Dest($item) {
  if ($item.PSIsContainer) { return 'Projects' }
  $ext = $item.Extension.ToLower()
  foreach ($k in $map.Keys) { if ($map[$k] -contains $ext) { return $k } }
  return 'Inbox'
}

function Get-FreePath($dir, $item) {
  $p = Join-Path $dir $item.Name
  if (-not (Test-Path -LiteralPath $p)) { return $p }
  if ($item.PSIsContainer) { $base = $item.Name; $ext = '' }
  else { $base = $item.BaseName; $ext = $item.Extension }
  $i = 2
  do { $p = Join-Path $dir "$base ($i)$ext"; $i++ } while (Test-Path -LiteralPath $p)
  return $p
}

$items = Get-ChildItem -LiteralPath $desk -Force | Where-Object {
  ($targets -notcontains $_.Name) -and
  -not ($_.Attributes -band [IO.FileAttributes]::Hidden) -and
  -not ($_.Attributes -band [IO.FileAttributes]::System)
}

if (-not $items) { Write-Host "Desktop is already clean."; exit }

$plan = foreach ($it in $items) {
  [pscustomobject]@{ Name = $it.Name; Folder = Get-Dest $it; Item = $it }
}

Write-Host ""
Write-Host "Desktop: $desk"
Write-Host ""
$plan | Sort-Object Folder, Name | Format-Table Folder, Name -AutoSize
$plan | Group-Object Folder | ForEach-Object { Write-Host ("{0,-10} {1} item(s)" -f $_.Name, $_.Count) }
Write-Host ""

if (-not $Run) {
  Write-Host "PREVIEW ONLY. Nothing was moved. Run again with -Run to do it."
  exit
}

foreach ($t in $targets) {
  $p = Join-Path $desk $t
  if (-not (Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Path $p | Out-Null }
}

$log = New-Object System.Collections.Generic.List[object]
foreach ($row in $plan) {
  $dest = Get-FreePath (Join-Path $desk $row.Folder) $row.Item
  try {
    Move-Item -LiteralPath $row.Item.FullName -Destination $dest -ErrorAction Stop
    $log.Add([pscustomobject]@{ From = $row.Item.FullName; To = $dest })
  } catch {
    Write-Host "SKIPPED (in use or locked): $($row.Name)"
  }
}
$log | Export-Csv -LiteralPath $logPath -NoTypeInformation
Write-Host "Done. Moved $($log.Count) item(s). Log saved to $logPath (used by -Undo)."
