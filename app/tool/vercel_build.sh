#!/usr/bin/env bash
set -euo pipefail

app_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$app_dir"

for name in APP_ENV SUPABASE_URL SUPABASE_PUBLISHABLE_KEY; do
  if [[ -z "${!name:-}" ]]; then
    echo "Missing required Vercel environment variable: $name" >&2
    exit 1
  fi
done

case "$APP_ENV" in
  development|production) ;;
  *)
    echo "APP_ENV must be development or production." >&2
    exit 1
    ;;
esac

if [[ ! "$SUPABASE_URL" =~ ^https://[a-zA-Z0-9-]+\.supabase\.co/?$ ]]; then
  echo "SUPABASE_URL must be an HTTPS Supabase project URL." >&2
  exit 1
fi

# Flutter Web ships compile-time values to every visitor. Accept only a
# Supabase publishable key (new format) or an anon JWT (legacy format).
if ! node <<'NODE'
const key = process.env.SUPABASE_PUBLISHABLE_KEY ?? '';
if (key.startsWith('sb_publishable_')) process.exit(0);
const parts = key.split('.');
if (parts.length === 3) {
  try {
    const payload = JSON.parse(Buffer.from(parts[1], 'base64url').toString('utf8'));
    if (payload.role === 'anon') process.exit(0);
  } catch {}
}
console.error('SUPABASE_PUBLISHABLE_KEY must be a publishable key or legacy anon key.');
process.exit(1);
NODE
then
  exit 1
fi

flutter_version="$(node -e 'const fs = require("node:fs"); const config = JSON.parse(fs.readFileSync(".fvmrc", "utf8")); process.stdout.write(config.flutter);')"
sdk_root="${FLUTTER_SDK_CACHE_DIR:-${TMPDIR:-/tmp}/musemend-flutter-sdk}"
flutter_bin="$sdk_root/flutter-$flutter_version/bin/flutter"

if [[ ! -x "$flutter_bin" ]]; then
  mkdir -p "$sdk_root"
  temp_dir="$(mktemp -d "$sdk_root/.download.XXXXXX")"
  trap 'rm -rf "$temp_dir"' EXIT

  release_json="$temp_dir/releases_linux.json"
  archive_info="$(mktemp "$temp_dir/archive-info.XXXXXX")"
  curl --fail --location --silent --show-error \
    https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json \
    --output "$release_json"
  node - "$flutter_version" "$release_json" > "$archive_info" <<'NODE'
const fs = require('node:fs');
const [version, manifestPath] = process.argv.slice(2);
const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
const release = manifest.releases.find(
  (item) => item.channel === 'stable' && item.version === version,
);
if (!release?.archive || !release?.sha256) {
  throw new Error(`Pinned Flutter stable release ${version} is unavailable.`);
}
process.stdout.write(`${manifest.base_url}/${release.archive}\n${release.sha256}`);
NODE

  archive_url="$(head -n 1 "$archive_info")"
  archive_sha256="$(tail -n 1 "$archive_info")"
  archive_path="$temp_dir/flutter.tar.xz"
  curl --fail --location --silent --show-error "$archive_url" --output "$archive_path"
  printf '%s  %s\n' "$archive_sha256" "$archive_path" | sha256sum --check --status
  mkdir -p "$sdk_root/flutter-$flutter_version"
  tar -xJf "$archive_path" --strip-components=1 -C "$sdk_root/flutter-$flutter_version"
fi

"$flutter_bin" config --no-analytics --enable-web
"$flutter_bin" pub get --enforce-lockfile
"$flutter_bin" build web --release --no-pub \
  --dart-define="APP_ENV=$APP_ENV" \
  --dart-define="SUPABASE_URL=$SUPABASE_URL" \
  --dart-define="SUPABASE_PUBLISHABLE_KEY=$SUPABASE_PUBLISHABLE_KEY"
