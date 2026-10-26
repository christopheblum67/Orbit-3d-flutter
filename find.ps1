$lines = @(Get-Content -Path pe_prev.txt);
for ($i=0; $i -lt $lines.Length; $i++) {
  if ($lines[$i] -like '*ProfileAvatarSelector*') {
    Write-Output ($i+1);
    break;
  }
}
