#!/usr/bin/env bash
# Builds plugin.appodealConsent and installs it as a local Solar2D plugin, so that
# build.settings can include it with publisherId "com.robbieelias".
#
# Run from Git Bash after Solar2D has built the project at least once
# (that build downloads the Appodeal consent library into the Gradle cache).
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
CORONA="${CORONA:-/c/Program Files (x86)/Corona Labs/Corona}"
ANDROID_SDK="${ANDROID_SDK:-$APPDATA/Corona Labs/Corona Simulator/Android Build/sdk}"
GRADLE_CACHE="${GRADLE_CACHE:-$USERPROFILE/.gradle/caches/modules-2/files-2.1}"
PUBLISHER="com.robbieelias"
PLUGIN="plugin.appodealConsent"

ANDROID_JAR="$(ls -d "$ANDROID_SDK"/platforms/android-*/android.jar | sort -V | tail -1)"
CONSENT_AAR="$(find "$GRADLE_CACHE/com.appodeal.ads/consent" -name 'consent-*.aar' | sort -V | tail -1)"
UMP_AAR="$(find "$GRADLE_CACHE/com.google.android.ump/user-messaging-platform" -name 'user-messaging-platform-*.aar' | sort -V | tail -1)"
[ -f "$ANDROID_JAR" ] || { echo "android.jar not found under $ANDROID_SDK"; exit 1; }
[ -f "$CONSENT_AAR" ] || { echo "Appodeal consent aar not found; build the app with Solar2D once first"; exit 1; }
[ -f "$UMP_AAR" ] || { echo "Google UMP aar not found; build the app with Solar2D once first"; exit 1; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/classes" "$WORK/libs" "$WORK/pkg"

# Compile-only dependencies: Solar2D runtime, Appodeal consent API and Google UMP (all present in the app at runtime)
(cd "$WORK/libs" && "$CORONA/jre/bin/jar.exe" xf "$(cygpath -w "$CORONA/Native/Corona/android/lib/gradle/Corona.aar")" classes.jar && mv classes.jar corona.jar)
(cd "$WORK/libs" && "$CORONA/jre/bin/jar.exe" xf "$(cygpath -w "$CONSENT_AAR")" classes.jar && mv classes.jar consent.jar)
(cd "$WORK/libs" && "$CORONA/jre/bin/jar.exe" xf "$(cygpath -w "$UMP_AAR")" classes.jar && mv classes.jar ump.jar)

CP="$(cygpath -w "$WORK/libs/corona.jar");$(cygpath -w "$WORK/libs/consent.jar");$(cygpath -w "$WORK/libs/ump.jar")"
"$CORONA/jre/bin/javac.exe" -source 1.8 -target 1.8 -nowarn \
	-bootclasspath "$(cygpath -w "$ANDROID_JAR")" -cp "$CP" \
	-d "$(cygpath -w "$WORK/classes")" \
	"$(cygpath -w "$HERE/src/plugin/appodealConsent/LuaLoader.java")"

"$CORONA/jre/bin/jar.exe" cf "$(cygpath -w "$WORK/pkg/$PLUGIN.jar")" -C "$(cygpath -w "$WORK/classes")" .
cp "$HERE/metadata.lua" "$WORK/pkg/metadata.lua"

DEST="$(cygpath -u "$APPDATA")/Solar2DPlugins/$PUBLISHER/$PLUGIN/android"
mkdir -p "$DEST"
tar -czf "$DEST/data.tgz" -C "$WORK/pkg" metadata.lua "$PLUGIN.jar"
echo "Installed $DEST/data.tgz (built against $(basename "$CONSENT_AAR"))"
