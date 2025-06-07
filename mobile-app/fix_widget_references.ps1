$content = Get-Content 'lib/main.dart'

# Fix line 781 (DashboardScreen _addToFavorites method)
$content[780] = $content[780] -replace 'widget\.firebaseEnabled', 'firebaseEnabled'

# Fix line 917 (FavoritesScreen _buildSummaryContent method)  
$content[916] = $content[916] -replace 'widget\.firebaseEnabled', 'firebaseEnabled'

# Fix line 978 (FavoritesScreen _removeFromFavorites method)
$content[977] = $content[977] -replace 'widget\.firebaseEnabled', 'firebaseEnabled'

$content | Set-Content 'lib/main.dart'

Write-Host "✅ Fixed widget.firebaseEnabled errors on lines 781, 917, and 978"
Write-Host "🚀 Ready to run: flutter run" 