#!/usr/bin/env bash
#
# Bootstrap an Ubuntu host and deploy the RBT Docker Compose stack. See
# README.md for the manual equivalent of each step, or run with --help.
#
#   S3_BUCKET_RBT=my-bucket S3_BUCKET_TERRAIN=my-other-bucket ./deploy.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

DATA_DIR="$SCRIPT_DIR/tileserver/data"
RBT_FILE="$DATA_DIR/RBT.mbtiles"
TERRAIN_FILE="$DATA_DIR/TERRAIN.mbtiles"

FORCE_DOWNLOAD=0

log()  { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mWARNING:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<'EOF'
deploy.sh - Bootstrap an Ubuntu host and deploy the RBT Docker Compose stack.

With no flags, all four steps below run in order. Pass one or more step
flags to run only those steps (still in the order listed here, regardless
of the order given on the command line):

  --init      Install prerequisites: AWS CLI v2, Docker Engine + Compose
              plugin, git/git-lfs.
  --download  Download RBT.mbtiles/TERRAIN.mbtiles from S3 into
              tileserver/data/.
  --perm      Fix mapproxy/nginx runtime directory permissions.
  --deploy    Run `docker compose up -d`.
  --force     Re-download mbtiles even if already present (only relevant
              together with --download, or with no step flags).

Usage:
  S3_BUCKET_RBT=my-bucket S3_BUCKET_TERRAIN=my-other-bucket ./deploy.sh
  ./deploy.sh --init                # just install prerequisites
  ./deploy.sh --download --perm     # just refresh data + permissions
  ./deploy.sh --deploy              # just (re)start the stack
  ./deploy.sh --force               # full run, force re-download

Run this as your normal (non-root) user, not via `sudo` -- it escalates
internally with sudo only for the specific steps that need root (apt,
installing/starting Docker, chown). Running it unprivileged means
`aws s3 cp` uses your own AWS credential chain (env vars, ~/.aws/credentials,
AWS_PROFILE, or an EC2/ECS instance role) exactly as it would outside this
script -- nothing here configures AWS credentials for you.

Required environment variables (only enforced when the download step runs):
  S3_BUCKET_RBT      Bucket (optionally with a prefix), no filename, e.g.
                      "my-bucket" or "s3://my-bucket/exports". Must contain
                      RBT.mbtiles.
  S3_BUCKET_TERRAIN  Same, but must contain TERRAIN.mbtiles.

Re-running this script is safe: package installs are skipped when already
present. TERRAIN.mbtiles is only downloaded once (it never changes upstream).
RBT.mbtiles is re-downloaded automatically whenever the S3 object's
LastModified time is newer than the local copy's -- pass --force to
re-download either file unconditionally.
EOF
}

# ---------------------------------------------------------------------------
# Prerequisites
# ---------------------------------------------------------------------------

install_aws_cli() {
  if command -v aws >/dev/null 2>&1; then
    log "AWS CLI already installed ($(aws --version 2>&1)); skipping"
    return
  fi

  log "Installing AWS CLI v2"
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  # $tmp_dir is intentionally expanded now, not at trap-fire time.
  # shellcheck disable=SC2064
  trap "rm -rf '$tmp_dir'" RETURN
  curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o "$tmp_dir/awscliv2.zip"
  unzip -q "$tmp_dir/awscliv2.zip" -d "$tmp_dir"
  "${SUDO[@]}" "$tmp_dir/aws/install"
}

install_docker() {
  if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    log "Docker + Compose plugin already installed ($(docker --version)); skipping"
    return
  fi

  log "Removing old/conflicting Docker packages (if any)"
  "${SUDO[@]}" apt-get remove -y docker docker-engine docker.io containerd runc || true

  log "Adding Docker's official apt repository"
  "${SUDO[@]}" mkdir -m 0755 -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg |
    "${SUDO[@]}" gpg --batch --yes --dearmor -o /etc/apt/keyrings/docker.gpg
  "${SUDO[@]}" chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" |
    "${SUDO[@]}" tee /etc/apt/sources.list.d/docker.list >/dev/null

  log "Installing Docker Engine and the Compose plugin"
  "${SUDO[@]}" apt-get update
  "${SUDO[@]}" apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  log "Enabling the Docker service"
  "${SUDO[@]}" systemctl enable --now docker

  # Group membership only takes effect in new sessions, so this is a
  # convenience for future logins -- docker compose below still runs via
  # sudo so this script works correctly on the very first run.
  if [[ -n "${SUDO_USER:-}" ]] && ! id -nG "$SUDO_USER" | grep -qw docker; then
    "${SUDO[@]}" usermod -aG docker "$SUDO_USER"
    warn "Added $SUDO_USER to the docker group -- log out/in (or run 'newgrp docker') to run docker without sudo outside this script."
  fi
}

prereqs_installed() {
  command -v aws >/dev/null 2>&1 &&
    command -v docker >/dev/null 2>&1 &&
    docker compose version >/dev/null 2>&1 &&
    command -v git >/dev/null 2>&1 &&
    command -v git-lfs >/dev/null 2>&1
}

install_prereqs() {
  if prereqs_installed; then
    log "All prerequisites already installed (aws, docker, docker compose, git, git-lfs); skipping setup"
    return
  fi

  log "Updating apt package lists"
  export DEBIAN_FRONTEND=noninteractive
  "${SUDO[@]}" apt-get update

  log "Installing base packages"
  "${SUDO[@]}" apt-get install -y ca-certificates curl gnupg lsb-release unzip git git-lfs

  install_aws_cli
  install_docker

  "${SUDO[@]}" git lfs install --system
}

# ---------------------------------------------------------------------------
# Map data
# ---------------------------------------------------------------------------

normalize_s3_uri() {
  local value="${1%/}"
  [[ "$value" == s3://* ]] && echo "$value" || echo "s3://$value"
}

s3_bucket_name() {
  local uri="${1#s3://}"
  echo "${uri%%/*}"
}

s3_object_key() {
  local uri="${1#s3://}"
  case "$uri" in
    */*) echo "${uri#*/}" ;;
    *) echo "" ;;
  esac
}

# Prints the epoch seconds of an S3 object's LastModified time on stdout, or
# nothing (with a non-zero exit) if it can't be read -- e.g. missing object,
# or an IAM policy that allows GetObject but not this HeadObject call.
remote_mtime_epoch() {
  local remote_uri="$1" last_modified
  last_modified="$(aws s3api head-object \
    --bucket "$(s3_bucket_name "$remote_uri")" \
    --key "$(s3_object_key "$remote_uri")" \
    --query 'LastModified' --output text 2>/dev/null)" || return 1
  [[ -n "$last_modified" && "$last_modified" != "None" ]] || return 1
  date -d "$last_modified" +%s
}

# check_remote=1 re-downloads whenever the S3 object's LastModified is newer
# than the local file's mtime (used for RBT.mbtiles, which is updated
# periodically). check_remote=0 just downloads once and leaves the local
# file alone afterwards (used for TERRAIN.mbtiles, which never changes).
# --force always re-downloads regardless of check_remote.
fetch_mbtiles() {
  local bucket_var="$1" dest="$2" check_remote="$3"
  local filename prefix remote_uri need_download

  filename="$(basename "$dest")"
  prefix="$(normalize_s3_uri "${!bucket_var}")"
  remote_uri="$prefix/$filename"
  need_download=1

  if [[ "$FORCE_DOWNLOAD" -eq 1 ]]; then
    need_download=1
  elif [[ ! -s "$dest" ]]; then
    need_download=1
  elif [[ "$check_remote" -eq 0 ]]; then
    log "$filename already present at $dest; skipping (use --force to re-download)"
    need_download=0
  else
    local remote_epoch local_epoch
    if remote_epoch="$(remote_mtime_epoch "$remote_uri")"; then
      local_epoch="$(stat -c %Y "$dest")"
      if [[ "$remote_epoch" -gt "$local_epoch" ]]; then
        log "$filename in S3 was modified $(date -d "@$remote_epoch") (newer than the local copy); re-downloading"
        need_download=1
      else
        log "$filename is already up to date with S3; skipping (use --force to re-download)"
        need_download=0
      fi
    else
      warn "Could not read S3 metadata for $remote_uri; re-downloading $filename to be safe"
      need_download=1
    fi
  fi

  [[ "$need_download" -eq 1 ]] || return 0

  log "Downloading $filename from $remote_uri"
  aws s3 cp "$remote_uri" "$dest"
}

download_mbtiles() {
  mkdir -p "$DATA_DIR"

  fetch_mbtiles S3_BUCKET_RBT "$RBT_FILE" 1
  fetch_mbtiles S3_BUCKET_TERRAIN "$TERRAIN_FILE" 0

  [[ -s "$RBT_FILE" ]] || die "$RBT_FILE is missing or empty after download"
  [[ -s "$TERRAIN_FILE" ]] || die "$TERRAIN_FILE is missing or empty after download"
}

# ---------------------------------------------------------------------------
# Permissions (see README.md "Linux Setup" -- mapproxy's image runs as uid/gid 1000)
# ---------------------------------------------------------------------------

fix_permissions() {
  log "Setting mapproxy/nginx runtime directory permissions"
  "${SUDO[@]}" chown -R 1000:1000 mapproxy/data mapproxy/locks mapproxy/tile_locks
  "${SUDO[@]}" chmod -R 775 mapproxy/data mapproxy/locks mapproxy/tile_locks nginx/cache nginx/logs nginx/run
}

# ---------------------------------------------------------------------------
# Deploy
# ---------------------------------------------------------------------------

deploy_stack() {
  log "Pulling images"
  "${SUDO[@]}" docker compose -f "$SCRIPT_DIR/docker-compose.yaml" pull

  log "Starting the RBT stack"
  "${SUDO[@]}" docker compose -f "$SCRIPT_DIR/docker-compose.yaml" up -d

  log "Current service status"
  "${SUDO[@]}" docker compose -f "$SCRIPT_DIR/docker-compose.yaml" ps
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

RUN_INIT=0
RUN_DOWNLOAD=0
RUN_PERM=0
RUN_DEPLOY=0
STEP_SELECTED=0

for arg in "$@"; do
  case "$arg" in
    -h|--help)
      usage
      exit 0
      ;;
    --init)
      RUN_INIT=1
      STEP_SELECTED=1
      ;;
    --download)
      RUN_DOWNLOAD=1
      STEP_SELECTED=1
      ;;
    --perm)
      RUN_PERM=1
      STEP_SELECTED=1
      ;;
    --deploy)
      RUN_DEPLOY=1
      STEP_SELECTED=1
      ;;
    --force)
      FORCE_DOWNLOAD=1
      ;;
    *)
      die "Unknown argument: $arg (use --help for usage)"
      ;;
  esac
done

# No step flags given -- run the whole thing.
if [[ "$STEP_SELECTED" -eq 0 ]]; then
  RUN_INIT=1
  RUN_DOWNLOAD=1
  RUN_PERM=1
  RUN_DEPLOY=1
fi

if [[ $EUID -eq 0 ]]; then
  SUDO=()
else
  command -v sudo >/dev/null 2>&1 || die "This script needs root privileges for some steps. Install sudo or run as root."
  SUDO=(sudo)
fi

if [[ -f /etc/os-release ]] && ! grep -qi ubuntu /etc/os-release; then
  warn "/etc/os-release doesn't identify this host as Ubuntu; continuing anyway."
fi

[[ -f "$SCRIPT_DIR/docker-compose.yaml" ]] ||
  die "docker-compose.yaml not found next to this script -- run it from inside the agc-rbt repo checkout."

if [[ "$RUN_DOWNLOAD" -eq 1 ]]; then
  : "${S3_BUCKET_RBT:?Set S3_BUCKET_RBT to the bucket (and optional prefix) containing RBT.mbtiles, e.g. S3_BUCKET_RBT=my-bucket}"
  : "${S3_BUCKET_TERRAIN:?Set S3_BUCKET_TERRAIN to the bucket (and optional prefix) containing TERRAIN.mbtiles}"
fi

if [[ "$RUN_INIT" -eq 1 ]]; then
  install_prereqs
fi
if [[ "$RUN_DOWNLOAD" -eq 1 ]]; then
  download_mbtiles
fi
if [[ "$RUN_PERM" -eq 1 ]]; then
  fix_permissions
fi
if [[ "$RUN_DEPLOY" -eq 1 ]]; then
  deploy_stack
fi

log "Done."
echo "  Logs:   docker compose logs -f"
echo "  Health: curl -fsS http://localhost:\${NGINX_PORT:-8081}/healthz"
echo "  Stop:   docker compose down --remove-orphans"
