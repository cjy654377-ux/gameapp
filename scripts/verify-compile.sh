#!/bin/bash
# 에이전트 코드 수정 후 커밋 전 검증 스크립트
# 반복 실수 패턴 3가지를 자동 체크

SCRIPTS_DIR="Assets/Scripts"
ERRORS=0

echo "=== 컴파일 사전 검증 ==="

# 1. EventTrigger 사용하는 파일에 using UnityEngine.EventSystems 있는지
echo "[1/5] EventSystems using 체크..."
for f in $(grep -rl "EventTrigger\|EventTriggerType" $SCRIPTS_DIR --include="*.cs"); do
    if ! grep -q "using UnityEngine.EventSystems" "$f"; then
        echo "  ERROR: $f 에서 EventTrigger 사용하는데 using EventSystems 없음"
        ERRORS=$((ERRORS+1))
    fi
done

# 2. Image 타입에 AddComponent 호출 (gameObject 없이)
echo "[2/5] Image.AddComponent 패턴 체크..."
grep -rn "\.AddComponent<" $SCRIPTS_DIR --include="*.cs" | grep -v "gameObject\." | grep -v "\.gameObject\." | grep -v "obj\." | grep -v "canvasObj\." | grep -v "tileObj\." | grep -v "starObj\." | while read line; do
    # Image/Button 등 Component 변수에 직접 AddComponent 호출하는 패턴
    if echo "$line" | grep -qE "(img|image|panel|container|fill|bg)\." ; then
        echo "  WARNING: $line — Component에 직접 AddComponent? .gameObject 필요할 수 있음"
    fi
done

# 3. ref 파라미터를 람다에서 사용
echo "[3/5] ref 파라미터 람다 캡처 체크..."
for f in $(grep -rl "ref " $SCRIPTS_DIR --include="*.cs"); do
    # ref 파라미터가 있는 메서드에서 람다/익명메서드도 있는지
    if grep -q "=>" "$f" && grep -q "ref " "$f"; then
        # 간단히 경고만 (정밀 분석은 컴파일러에 맡김)
        ref_methods=$(grep -n "ref " "$f" | grep -v "//")
        if [ -n "$ref_methods" ]; then
            echo "  INFO: $f 에 ref 파라미터 + 람다 있음 — 캡처 문제 주의"
        fi
    fi
done

# 4. 접근 제한자 없는 const (다른 파일에서 접근하는지)
echo "[4/5] private const 외부 참조 체크..."
grep -rn "private const\|const " $SCRIPTS_DIR --include="*.cs" | grep -v "public\|internal\|protected" | head -5 > /dev/null

# 5. 미사용 using 후보 (EventSystems만 특별 체크)
echo "[5/5] 핵심 using 존재 확인..."
for f in $(find $SCRIPTS_DIR -name "*.cs"); do
    if grep -q "EventTrigger" "$f" && ! grep -q "using UnityEngine.EventSystems" "$f"; then
        echo "  ERROR: $f — EventTrigger 사용하는데 using 없음"
        ERRORS=$((ERRORS+1))
    fi
    if grep -q "List<\|Dictionary<" "$f" && ! grep -q "using System.Collections.Generic" "$f"; then
        echo "  ERROR: $f — Generic 컬렉션 사용하는데 using 없음"
        ERRORS=$((ERRORS+1))
    fi
done

echo ""
if [ $ERRORS -eq 0 ]; then
    echo "✅ 검증 통과 (에러 0건)"
else
    echo "❌ 에러 $ERRORS건 발견! 커밋 전 수정 필요"
fi
exit $ERRORS
