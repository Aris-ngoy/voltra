#!/usr/bin/env node
/*
  Add a Voltra Android widget receiver + provider files to a bare React Native app.

  Usage:
    node scripts/add-android-widget.js \
      --projectRoot /path/to/app \
      --package com.example.app \
      --widgetId voltra \
      --displayName "Voltra Widget" \
      --targetCellWidth 2 \
      --targetCellHeight 2 \
      --minCellWidth 2 \
      --minCellHeight 2
*/

const fs = require('fs');
const path = require('path');

const args = process.argv.slice(2);
const getArg = (name, fallback) => {
  const idx = args.indexOf(name);
  if (idx === -1) return fallback;
  return args[idx + 1] ?? fallback;
};

const projectRoot = path.resolve(getArg('--projectRoot', process.cwd()));
const packageName = getArg('--package');
const widgetId = getArg('--widgetId');
const displayName = getArg('--displayName', widgetId || 'Voltra Widget');
const targetCellWidth = Number(getArg('--targetCellWidth', '2'));
const targetCellHeight = Number(getArg('--targetCellHeight', '2'));
const minCellWidth = Number(getArg('--minCellWidth', '2'));
const minCellHeight = Number(getArg('--minCellHeight', '2'));

if (!packageName || !widgetId) {
  // eslint-disable-next-line no-console
  console.error('Missing required args: --package and --widgetId');
  process.exit(1);
}

const sanitizedId = widgetId.replace(/[^a-zA-Z0-9_]/g, '_');
const className = `VoltraWidget_${sanitizedId}Receiver`;
const receiverClassName = `.widget.${className}`;

const androidDir = path.join(projectRoot, 'android');
const appMainDir = path.join(androidDir, 'app', 'src', 'main');
const manifestPath = path.join(appMainDir, 'AndroidManifest.xml');
const resDir = path.join(appMainDir, 'res');
const resXmlDir = path.join(resDir, 'xml');
const resLayoutDir = path.join(resDir, 'layout');
const resValuesDir = path.join(resDir, 'values');
const kotlinDir = path.join(
  appMainDir,
  'java',
  ...packageName.split('.'),
  'widget'
);

const ensureDir = (dir) => {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, {recursive: true});
  }
};

ensureDir(resXmlDir);
ensureDir(resLayoutDir);
ensureDir(resValuesDir);
ensureDir(kotlinDir);

// 1) Kotlin receiver
const kotlinPath = path.join(kotlinDir, `${className}.kt`);
if (!fs.existsSync(kotlinPath)) {
  fs.writeFileSync(
    kotlinPath,
    `package ${packageName}.widget\n\nimport voltra.widget.VoltraWidgetReceiver\n\n/**\n * Auto-generated widget receiver for ${displayName}\n * Widget ID: ${widgetId}\n */\nclass ${className} : VoltraWidgetReceiver() {\n    override val widgetId: String = "${widgetId}"\n}\n`,
    'utf8'
  );
}

// 2) Widget provider info XML
const minWidth = minCellWidth * 70 - 30;
const minHeight = minCellHeight * 70 - 30;
const widgetInfoPath = path.join(resXmlDir, `voltra_widget_${widgetId}_info.xml`);
if (!fs.existsSync(widgetInfoPath)) {
  fs.writeFileSync(
    widgetInfoPath,
    `<?xml version="1.0" encoding="utf-8"?>\n<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"\n    android:minWidth="${minWidth}dp"\n    android:minHeight="${minHeight}dp"\n    android:targetCellWidth="${targetCellWidth}"\n    android:targetCellHeight="${targetCellHeight}"\n    android:updatePeriodMillis="0"\n    android:initialLayout="@layout/voltra_widget_placeholder"\n    android:resizeMode="horizontal|vertical"\n    android:widgetCategory="home_screen"\n    android:description="@string/voltra_widget_${widgetId}_description">\n</appwidget-provider>\n`,
    'utf8'
  );
}

// 3) Placeholder layout
const placeholderLayoutPath = path.join(resLayoutDir, 'voltra_widget_placeholder.xml');
if (!fs.existsSync(placeholderLayoutPath)) {
  fs.writeFileSync(
    placeholderLayoutPath,
    `<?xml version="1.0" encoding="utf-8"?>\n<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"\n    android:layout_width="match_parent"\n    android:layout_height="match_parent"\n    android:background="?android:attr/colorBackground">\n    <TextView\n        android:layout_width="wrap_content"\n        android:layout_height="wrap_content"\n        android:layout_gravity="center"\n        android:text="Loading..."\n        android:textColor="?android:attr/textColorPrimary" />\n</FrameLayout>\n`,
    'utf8'
  );
}

// 4) String resources
const stringsPath = path.join(resValuesDir, 'voltra_widgets.xml');
const labelName = `voltra_widget_${widgetId}_label`;
const descName = `voltra_widget_${widgetId}_description`;
const ensureString = (content, name, value) => {
  if (content.includes(`name=\"${name}\"`)) return content;
  return content.replace(
    /<\/resources>\s*$/,
    `  <string name="${name}">${value}</string>\n</resources>`
  );
};

if (!fs.existsSync(stringsPath)) {
  const base = `<resources>\n  <string name="${labelName}">${displayName}</string>\n  <string name="${descName}">${displayName} widget</string>\n</resources>\n`;
  fs.writeFileSync(stringsPath, base, 'utf8');
} else {
  let content = fs.readFileSync(stringsPath, 'utf8');
  content = ensureString(content, labelName, displayName);
  content = ensureString(content, descName, `${displayName} widget`);
  fs.writeFileSync(stringsPath, content, 'utf8');
}

// 5) AndroidManifest receiver
if (fs.existsSync(manifestPath)) {
  let manifest = fs.readFileSync(manifestPath, 'utf8');
  if (!manifest.includes(`android:name=\"${receiverClassName}\"`)) {
    const receiverBlock = `      <receiver\n        android:name="${receiverClassName}"\n        android:exported="true"\n        android:label="@string/voltra_widget_${widgetId}_label">\n        <intent-filter>\n          <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />\n        </intent-filter>\n        <meta-data\n          android:name="android.appwidget.provider"\n          android:resource="@xml/voltra_widget_${widgetId}_info" />\n      </receiver>\n`;

    manifest = manifest.replace(/\s*<\/application>/, `\n${receiverBlock}    </application>`);
    fs.writeFileSync(manifestPath, manifest, 'utf8');
  }
}

// eslint-disable-next-line no-console
console.log(`Widget "${widgetId}" added. Receiver: ${packageName}${receiverClassName}`);
