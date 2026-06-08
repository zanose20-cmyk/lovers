const fs = require('fs');
const path = require('path');
const readline = require('readline');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

function ask(q) {
  return new Promise(resolve => rl.question(q, resolve));
}

async function main() {
  console.log('');
  console.log('===================================');
  console.log('  Firebase Config Generator');
  console.log('===================================');
  console.log('');
  console.log('Go to: https://console.firebase.google.com');
  console.log('1. Create new project (or use existing)');
  console.log('2. Add Android app (package: com.example.lovers_app)');
  console.log('3. Download google-services.json');
  console.log('4. Add iOS app (bundle: com.example.loversApp)');
  console.log('5. Download GoogleService-Info.plist');
  console.log('');

  const projectId = await ask('Firebase Project ID: ');
  const androidKey = await ask('Android API Key: ');
  const iosKey = await ask('iOS API Key: ');

  // google-services.json for Android
  const androidConfig = {
    project_info: {
      project_number: '000000000000',
      project_id: projectId,
      storage_bucket: `${projectId}.appspot.com`
    },
    client: [{
      client_info: {
        mobilesdk_app_id: `1:000000000000:android:0000000000000000`,
        android_client_info: { package_name: 'com.example.lovers_app' }
      },
      oauth_client: [],
      api_key: [{ current_key: androidKey }],
      services: { appinvite_service: { other_platform_oauth_client: [] } }
    }],
    configuration_version: '1'
  };

  const androidPath = path.join(__dirname, '..', 'flutter', 'android', 'app', 'google-services.json');
  fs.writeFileSync(androidPath, JSON.stringify(androidConfig, null, 2));
  console.log(`\n✅ Written: ${androidPath}`);

  // .env backend
  const envPath = path.join(__dirname, '.env');
  let env = fs.readFileSync(envPath, 'utf8');
  env = env.replace(/# FIREBASE_PROJECT_ID=.*/m, `FIREBASE_PROJECT_ID=${projectId}`);
  fs.writeFileSync(envPath, env);
  console.log(`✅ Updated .env with FIREBASE_PROJECT_ID`);

  console.log('\nDone! Restart the app to use Firebase.');
  rl.close();
}

main().catch(e => { console.error(e); rl.close(); process.exit(1); });
