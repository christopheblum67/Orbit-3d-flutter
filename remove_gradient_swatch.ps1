$content = Get-Content 'lib/features/profile/profile_edit_screen.dart' -Raw
$content = $content -replace '(?s)class _GradientSwatch extends StatelessWidget \{.*?\}\n', ''
Set-Content 'lib/features/profile/profile_edit_screen.dart' -Value $content