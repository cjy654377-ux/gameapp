#!/bin/bash
# GameApp 팀 tmux 레이아웃 — 4분할 인터랙티브 claude 세션
# 사용법: ./scripts/tmux-teams.sh

SESSION="gamedev"
PROJECT="/Users/choijooyong/gameapp"

# 기존 세션 있으면 붙기
tmux has-session -t $SESSION 2>/dev/null && { tmux attach -t $SESSION; exit 0; }

# 새 세션: Pane 0 — 디렉터 (Opus)
tmux new-session -d -s $SESSION -n "teams" -c "$PROJECT"

# Pane 1 — 오른쪽
tmux split-window -h -t $SESSION:teams -c "$PROJECT"

# Pane 2 — 왼쪽 아래
tmux split-window -v -t $SESSION:teams.0 -c "$PROJECT"

# Pane 3 — 오른쪽 아래
tmux split-window -v -t $SESSION:teams.1 -c "$PROJECT"

# 4등분 레이아웃
tmux select-layout -t $SESSION:teams tiled

# 패인 테두리에 이름 표시
tmux set -t $SESSION pane-border-format " #{pane_index}: #{pane_title} "
tmux set -t $SESSION pane-border-status top

# Pane 0: 디렉터 (Opus) — 메인 오케스트레이션
tmux select-pane -t $SESSION:teams.0 -T "Director (Opus)"
tmux send-keys -t $SESSION:teams.0 'claude --dangerously-skip-permissions --model claude-opus-4-6' C-m

# Pane 1: 팀1 UI-Agent (Opus)
tmux select-pane -t $SESSION:teams.1 -T "Team1: UI (Opus)"
tmux send-keys -t $SESSION:teams.1 'claude --dangerously-skip-permissions --model claude-opus-4-6 --system-prompt "너는 ui-agent야. Unity UI 전담팀 (Assets/Scripts/UI/, Assets/UI/). 한국어로 답변. CLAUDE.md 규칙 준수. 디렉터 지시에 따라 작업."' C-m

# Pane 2: 팀2 Build-Agent (Sonnet)
tmux select-pane -t $SESSION:teams.2 -T "Team2: Build (Sonnet)"
tmux send-keys -t $SESSION:teams.2 'claude --dangerously-skip-permissions --model claude-sonnet-4-6 --system-prompt "너는 build-agent야. Unity 빌드/씬/코어 시스템 전담팀. 한국어로 답변. CLAUDE.md 규칙 준수. 디렉터 지시에 따라 작업."' C-m

# Pane 3: 팀3 Review-Agent (Haiku)
tmux select-pane -t $SESSION:teams.3 -T "Team3: Review (Haiku)"
tmux send-keys -t $SESSION:teams.3 'claude --dangerously-skip-permissions --model claude-haiku-4-5-20251001 --system-prompt "너는 review-agent야. 코드리뷰/검증 전담. 체크리스트 기반 검증. 한국어로 답변. CLAUDE.md 규칙 준수."' C-m

# 디렉터 패인 포커스
tmux select-pane -t $SESSION:teams.0

tmux attach -t $SESSION
