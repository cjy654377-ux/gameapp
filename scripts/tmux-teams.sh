#!/bin/bash
# GameApp 팀 tmux 레이아웃
# 사용법: ./scripts/tmux-teams.sh

SESSION="gamedev"
PROJECT="/Users/choijooyong/gameapp"

# 기존 세션 있으면 붙기
tmux has-session -t $SESSION 2>/dev/null && { tmux attach -t $SESSION; exit 0; }

# 새 세션: 디렉터 (메인)
tmux new-session -d -s $SESSION -n "director" -c "$PROJECT"

# 팀1 (ui-agent) — 오른쪽 분할
tmux split-window -h -t $SESSION:director -c "$PROJECT"

# 팀2 (build-agent) — 왼쪽 아래 분할
tmux split-window -v -t $SESSION:director.0 -c "$PROJECT"

# 팀3 (review-agent) — 오른쪽 아래 분할
tmux split-window -v -t $SESSION:director.1 -c "$PROJECT"

# 레이아웃: 4등분 (tiled)
tmux select-layout -t $SESSION:director tiled

# 각 패인에 라벨 표시 + claude 실행
# Pane 0: 디렉터 (Opus)
tmux send-keys -t $SESSION:director.0 'echo "🎬 디렉터 (Opus)" && claude --model claude-opus-4-6' C-m

# Pane 1: 팀1 UI (Opus)
tmux send-keys -t $SESSION:director.1 'echo "🎨 팀1 UI-Agent (Opus)" && claude --model claude-opus-4-6 -p "너는 ui-agent야. Unity UI 전담팀. Assets/Scripts/UI/, Assets/UI/ 범위만 작업. 디렉터의 지시를 기다려."' C-m

# Pane 2: 팀2 빌드 (Sonnet)
tmux send-keys -t $SESSION:director.2 'echo "🔧 팀2 Build-Agent (Sonnet)" && claude --model claude-sonnet-4-6 -p "너는 build-agent야. Unity 빌드/씬/코어 시스템 전담팀. 디렉터의 지시를 기다려."' C-m

# Pane 3: 팀3 검증 (Haiku)
tmux send-keys -t $SESSION:director.3 'echo "✅ 팀3 Review-Agent (Haiku)" && claude --model claude-haiku-4-5-20251001 -p "너는 review-agent야. 코드리뷰, 검증 전담. 팀1/팀2 작업 완료 후 검증 요청이 들어오면 체크리스트 기반으로 검증해."' C-m

# 디렉터 패인으로 포커스
tmux select-pane -t $SESSION:director.0

tmux attach -t $SESSION
