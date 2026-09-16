#!/usr/bin/env bash
# disk_usage_report.sh
# Read-only disk usage investigation for Ubuntu.
# Run: sudo bash disk_usage_report.sh | tee disk_usage_report.txt

set -u

SUDO=""
if [[ $EUID -ne 0 ]]; then
  SUDO="sudo"
  echo "NOTE: Not running as root. Some output may be incomplete."
  echo "      For best results: sudo bash $0 | tee disk_usage_report.txt"
fi

section() {
  printf '\n\n===== %s =====\n' "$*"
}

section "Date / host"
date
hostname

section "Filesystem usage (df -h)"
df -h

section "Inode usage (df -i)"
df -i

section "Block devices"
lsblk -f 2>/dev/null || true

section "Top-level directories under / (sorted)"
$SUDO du -x -h -d 1 / 2>/dev/null | sort -h

section "Top directories under /var"
$SUDO du -x -h -d 1 /var 2>/dev/null | sort -h

section "Top directories under /home"
$SUDO du -x -h -d 1 /home 2>/dev/null | sort -h

section "Top directories under /usr"
$SUDO du -x -h -d 1 /usr 2>/dev/null | sort -h

section "Top directories under /tmp and /var/tmp"
$SUDO du -x -h -d 1 /tmp 2>/dev/null | sort -h
$SUDO du -x -h -d 1 /var/tmp 2>/dev/null | sort -h

section "Top directories under /root and current user's home"
$SUDO du -x -h -d 1 /root 2>/dev/null | sort -h
du -x -h -d 1 "$HOME" 2>/dev/null | sort -h

section "Largest files >200MB on / (top 40)"
$SUDO find / -xdev -type f -size +200M -printf '%s\t%p\n' 2>/dev/null \
  | sort -n \
  | tail -40 \
  | awk -F'\t' '{printf "%10.2f MB  %s\n", $1/1024/1024, $2}'

section "Deleted but still open files (space held by processes)"
if command -v lsof >/dev/null 2>&1; then
  $SUDO lsof +L1 2>/dev/null | head -100
else
  echo "lsof not installed. Install with: sudo apt install lsof"
fi

section "/var/log usage"
$SUDO du -sh /var/log 2>/dev/null || true
$SUDO du -h -d 1 /var/log 2>/dev/null | sort -h | tail -30

section "journald usage"
if command -v journalctl >/dev/null 2>&1; then
  $SUDO journalctl --disk-usage 2>/dev/null || true
else
  echo "journalctl not found"
fi

section "APT cache"
$SUDO du -sh /var/cache/apt 2>/dev/null || true
$SUDO du -sh /var/cache/apt/archives 2>/dev/null || true

section "Docker usage"
if command -v docker >/dev/null 2>&1; then
  $SUDO docker system df 2>/dev/null || true
  echo
  $SUDO docker ps -s 2>/dev/null || true
else
  echo "docker not installed or not in PATH"
fi

section "Common user caches"
for d in \
  "$HOME/.cache" \
  "$HOME/.npm" \
  "$HOME/.conda" \
  "$HOME/anaconda3" \
  "$HOME/miniconda3" \
  "$HOME/.local/share/Trash"
do
  if [[ -e "$d" ]]; then
    du -sh "$d" 2>/dev/null || true
  fi
done

section "Snap usage"
$SUDO du -sh /var/lib/snapd 2>/dev/null || true

section "Done"
echo "Report complete. Review the largest items above."
