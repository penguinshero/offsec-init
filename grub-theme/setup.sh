#!/usr/bin/env bash
# =============================================================================
#  GRUB Theme Installer
#  Author : Muhammad Shawon (github.com/penguinshero)
#  License: MIT
# =============================================================================

set -euo pipefail

# ─── Colors ──────────────────────────────────────────────────────────────────
RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
RED='\033[38;5;210m'
GREEN='\033[38;5;114m'
BLUE='\033[38;5;110m'
GRAY='\033[38;5;245m'
WHITE='\033[38;5;252m'

# ─── Config ──────────────────────────────────────────────────────────────────
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_DIR="/boot/grub/themes/kali"
WALLPAPER="/usr/share/images/desktop-base/desktop-grub.png"
STEP_TOTAL=5
STEP_NOW=0

declare -a _RESULTS=()
declare -a _DETAILS=()
declare -a _STATUSES=()

# ─── Primitives ──────────────────────────────────────────────────────────────
_print() { printf "%b\n" "$*"; }
ok()     { _print "  ${GREEN}✔${RESET}  ${WHITE}$*${RESET}  ${DIM}done${RESET}"; }
fail()   { _print "  ${RED}✘${RESET}  ${WHITE}$*${RESET}  ${DIM}failed${RESET}" >&2; }
info()   { _print "  ${BLUE}·${RESET}  ${DIM}$*${RESET}"; }

# ─── Spinner ─────────────────────────────────────────────────────────────────
_spin_pid=""
_spinner_start() {
    local msg="$1"
    local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local i=0
    tput civis 2>/dev/null || true
    while true; do
        printf "\r  ${BLUE}%s${RESET}  ${DIM}%s${RESET}" "${frames[$i]}" "$msg"
        i=$(( (i+1) % 10 ))
        sleep 0.07
    done &
    _spin_pid=$!
}
_spinner_stop() {
    [[ -n "$_spin_pid" ]] && { kill "$_spin_pid" 2>/dev/null; wait "$_spin_pid" 2>/dev/null || true; _spin_pid=""; }
    printf "\r\033[K"
    tput cnorm 2>/dev/null || true
}

# ─── Progress Bar ─────────────────────────────────────────────────────────────
_progress() {
    local filled=$(( STEP_NOW * 28 / STEP_TOTAL ))
    local empty=$(( 28 - filled ))
    local bar=""
    for ((i=0; i<filled; i++)); do bar+="─"; done
    for ((i=0; i<empty;  i++)); do bar+=" "; done
    local pct=$(( STEP_NOW * 100 / STEP_TOTAL ))
    printf "  ${DIM}[${RESET}${BLUE}%s${RESET}${DIM}]${RESET}  ${DIM}%d%%${RESET}\n" "$bar" "$pct"
}

# ─── Step Runner ──────────────────────────────────────────────────────────────
run_step() {
    local label="$1"; shift
    STEP_NOW=$(( STEP_NOW + 1 ))
    _print ""
    _print "  ${BOLD}${WHITE}${STEP_NOW}/${STEP_TOTAL}${RESET}  ${GRAY}${label}${RESET}"
    _progress
    _spinner_start "$label"
    local rc=0
    "$@" >> /dev/null 2>&1 || rc=$?
    _spinner_stop
    if [[ $rc -ne 0 ]]; then
        fail "$label"
        _RESULTS+=("$label"); _STATUSES+=("err"); _DETAILS+=("failed")
        _print_summary
        _fail_box
        exit 1
    fi
    ok "$label"
    _RESULTS+=("$label"); _STATUSES+=("ok"); _DETAILS+=("done")
}

# ─── Banner ──────────────────────────────────────────────────────────────────
_banner() {
    clear
    _print ""
    _print "  ${BOLD}${WHITE}GRUB Theme Installer${RESET}  ${DIM}·  github.com/penguinshero${RESET}"
    _print "  ${DIM}$(printf '%.0s─' {1..44})${RESET}"
    _print ""
    sleep 0.6
}

# ─── Summary Table ────────────────────────────────────────────────────────────
_print_summary() {
    local col=36
    _print ""
    _print "  ${DIM}$(printf '%.0s─' {1..56})${RESET}"
    printf "  ${BOLD}${BLUE}%-${col}s  %-8s  %s${RESET}\n" "Task" "Status" "Detail"
    _print "  ${DIM}$(printf '%.0s─' {1..56})${RESET}"
    for i in "${!_RESULTS[@]}"; do
        local st="${_STATUSES[$i]}"
        local icon
        if [[ "$st" == "ok" ]]; then
            icon="${GREEN}✔  ok   ${RESET}"
        else
            icon="${RED}✘  err  ${RESET}"
        fi
        printf "  ${WHITE}%-${col}s${RESET}  %b  ${DIM}%s${RESET}\n" \
            "${_RESULTS[$i]}" "$icon" "${_DETAILS[$i]}"
    done
    _print "  ${DIM}$(printf '%.0s─' {1..56})${RESET}"
    _print ""
}

# ─── Result Boxes ─────────────────────────────────────────────────────────────
_success_box() {
    _print "  ${GREEN}${BOLD}✔  Installation complete${RESET}"
    _print "  ${DIM}Reboot to apply your custom GRUB theme.${RESET}"
    _print ""
}
_fail_box() {
    _print "  ${RED}${BOLD}✘  Installation failed${RESET}"
    _print ""
}

# ─── Step Functions ───────────────────────────────────────────────────────────
_check_root() {
    [[ "$EUID" -eq 0 ]] || { fail "Run as root: sudo $0"; exit 1; }
}
_check_image() {
    [[ -f "$SRC_DIR/grubimg.png" ]] || { fail "grubimg.png not found in $SRC_DIR"; exit 1; }
}
_create_dirs() {
    mkdir -p "$THEME_DIR"
    mkdir -p "$(dirname "$WALLPAPER")"
}
_copy_image() {
    cp -f "$SRC_DIR/grubimg.png" "$WALLPAPER"
    cp -f "$SRC_DIR/grubimg.png" "$THEME_DIR/grubimg.png"
}
_write_theme() {
    rm -f "$THEME_DIR/theme.txt" "$THEME_DIR/grub_background.sh"
    cat > "$THEME_DIR/theme.txt" << 'EOF'
title-text: ""
desktop-image: "grubimg.png"
desktop-color: "#2f5595"
terminal-left: "0"
terminal-top: "0"
terminal-width: "100%"
terminal-height: "100%"
terminal-border: "0"

+ boot_menu {
  left = 25%
  top = 25%
  width = 50%
  height = 60%
  item_color = "#845ec2"
  selected_item_color = "#00c9a7"
  icon_width = 0
  icon_height = 0
  item_icon_space = 10
  item_height = 36
  item_padding = 0
  item_spacing = 5
  selected_item_pixmap_style = "select_*.png"
}

+ label {
  top = 95%
  left = 35%
  width = 30%
  align = "center"
  id = "__timeout__"
  text = "Booting in %d seconds"
  color = "#ffffff"
}
EOF
    cat > "$THEME_DIR/grub_background.sh" << EOF
WALLPAPER=${WALLPAPER}
COLOR_NORMAL=white/black
COLOR_HIGHLIGHT=black/white
EOF
}
_update_grub() { update-grub; }

# ─── Main ─────────────────────────────────────────────────────────────────────
main() {
    _banner

    # fast pre-checks
    _check_root
    _check_image

    run_step "Create directories"    _create_dirs
    run_step "Copy wallpaper image"  _copy_image
    run_step "Write theme files"     _write_theme
    run_step "Update GRUB config"    _update_grub
    run_step "Verify installation"   _verify

    _print_summary
    _success_box
}

_verify() {
    [[ -f "$WALLPAPER" ]]              || return 1
    [[ -f "$THEME_DIR/theme.txt" ]]    || return 1
    [[ -f "$THEME_DIR/grubimg.png" ]]  || return 1
}

main "$@"
