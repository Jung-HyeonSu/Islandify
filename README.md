# Codex 하네스 참고 문서

이 문서는 Codex 하네스 구조를 정리할 때 참고한 공식 OpenAI 문서와 저장소 적용 위치를 기록한다. 실제 작업 지침의 정본은 루트 `../AGENTS.md`와 `.agents/**`, `.codex/**` 이며, 이 파일 자체는 Codex가 자동으로 로드하는 지침 파일이 아니다.

## 공식 문서와 적용 위치

| 영역 | 저장소 위치 | 공식 문서 | 적용 기준 |
|---|---|---|---|
| 공통 작업 지침 | `AGENTS.md` | [Custom instructions with AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md) | 세션 진입 원칙과 항상 지켜야 할 최소 제약만 둔다. |
| 반복 작업 절차 | `.agents/skills/<skill>/SKILL.md` | [Build skills](https://learn.chatgpt.com/docs/build-skills) | 영역별 절차와 상세 지식은 Skill로 분리하고, 필요한 Skill만 선택해 로드한다. |
| 프로젝트 설정 | `.codex/config.toml` | [Config basics](https://learn.chatgpt.com/docs/config-file/config-basic) | 팀 공통 Codex 설정과 MCP·Subagent 공통 설정을 둘 때 사용한다. |
| MCP | `.codex/config.toml`의 `mcp_servers` | [Model Context Protocol](https://learn.chatgpt.com/docs/extend/mcp) | 팀 공통 MCP를 등록한다. 비밀값은 파일에 넣지 않고 환경 변수로 전달한다. |
| Hooks | `.codex/hooks.json`, `.codex/hooks/**` | [Hooks](https://learn.chatgpt.com/docs/hooks) | 경로 차단이나 구조 검증처럼 결정적인 검사만 자동화한다. 의미 판단이 필요한 티켓·Skill 작성은 Hook에서 수행하지 않는다. |
| Subagents | `.codex/agents/*.toml` | [Subagents](https://learn.chatgpt.com/docs/agent-configuration/subagents) | 프로젝트 전용 역할이 필요할 때만 좁고 명확한 Agent를 정의한다. 파일을 만든 것만으로 실행되지는 않는다. |
| 명령 실행 규칙 | `.codex/rules/*.rules` | [Rules](https://learn.chatgpt.com/docs/agent-configuration/rules) | 셸 명령의 허용·확인·차단 정책에만 사용한다. 코드 작성 원칙은 `AGENTS.md`와 Skill에 유지한다. |

## 저장소 고유 구성

- AGENTS.md 파일 작성 참고 자료 - [andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills/blob/main/CLAUDE.md)
- `.codex/ticket/**`은 작업 계획과 기록을 보관하는 프로젝트 고유 경로다. Codex 공식 자동 로드 위치가 필요한 경우에만 읽고 갱신한다.
- 코드·설정·DB·테스트 변경 후의 Skill 실제 생성·수정은 `$skill-creator` 절차를 따른다.
- 세부 지침을 루트 `AGENTS.md`에 계속 추가하지 않고, 반복 가능하고 독립적인 절차는 `.agents/skills/**`로 분리한다.
- Hooks, MCP, Subagents, 명령 규칙은 `.agents` 아래에 섞지 않고 공식 프로젝트 설정 위치인 `.codex/**`에 둔다.

마지막 공식 문서 확인일: 2026-08-13

## Islandify 프로젝트 구조

Islandify는 로컬 데이터를 기반으로 타이머, 여행 D-day, 커플 D+, 러닝 정보를 앱과 Dynamic Island·잠금 화면 Live Activity에 표시하는 네이티브 SwiftUI iOS 앱이다.

```text
Islandify/
├── Islandify.xcodeproj/                 # Xcode 프로젝트
│   ├── project.pbxproj                  # 앱·Widget·Unit Test 타깃 설정
│   ├── project.xcworkspace/             # Xcode workspace 정보
│   └── xcshareddata/xcschemes/           # 공유 Islandify 빌드 scheme
├── Islandify/                           # iOS 앱 타깃
│   ├── App/
│   │   ├── IslandifyApp.swift            # 앱 진입점
│   │   ├── ContentView.swift             # Timer·Travel·Together·Run·Style 화면
│   │   ├── IslandifyAppModel.swift       # 앱 상태·저장소·Activity 연결
│   │   └── *FeatureView.swift             # 기능별 SwiftUI 화면
│   ├── Services/
│   │   ├── LiveActivityManager.swift     # ActivityKit 시작·갱신·종료
│   │   ├── LocalNotificationScheduler.swift
│   │   └── LocationService.swift         # Core Location 권한·샘플 수집
│   └── Resources/
│       ├── Info.plist                    # Live Activity·위치 권한 설정
│       └── Islandify.entitlements        # 앱 권한 및 capability 설정
├── IslandifyWidget/                      # WidgetKit Extension 타깃
│   ├── IslandifyWidgetBundle.swift       # Widget bundle 진입점
│   ├── IslandifyLiveActivityWidget.swift # Dynamic Island·Lock Screen UI
│   └── Info.plist
├── Shared/                               # 앱과 Widget이 함께 사용하는 코드
│   ├── ActivityContracts/
│   │   └── IslandifyActivityAttributes.swift # ActivityAttributes·ContentState
│   ├── Domain/
│   │   ├── ActivityPresentation.swift    # 고정 슬롯 기반 공통 표시 모델
│   │   ├── TimerDomain.swift              # 절대 시각 기반 타이머 계산
│   │   ├── TravelDomain.swift             # 타임존 안전 여행 D-day 계산
│   │   ├── RelationshipDomain.swift       # D+·기념일·알림 계산
│   │   ├── RunningDomain.swift            # 거리·페이스·칼로리 계산
│   │   ├── CustomizationDomain.swift      # 테마·슬롯·미리보기 조합
│   │   ├── DateMath.swift                 # 날짜·달력 계산
│   │   ├── TimeFormatting.swift           # 시간·거리·페이스 포맷터
│   │   ├── LocalStore.swift               # 버전 관리 로컬 JSON 저장소
│   │   ├── PreviewData.swift              # 미리보기·샘플 데이터
│   │   └── TravelPresentation.swift       # 여행 상태 표시 변환
│   └── DomainChecks/main.swift            # XCTest 없이 실행하는 도메인 점검
├── IslandifyTests/                       # 순수 도메인 Unit Test
│   ├── *DomainTests.swift                 # Timer·Travel·Relationship·Running 테스트
│   ├── PresentationTests.swift            # 표시 모델·테마·접근성 테스트
│   ├── LocalStoreTests.swift              # 저장소·마이그레이션 테스트
│   └── StabilityDomainTests.swift         # 만료·잘림·권한 fallback 테스트
├── .agents/skills/                        # Islandify 전용 작업 지침
├── .codex/                                # 티켓·검증 hook·agent 설정
├── Package.swift                          # 도메인 Swift Package 테스트 설정
├── AGENTS.md                              # 저장소 작업 규칙
└── README.md                              # 프로젝트 및 작업 참고 문서
```

## 주요 구성 설명

- `Islandify/App`은 사용자의 입력과 화면 상태를 관리한다. 실제 날짜·시간·거리 계산은 `Shared/Domain`에 위임한다.
- `Shared/ActivityContracts`의 ActivityKit 타입은 앱 타깃과 Widget Extension 타깃에 동일한 소스로 포함된다.
- `Shared/Domain`은 가능한 한 순수 타입으로 구성되어 백그라운드 전환, 타임존, 윤년, 일시정지·재개 같은 동작을 테스트할 수 있다.
- `IslandifyWidget`은 시스템이 제공하는 `compact`, `minimal`, `expanded`, Lock Screen 영역만 사용한다. 사용자가 Dynamic Island 시스템 영역을 임의로 그리는 방식은 지원하지 않는다.
- 데이터는 기기 내부에만 저장한다. 계정, 서버, 네트워크, HealthKit, Apple Watch, 친구 순위, 음성 코칭은 v1 범위에 포함하지 않는다.

## 검증 명령

```sh
swift test
swift run IslandifyDomainChecks
xcodebuild -project Islandify.xcodeproj -target Islandify -sdk iphonesimulator -configuration Debug build
xcodebuild -project Islandify.xcodeproj -target IslandifyTests -sdk iphonesimulator -configuration Debug build
sh .codex/hooks/verify_goal.sh --complete
```
