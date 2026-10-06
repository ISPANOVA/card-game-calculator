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
  ok &= _step('native code', _native);
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
  if (!s.contains('androidx.core:core-ktx')) {
    s += '\ndependencies {\n    implementation("androidx.core:core-ktx:1.13.1")\n}\n';
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
  if (!s.contains('FileProvider')) {
    s = s.replaceFirst(
      '</application>',
      '''    <provider
            android:name="androidx.core.content.FileProvider"
            android:authorities="$appId.share"
            android:exported="false"
            android:grantUriPermissions="true">
            <meta-data
                android:name="android.support.FILE_PROVIDER_PATHS"
                android:resource="@xml/share_paths" />
        </provider>
    </application>''',
    );
  }
  f.writeAsStringSync(s);
}

/// MainActivity with the app's channel (screen on, sounds, sharing).
void _native() {
  final activities = Directory('android/app/src/main/kotlin')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('MainActivity.kt'))
      .toList();
  if (activities.length != 1) throw 'MainActivity.kt not found';
  final src = File('tool/native/MainActivity.kt').readAsStringSync();
  final pkg = RegExp(r'^package\s+(\S+)', multiLine: true).firstMatch(activities.first.readAsStringSync())!.group(1)!;
  activities.first.writeAsStringSync(src.replaceFirst(RegExp(r'^package\s+\S+', multiLine: true), 'package $pkg'));
  final xml = Directory('android/app/src/main/res/xml')..createSync(recursive: true);
  File('tool/native/share_paths.xml').copySync('${xml.path}/share_paths.xml');
}
