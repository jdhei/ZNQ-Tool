#!/usr/bin/env bash
# ZNQ one-command installer for Termux
# Features: deps install, PyArmor obfuscation, CRLF fix, launcher "znq"

set -Eeuo pipefail

# ========= CONFIG (CHỈ SỬA DÒNG NÀY) =========
TOOL_URL="https://raw.githubusercontent.com/YourUsername/YourRepo/main/znq-rejoin.py"
# ============================================

RED='\033[31m'; GRN='\033[32m'; YLW='\033[33m'; CLR='\033[0m'

log()  { echo -e "${GRN}[+]${CLR} $*"; }
warn() { echo -e "${YLW}[!]${CLR} $*"; }
err()  { echo -e "${RED}[x]${CLR} $*" >&2; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || return 1
}

ensure_termux() {
  if [ -z "${PREFIX:-}" ] || ! echo "$PREFIX" | grep -q "com.termux"; then
    warn "Có vẻ bạn không ở Termux. Script này dành cho Termux."
  fi
}

ensure_storage() {
  if [ ! -d "/sdcard" ]; then
    warn "Chưa cấp quyền storage cho Termux? Chạy: termux-setup-storage"
  else
    termux-setup-storage >/dev/null 2>&1 || true
  fi
}

install_deps() {
  log "Đang cập nhật Termux & cài gói hệ thống…"
  pkg update -y >/dev/null 2>&1 || true
  pkg install -y bash python git curl clang binutils >/dev/null 2>&1

  log "Đang nâng cấp pip & wheel…"
  pip install -U pip setuptools wheel >/dev/null 2>&1

  log "Cài thư viện Python tối thiểu…"
  # psutil + certifi (tool của bạn có dùng) + requests (an toàn)
  pip install -U psutil certifi requests >/dev/null 2>&1

  log "Cài PyArmor để làm rối mã…"
  # cố định 1 phiên bản ổn định, nếu lỗi sẽ fallback
  (pip install "pyarmor==8.5.10" >/dev/null 2>&1) || (pip install pyarmor >/dev/null 2>&1) || true
}

pyarmor_ok() {
  python - <<'PY' >/dev/null 2>&1
try:
    import pyarmor  # noqa
    import sys; sys.exit(0)
except Exception:
    import sys; sys.exit(1)
PY
}

download_tool() {
  mkdir -p "$HOME/.znq/src"
  log "Tải tool về…"
  curl -fsSL "$TOOL_URL" -o "$HOME/.znq/src/znq-rejoin.py"
  if [ ! -s "$HOME/.znq/src/znq-rejoin.py" ]; then
    err "Không thể tải tool. Kiểm tra TOOL_URL / mạng!"
    exit 1
  fi
  # Sửa CRLF nếu có
  sed -i 's/\r$//' "$HOME/.znq/src/znq-rejoin.py"
}

obfuscate() {
  mkdir -p "$HOME/.znq/znq_tool"
  log "Làm rối mã nguồn bằng PyArmor…"
  # Ưu tiên gọi module để tránh PATH lệch dưới su
  if pyarmor_ok; then
    # PyArmor v8+: lệnh "gen" nhanh gọn
    if python -c "import pyarmor.cli.__main__" >/dev/null 2>&1; then
      python -m pyarmor gen -O "$HOME/.znq/znq_tool" "$HOME/.znq/src/znq-rejoin.py" >/dev/null 2>&1 || true
    else
      # v7: dùng 'obfuscate'
      pyarmor obfuscate -O "$HOME/.znq/znq_tool" "$HOME/.znq/src/znq-rejoin.py" >/dev/null 2>&1 || true
    fi
  fi

  if [ ! -f "$HOME/.znq/znq_tool/znq-rejoin.py" ]; then
    warn "PyArmor lỗi hoặc không có → chạy BẢN GỐC (không rối mã)."
    cp "$HOME/.znq/src/znq-rejoin.py" "$HOME/.znq/znq_tool/znq-rejoin.py"
  fi
}

make_launcher() {
  local BIN="$PREFIX/bin"
  mkdir -p "$BIN"
  cat > "$BIN/znq" <<'SH'
#!/usr/bin/env bash
set -e
# Launcher cho ZNQ (ưu tiên bản đã obfuscate)
PY="$HOME/.znq/znq_tool/znq-rejoin.py"
if [ ! -f "$PY" ]; then
  echo "[x] Không tìm thấy tool tại $PY" >&2
  exit 1
fi
exec python "$PY" "$@"
SH
  chmod +x "$BIN/znq"
}

main() {
  echo "============================================="
  echo " ZNQ TOOL - CÀI ĐẶT & BẢO MẬT (Termux) "
  echo "============================================="
  ensure_termux
  ensure_storage
  install_deps
  download_tool
  obfuscate
  make_launcher
  echo
  echo -e "${GRN}✓ Hoàn tất!${CLR}"
  echo "Bạn có thể chạy tool bằng lệnh:  znq"
  echo "Hoặc: python $HOME/.znq/znq_tool/znq-rejoin.py"
}
main "$@"
