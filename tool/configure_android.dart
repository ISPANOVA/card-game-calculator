// Run after `flutter create --platforms=android .` to give the generated
// Android project its real id, name and release signing.
import 'dart:io';

const appId = 'com.smrh.cardgamecalculator';
const label = 'Card Game Calculator';

void main() {
  var ok = true;
  ok &= _step('gradle', _gradle);
  ok &= _step('gradle.properties', _gradleProperties);
  ok &= _step('manifest', _manifest);
  if (!ok) exit(1);
}

bool _step(String name, void Function() action) {
  try {
    action();
    stdout.writeln('✔ $name');
    return true;
  } catch (e) {
    stdout.writeln('✖ $name: $e');
    return false;
  }
}

void _gradle() {
  final kts = File('android/app/build.gradle.kts');
  if (!kts.existsSync()) throw 'android/app/build.gradle.kts not found';
  var s = kts.readAsStringSync();
  s = s.replaceAll(RegExp(r'applicationId\s*=\s*"[^"]*"'), 'applicationId = "$appId"');
  if (!s.contains('keystoreProperties')) {
    s = 'import java.io.FileInputStream\nimport java.util.Properties\n\n$s';
    s = s.replaceFirst(
      RegExp(r'\nandroid\s*\{'),
      '''

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }
''',
    );
    const debug = 'signingConfig = signingConfigs.getByName("debug")';
    if (!s.contains(debug)) throw 'release signingConfig line not found';
    s = s.replaceFirst(
      debug,
      'signingConfig = if (keystorePropertiesFile.exists()) signingConfigs.getByName("release") else signingConfigs.getByName("debug")',
    );
  }
  kts.writeAsStringSync(s);
}

/// The pub cache (C:) and the project may sit on different drives on
/// Windows, which breaks Kotlin incremental compilation.
void _gradleProperties() {
  final f = File('android/gradle.properties');
  if (!f.existsSync()) throw 'android/gradle.properties not found';
  final s = f.readAsStringSync();
  if (!s.contains('kotlin.incremental')) {
    f.writeAsStringSync('${s.trimRight()}\nkotlin.incremental=false\n');
  }
}

void _manifest() {
  final f = File('android/app/src/main/AndroidManifest.xml');
  if (!f.existsSync()) throw 'AndroidManifest.xml not found';
  var s = f.readAsStringSync();
  s = s.replaceAll(RegExp(r'android:label="[^"]*"'), 'android:label="$label"');
  f.writeAsStringSync(s);
}
