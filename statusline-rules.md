# Statusline 표시 규칙 (2줄)

다른 머신에서 Claude Code statusline을 재설정할 때 제시하는 규격이다.
기준 구현은 `~/.claude/statusline.ps1`(Windows, PowerShell)이다.

## 출력 포맷

```
{cwd} {git branch}[*] {model} {effort}
ctx: {used%} ({5h 사용률}% {5h 리셋 HH:mm} / {7d 사용률}% {7d 리셋 dd,HH:mm})
```

예시:

```
~/workspace/retarget master* Opus 4.7 high
ctx: 23% ( 41% 17:30 /  12% 14,09:00)
```

## 1행: 위치, 모델, effort

항목은 공백 1칸으로 구분하고, 값이 없는 항목은 생략한다.

| 항목 | 소스 | 색상 | 규칙 |
|---|---|---|---|
| cwd | `workspace.current_dir`, 없으면 `cwd` | 초록 (ANSI 32) | 홈 디렉터리 접두부(`%USERPROFILE%`)를 `~`로 치환 (대소문자 무시) |
| git branch | git | 진회색 (90) | git work tree 안에서만 표시. `symbolic-ref --short HEAD`, detached HEAD면 `rev-parse --short HEAD`. `git diff --quiet --ignore-submodules HEAD`로 미커밋 변경이 있으면 `*`를 붙임 |
| model | `model.display_name` | 주황 (256색 `38;5;214`) | 그대로 표시 |
| effort | `effort.level` | 진회색 (90) | 필드가 있을 때만 표시 |

git 명령은 `git --no-optional-locks -C <cwd>`와 `-c core.fsmonitor=false`로 실행하고 stderr는 버린다.

## 2행: 컨텍스트와 rate limit

### 컨텍스트 사용률: `ctx: {NN}%`

- `context_window.used_percentage`를 내림하고 2자리로 왼쪽 패딩한다.
- 값이 없으면 `100 - remaining_percentage`를 쓰고, 둘 다 없으면 `ctx: --%`로 표시한다.
- 80% 이상이면 노랑(33), 아니면 진회색(90)이다.

### Rate limit: `({5h}% {HH:mm} / {7d}% {dd,HH:mm})`

- 5h 구간은 `rate_limits.five_hour`이다. 퍼센트는 내림 후 3자리로 왼쪽 패딩하고, 리셋 시각(`resets_at`, Unix epoch)은 로컬 시간 `HH:mm`으로 표시한다.
- 7d 구간은 `rate_limits.seven_day`이다. 퍼센트 패딩은 같고, 리셋 시각은 `dd,HH:mm`으로 표시한다.
- 퍼센트가 없으면 같은 폭의 `--`, 리셋 시각이 없으면 `--:--` 또는 `--,--:--`로 표시해 줄 폭을 유지한다.
- 5h와 7d 중 하나라도 80% 이상이면 빨강(31), 아니면 진회색(90)이다.

## 구현 메모

- stdin에서 JSON을 읽는다.
- 출력은 UTF-8로 설정한다.
- 색상은 ANSI escape(`ESC[...m`)로 넣고, 색 구간마다 `ESC[0m`으로 닫는다.
- 두 줄을 `\n`으로 이어 출력하고 끝에 개행을 붙이지 않는다.
- `$ErrorActionPreference = 'SilentlyContinue'`로 오류가 출력을 깨지 않게 한다.

## settings.json 등록

```json
"statusLine": {
  "type": "command",
  "command": "powershell -NoProfile -ExecutionPolicy Bypass -File C:/Users/RMARKET/.claude/statusline.ps1"
}
```

- 다른 머신에서는 경로를 해당 사용자에 맞게 바꾼다. Windows에서는 경로에 슬래시(`/`)를 쓴다.
- macOS나 Linux에서는 같은 규칙을 bash/jq 스크립트(예: `~/.claude/statusline-command.sh`)로 다시 구현한다.
