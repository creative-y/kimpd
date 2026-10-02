#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────
#  kimpd 배포 스크립트
#    사용법 : ./deploy.sh [새파일.html] ["커밋 메모"]
#    인자 없이 실행하면 Downloads 의 최신 kimp-dashboard_*.html 을 찾아 물어봅니다.
# ──────────────────────────────────────────────────────────────
set -u
cd "$(dirname "$0")" || exit 1

REPO="https://github.com/creative-y/kimpd.git"
BRANCH="main"
SITE="https://creative-y.github.io/kimpd/"

say()  { printf '\n\033[36m%s\033[0m\n' "$*"; }
ok()   { printf '\033[32m%s\033[0m\n' "$*"; }
hold() { printf '\n'; read -r -p "엔터를 누르면 창이 닫힙니다... " _; }
die()  { printf '\n\033[31m[중단] %s\033[0m\n' "$*"; hold; exit 1; }

command -v git >/dev/null 2>&1 || die "git 이 설치돼 있지 않습니다. https://git-scm.com/download/win"

# ── 1) 올릴 파일 정하기 ───────────────────────────────────────
SRC=""; MSG=""
if [ $# -ge 1 ]; then
  if [ -f "$1" ]; then SRC="$1"; MSG="${2:-}"; else MSG="$1"; fi
fi

if [ -z "$SRC" ]; then
  # Downloads 에서 가장 최근 kimp-dashboard_*.html 을 찾아 index.html 보다 새로우면 제안
  NEW=$(ls -t "$HOME"/Downloads/kimp-dashboard*.html 2>/dev/null | head -1)
  if [ -n "$NEW" ] && { [ ! -f index.html ] || [ "$NEW" -nt index.html ]; }; then
    say "Downloads 에 더 최근 파일이 있습니다:"
    echo "   $(basename "$NEW")   ($(date -r "$NEW" '+%Y-%m-%d %H:%M'))"
    read -r -p "이 파일로 교체할까요? [Y/n] " ans
    case "${ans:-Y}" in [Nn]*) ;; *) SRC="$NEW";; esac
  fi
fi

if [ -n "$SRC" ]; then
  cp -- "$SRC" index.html || die "복사 실패: $SRC"
  ok "index.html 교체 완료 — $(basename "$SRC")"
fi
[ -f index.html ] || die "index.html 이 없습니다."

# ── 2) 처음이면 저장소 연결 ───────────────────────────────────
if [ ! -d .git ]; then
  say "저장소를 처음 연결합니다…"
  git init -b "$BRANCH"                || die "git init 실패"
  git remote add origin "$REPO"        || die "remote 추가 실패"
  git fetch origin                     || die "원격 접속 실패 — 네트워크/로그인을 확인하세요."
  git reset origin/"$BRANCH"           || die "원격 이력 연결 실패"
  ok "연결 완료"
fi
git remote get-url origin >/dev/null 2>&1 || git remote add origin "$REPO"

if ! git config user.name >/dev/null; then
  say "커밋에 쓸 이름/이메일이 설정돼 있지 않습니다. 한 번만 입력하세요."
  read -r -p "  이름  : " GN; read -r -p "  이메일: " GE
  git config --global user.name  "$GN"
  git config --global user.email "$GE"
fi

# ── 3) 변경 확인 ──────────────────────────────────────────────
git add -A
if git diff --cached --quiet; then
  say "바뀐 내용이 없습니다. 배포할 것이 없습니다."
  hold; exit 0
fi
printf '\n변경된 파일\n'; git diff --cached --name-status

# ── 4) 커밋 & 푸시 ────────────────────────────────────────────
[ -n "$MSG" ] || MSG="update $(date '+%Y-%m-%d %H:%M')"
git commit -m "$MSG" || die "커밋 실패"

say "푸시 중… (처음 한 번은 GitHub 로그인 창이 뜹니다)"
if ! git push -u origin "$BRANCH"; then
  say "원격에 다른 변경이 있어 먼저 합칩니다…"
  git pull --rebase origin "$BRANCH" || die "병합 실패 — Git Bash에서 git status 로 확인하세요."
  git push -u origin "$BRANCH"       || die "푸시 실패"
fi

say "배포 완료 — 1~2분 뒤 반영됩니다"
echo "   $SITE"
echo "   브라우저에서 Ctrl+Shift+R (강력 새로고침)"
echo "   진행 상황: https://github.com/creative-y/kimpd/actions"
hold
