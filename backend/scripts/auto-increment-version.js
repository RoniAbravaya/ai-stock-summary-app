/**
 * Auto-increment version code in pubspec.yaml
 * Reads current version, increments build number, writes back
 */

const fs = require('fs');
const path = require('path');

function main() {
  const pubspecPath = path.resolve(__dirname, '../../mobile-app/pubspec.yaml');
  
  if (!fs.existsSync(pubspecPath)) {
    console.error('pubspec.yaml not found');
    process.exit(1);
  }
  
  let content = fs.readFileSync(pubspecPath, 'utf8');
  
  // Find version line: version: 1.0.0+10
  const versionMatch = content.match(/^version:\s*(.+?)\+(\d+)$/m);
  
  if (!versionMatch) {
    console.error('Version format not found in pubspec.yaml');
    process.exit(1);
  }
  
  const versionName = versionMatch[1];
  const currentBuildNumber = parseInt(versionMatch[2]);
  const newBuildNumber = currentBuildNumber + 1;
  const newVersion = `${versionName}+${newBuildNumber}`;
  
  // Replace version in content
  const newContent = content.replace(
    /^version:\s*.+$/m,
    `version: ${newVersion}`
  );
  
  // Write back to file
  fs.writeFileSync(pubspecPath, newContent, 'utf8');
  
  console.log(`${newVersion}`);
  return newVersion;
}

if (require.main === module) {
  main();
}

module.exports = main;
