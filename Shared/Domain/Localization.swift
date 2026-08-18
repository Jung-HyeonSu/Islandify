import Foundation

/// Islandify supports Korean explicitly and uses English for every other
/// device language. Keeping this decision in one pure type lets the app,
/// widget extension, and domain formatters render the same language.
public enum IslandifyLanguage: String, Codable, Hashable, Sendable {
    case korean
    case english

    public init(localeIdentifier: String) {
        let normalized = localeIdentifier
            .replacingOccurrences(of: "_", with: "-")
            .lowercased()
        self = normalized == "ko" || normalized.hasPrefix("ko-") ? .korean : .english
    }

    public static var current: IslandifyLanguage {
        let identifier = Locale.preferredLanguages.first ?? Locale.current.identifier
        return IslandifyLanguage(localeIdentifier: identifier)
    }
}

public struct IslandifyCopy: Hashable, Sendable {
    public let language: IslandifyLanguage

    public init(language: IslandifyLanguage = .current) {
        self.language = language
    }

    public static var current: IslandifyCopy { IslandifyCopy() }

    private var isKorean: Bool { language == .korean }

    private func localized(_ korean: String, _ english: String) -> String {
        isKorean ? korean : english
    }

    public var appName: String { "Islandify" }
    public var widgetDescription: String {
        localized("현재 활동을 한눈에 보여주는 위젯입니다.", "A glanceable view of your current activity.")
    }

    public var timer: String { localized("타이머", "Timer") }
    public var travel: String { localized("여행", "Travel") }
    public var travelDdayTitle: String { localized("여행 디데이", "Travel D-day") }
    public var travelDday: String { localized("디데이", "D-DAY") }
    public var relationship: String { localized("함께", "Together") }
    public var running: String { localized("러닝", "Run") }
    public var style: String { localized("꾸미기", "Style") }

    public var timerExampleName: String { localized("집중 타이머", "Deep focus") }
    public var travelExampleName: String { localized("여름 여행", "Summer trip") }
    public var destinationExample: String { localized("서울", "Seoul") }
    public var relationshipExampleName: String { localized("우리의 날", "Our days") }
    public var runExampleName: String { localized("아침 러닝", "Morning run") }

    public var name: String { localized("이름", "Name") }
    public var timerName: String { localized("타이머 이름", "Timer name") }
    public var timerEmoji: String { localized("타이머 이모지", "Timer emoji") }
    public var tripName: String { localized("여행 이름", "Trip name") }
    public var destination: String { localized("목적지", "Destination") }
    public var tripEmoji: String { localized("여행 이모지", "Trip emoji") }
    public var anniversaryName: String { localized("기념일 이름", "Anniversary name") }
    public var nickname: String { localized("별명", "Nickname") }
    public var relationshipStartDate: String { localized("커플 시작일", "Relationship start date") }
    public var relationshipEmoji: String { localized("커플 이모지", "Relationship emoji") }
    public var runName: String { localized("러닝 이름", "Run name") }
    public var runEmoji: String { localized("러닝 이모지", "Run emoji") }
    public var optionalMemo: String { localized("메모(선택)", "Optional memo") }
    public var optionalRunMemo: String { localized("러닝 메모(선택)", "Optional run memo") }

    public var duration: String { localized("시간", "Duration") }
    public var icon: String { localized("아이콘", "Icon") }
    public var theme: String { localized("테마", "Theme") }
    public var alertSound: String { localized("알림음", "Alert sound") }
    public var progress: String { localized("진행률", "Progress") }
    public var timezone: String { localized("시간대", "Timezone") }
    public var departure: String { localized("출발", "Departure") }
    public var startDate: String { localized("시작일", "Start date") }
    public var departureDateAndTime: String { localized("출발 날짜 및 시간", "Departure date and time") }
    public var departureTimezone: String { localized("출발 시간대", "Departure timezone") }
    public var relationshipTimezone: String { localized("커플 시간대", "Relationship timezone") }
    public var timezoneExample: String { "Asia/Seoul" }

    public var startTimer: String { localized("타이머 시작", "Start timer") }
    public var startTripCountdown: String { localized("여행 카운트다운 시작", "Start trip countdown") }
    public var startRelationship: String { localized("D+ 시작", "Start D+") }
    public var startRun: String { localized("러닝 시작", "Start run") }
    public var pause: String { localized("일시정지", "Pause") }
    public var resume: String { localized("재개", "Resume") }
    public var reset: String { localized("초기화", "Reset") }
    public var end: String { localized("종료", "End") }
    public var endTrip: String { localized("여행 종료", "End trip") }
    public var endCounter: String { localized("카운터 종료", "End counter") }
    public var addMinute: String { localized("1분 추가", "+1 min") }
    public var moreTimerActions: String { localized("타이머 추가 동작", "More timer actions") }
    public var moreTripActions: String { localized("여행 추가 동작", "More trip actions") }
    public var moreRelationshipActions: String { localized("커플 추가 동작", "More relationship actions") }
    public var moreRunActions: String { localized("러닝 추가 동작", "More run actions") }

    public var timerFormDescription: String {
        localized(
            "절대 종료 시각을 기준으로 계산하므로 앱이 일시 중단되어도 정확한 시간을 유지합니다.",
            "The timer uses an absolute end date so it stays correct after suspension."
        )
    }

    public var runningFormDescription: String {
        localized(
            "러닝을 시작할 때만 위치 권한을 요청합니다. 권한을 거부해도 경과 시간만 측정하는 러닝으로 계속할 수 있습니다.",
            "Location is requested only when you start a run. If access is denied, elapsed time still works as a time-only run."
        )
    }

    public var customizationDescription: String {
        localized(
            "Apple이 정한 Live Activity 슬롯에 의미 있는 값을 조합합니다. Islandify는 Dynamic Island를 자유 캔버스로 바꾸지 않습니다.",
            "Choose semantic values for Apple's fixed Live Activity slots. Islandify never turns the Dynamic Island into a free-form canvas."
        )
    }

    public var startTimerHint: String {
        localized(
            "타이머를 시작하고 Live Activity가 활성화되어 있으면 표시합니다.",
            "Starts the timer and requests a Live Activity if it is enabled."
        )
    }

    public var startTripHint: String {
        localized(
            "여행 카운트다운을 시작하고 저장한 출발 시간대를 사용합니다.",
            "Starts the trip countdown and uses the saved departure timezone."
        )
    }

    public var startRelationshipHint: String {
        localized(
            "커플 카운터를 시작하고 선택하면 기념일 로컬 알림을 예약합니다.",
            "Starts the relationship counter and optionally schedules local milestone notifications."
        )
    }

    public var startRunHint: String {
        localized(
            "러닝을 시작하고 위치 권한을 요청합니다.",
            "Starts a run and requests location access."
        )
    }

    public var relationshipCounting: String { localized("계산 방식", "Counting") }
    public var dPlus0OnStartDate: String { localized("시작일을 D+0으로 계산", "D+0 on start date") }
    public var dPlus1OnStartDate: String { localized("시작일을 D+1로 계산", "D+1 on start date") }
    public var milestoneNotifications: String { localized("기념일 알림", "Milestone notifications") }
    public var endLiveActivityWhenComplete: String {
        localized("완료 시 Live Activity 종료", "End Live Activity when complete")
    }

    public var liveActivityTitle: String { localized("Live Activity 제목", "Live Activity title") }
    public var liveActivityDescription: String { localized("Live Activity 설명", "Live Activity description") }
    public var iconOrEmoji: String { localized("아이콘 / 이모지", "Icon / emoji") }
    public var liveActivityIconOrEmoji: String { localized("Live Activity 아이콘 또는 이모지", "Live Activity icon or emoji") }
    public var themeOrColor: String { localized("테마 / 색상", "Theme / color") }
    public var numberFormat: String { localized("숫자 형식", "Number format") }
    public var alignment: String { localized("정렬", "Alignment") }
    public var compactLeadingSlot: String { localized("축약 앞 슬롯", "Compact leading slot") }
    public var compactTrailingSlot: String { localized("축약 뒤 슬롯", "Compact trailing slot") }
    public var expandedDetails: String { localized("확장 상세 내용", "Expanded details") }
    public var completionMessage: String { localized("완료 문구", "Completion message") }
    public var saveLayout: String { localized("레이아웃 저장", "Save layout") }
    public var previewAllSurfaces: String { localized("모든 시스템 화면 미리보기", "Preview all system surfaces") }
    public var customize: String { localized("직접 꾸미기", "Customize") }
    public var activity: String { localized("활동", "Activity") }
    public var title: String { localized("제목", "Title") }
    public var shortDescription: String { localized("짧은 설명", "Short description") }
    public func detail(_ number: Int) -> String { localized("상세 \(number)", "Detail \(number)") }

    public var currentPace: String { localized("현재 페이스", "Current pace") }
    public var averagePace: String { localized("평균 페이스", "Average pace") }
    public var calories: String { localized("칼로리", "Calories") }
    public var recentRuns: String { localized("최근 러닝", "Recent runs") }
    public var completedRunsPlaceholder: String {
        localized("완료한 러닝이 여기에 표시됩니다.", "Completed runs will appear here.")
    }
    public var gpsDistanceActive: String { localized("GPS 거리 측정 중입니다.", "GPS distance is active.") }
    public var waitingForLocationPermission: String { localized("위치 권한을 기다리는 중…", "Waiting for location permission…") }
    public var locationDeniedTimeOnly: String { localized("위치 권한 거부 — 시간만 기록합니다.", "Location denied — recording time only.") }
    public var locationRestrictedTimeOnly: String { localized("위치 사용 제한 — 시간만 기록합니다.", "Location restricted — recording time only.") }
    public var locationUnavailableTimeOnly: String { localized("위치를 사용할 수 없음 — 시간만 기록합니다.", "Location unavailable — recording time only.") }
    public var elapsedTime: String { localized("경과 시간", "Elapsed time") }

    public var noActiveActivity: String { localized("활성 활동 없음", "No active activity") }
    public var activityDetailsInActiveTab: String { localized("활동 상세 정보는 활성 탭에서 확인할 수 있습니다.", "Activity details are shown in the active tab.") }
    public var openedFromSupportedLink: String { localized("지원되는 링크로 Islandify를 열었습니다.", "Islandify opened from a supported link.") }
    public var endCurrentActivity: String { localized("현재 활동을 종료한 후 다른 활동을 시작하세요.", "End the current activity before starting another one.") }
    public var liveActivitiesDisabled: String {
        localized(
            "Live Activity가 비활성화되어 있습니다. 타이머는 앱에서 계속 사용할 수 있습니다.",
            "Live Activities are disabled. The timer will still remain available in the app."
        )
    }
    public var duplicateLiveActivity: String {
        localized(
            "Islandify 활동이 이미 실행 중입니다. 새 활동을 시작하기 전에 기존 활동을 종료하세요.",
            "An Islandify activity is already running. End it before starting another one."
        )
    }
    public var noActiveLiveActivityToUpdate: String {
        localized("업데이트할 Live Activity가 없습니다.", "There is no active Live Activity to update.")
    }

    public var savedTimerLoadFailed: String { localized("저장된 타이머를 불러오지 못했습니다.", "Saved timer could not be loaded.") }
    public var savedTravelLoadFailed: String { localized("저장된 여행을 불러오지 못했습니다.", "Saved trip could not be loaded.") }
    public var savedRelationshipLoadFailed: String {
        localized("저장된 커플 카운터를 불러오지 못했습니다.", "Saved relationship counter could not be loaded.")
    }
    public var previousRunPaused: String {
        localized(
            "이전 러닝은 앱을 다시 실행하면서 일시정지되었습니다. GPS 추적을 계속하려면 재개하세요.",
            "The previous run was paused after relaunch. Resume it to continue GPS tracking."
        )
    }
    public var savedRunLoadFailed: String { localized("저장된 러닝을 불러오지 못했습니다.", "Saved run could not be loaded.") }
    public var runHistoryLoadFailed: String { localized("러닝 기록을 불러오지 못했습니다.", "Run history could not be loaded.") }
    public var savedCustomizationLoadFailed: String {
        localized("저장된 꾸미기 설정을 불러오지 못했습니다.", "Saved customization could not be loaded.")
    }
    public var timerSaveFailed: String { localized("이 기기에 타이머를 저장하지 못했습니다.", "Timer could not be saved on this device.") }
    public var travelSaveFailed: String { localized("이 기기에 여행을 저장하지 못했습니다.", "Trip could not be saved on this device.") }
    public var relationshipSaveFailed: String {
        localized("이 기기에 커플 카운터를 저장하지 못했습니다.", "Relationship counter could not be saved on this device.")
    }
    public var runSaveFailed: String { localized("이 기기에 러닝을 저장하지 못했습니다.", "Run could not be saved on this device.") }
    public var runHistorySaveFailed: String {
        localized("이 기기에 러닝 기록을 저장하지 못했습니다.", "Run history could not be saved on this device.")
    }
    public var customizationSaveFailed: String {
        localized("이 기기에 꾸미기 설정을 저장하지 못했습니다.", "Customization could not be saved on this device.")
    }
    public func duplicateSavedActivity(timerIsAuthoritative: Bool) -> String {
        if timerIsAuthoritative {
            return localized(
                "중복 저장 활동을 무시했습니다. 타이머를 기준으로 유지합니다.",
                "A duplicate saved activity was ignored; the timer remains authoritative."
            )
        }
        return localized(
            "중복 저장 활동을 무시했습니다. 먼저 저장된 활동을 기준으로 유지합니다.",
            "A duplicate saved activity was ignored; the first activity remains authoritative."
        )
    }

    public func activityName(_ kind: ActivityKind) -> String {
        switch kind {
        case .timer: return timer
        case .travel: return travel
        case .relationship: return relationship
        case .running: return running
        }
    }

    public func themeName(_ theme: IslandifyTheme) -> String {
        switch theme {
        case .minimalBlack: return localized("미니멀 블랙", "Minimal Black")
        case .pastelCouple: return localized("파스텔 커플", "Pastel Couple")
        case .travelBlue: return localized("트래블 블루", "Travel Blue")
        case .neonTimer: return localized("네온 타이머", "Neon Timer")
        case .runningGreen: return localized("러닝 그린", "Running Green")
        case .creamDiary: return localized("크림 다이어리", "Cream Diary")
        }
    }

    public func alertSoundName(_ rawValue: String) -> String {
        switch rawValue {
        case "none": return localized("없음", "None")
        case "chime": return localized("차임", "Chime")
        case "bell": return localized("벨", "Bell")
        case "gentle": return localized("부드러운 알림", "Gentle")
        default: return rawValue.capitalized
        }
    }

    public func progressStyleName(_ style: ProgressStyle) -> String {
        switch style {
        case .bar: return localized("막대", "Bar")
        case .circle: return localized("원형", "Circle")
        case .dots: return localized("점", "Dots")
        case .hidden: return localized("숨김", "Hidden")
        }
    }

    public func numberFormatName(_ format: NumberFormat) -> String {
        switch format {
        case .duration: return localized("시간", "Duration")
        case .compactDuration: return localized("간단한 시간", "Compact duration")
        case .decimal: return localized("소수", "Decimal")
        case .pace: return localized("페이스", "Pace")
        case .dayCount: return localized("일수", "Day count")
        case .distance: return localized("거리", "Distance")
        }
    }

    public func alignmentName(_ alignment: SlotAlignment) -> String {
        switch alignment {
        case .leading: return localized("앞쪽", "Leading")
        case .center: return localized("가운데", "Center")
        case .trailing: return localized("뒤쪽", "Trailing")
        }
    }

    public func slotName(_ slot: PresentationSlot) -> String {
        switch slot {
        case .icon: return localized("아이콘", "Icon")
        case .title: return localized("제목", "Title")
        case .description: return localized("설명", "Description")
        case .primaryValue: return localized("기본 값", "Primary value")
        case .secondaryValue: return localized("보조 값", "Secondary value")
        case .progress: return localized("진행률", "Progress")
        case .phase: return localized("상태", "Phase")
        }
    }

    public func surfaceName(_ surface: ActivitySurface) -> String {
        switch surface {
        case .compact: return localized("축약", "Compact")
        case .minimal: return localized("미니멀", "Minimal")
        case .expanded: return localized("확장", "Expanded")
        case .lockScreen: return localized("잠금 화면", "Lock Screen")
        }
    }

    public func phaseLabel(_ phase: ActivityPhase) -> String {
        switch phase {
        case .configured: return localized("준비", "Ready")
        case .active: return localized("진행 중", "Active")
        case .paused: return localized("일시정지", "Paused")
        case .completed: return localized("완료", "Completed")
        case .ended: return localized("종료", "Ended")
        }
    }

    public func runningPhaseLabel(_ rawValue: String) -> String {
        switch rawValue {
        case "configured": return localized("준비", "Ready")
        case "active": return localized("진행 중", "Active")
        case "paused": return localized("일시정지", "Paused")
        case "completed": return localized("완료", "Completed")
        case "ended": return localized("종료", "Ended")
        default: return rawValue.capitalized
        }
    }

    public func iconAccessibilityLabel(_ icon: ActivityIcon) -> String {
        icon.kind == .emoji
            ? localized("이모지 \(icon.value)", "Emoji \(icon.value)")
            : icon.value.replacingOccurrences(of: ".", with: " ")
    }

    public var defaultCompletionMessage: String { localized("완료", "Done") }

    public func defaultPresentation(for kind: ActivityKind) -> (title: String, completion: String) {
        switch kind {
        case .timer: return (localized("집중", "Focus"), localized("집중 완료", "Focus complete"))
        case .travel: return (localized("여행", "Trip"), localized("즐거운 여행 되세요", "Have a great trip"))
        case .relationship: return (localized("함께", "Together"), localized("오늘도 함께", "Another day together"))
        case .running: return (localized("러닝", "Run"), localized("러닝 완료", "Run complete"))
        }
    }

    public var timerDescription: String { localized("타이머", "Timer") }
    public var runningDescription: String { localized("GPS 러닝", "GPS run") }
    public var defaultRunningName: String { localized("러닝", "Run") }

    public func timerCompletion(name: String) -> String {
        localized("\(name) 완료", "\(name) complete")
    }

    public func durationMinutes(_ minutes: Int) -> String {
        localized("\(minutes)분", "\(minutes) min")
    }

    public func durationAccessibility(minutes: Int) -> String {
        localized("시간, \(minutes)분", "Duration, \(minutes) minutes")
    }

    public func timerRemaining(name: String, value: String) -> String {
        localized("\(name), \(value) 남음", "\(name), \(value) remaining")
    }

    public func progressPercent(_ percent: Int) -> String {
        localized("진행률 \(percent)%", "Progress \(percent)%")
    }

    public func travelCountdown(hours: Int, minutes: Int) -> String {
        localized("\(hours)시간 \(minutes)분", "\(hours)h \(minutes)m")
    }

    public var travelStarted: String { localized("여행 시작", "Trip started") }

    public func travelAccessibility(tripName: String, destination: String, value: String) -> String {
        localized("\(tripName), \(destination), \(value)", "\(tripName), \(destination), \(value)")
    }

    public func relationshipDayMilestone(_ value: Int) -> String { "D+\(value)" }

    public func annualMilestone(years: Int) -> String {
        localized("\(years)주년", "\(years)-year anniversary")
    }

    public func relationshipMessage(name: String, dayCount: Int) -> String {
        localized("\(name)와 함께한 D+\(dayCount)", "D+\(dayCount) with \(name)")
    }

    public func nextMilestone(_ title: String) -> String {
        localized("다음 \(title)", "Next \(title)")
    }

    public func annualMilestoneLabel(_ title: String) -> String {
        localized("주년: \(title)", "Annual: \(title)")
    }

    public func relationshipDayNotificationBody(name: String, title: String) -> String {
        localized("\(name), 오늘은 \(title)입니다.", "\(name), today is \(title)")
    }

    public func relationshipAnnualNotificationBody(name: String, title: String) -> String {
        localized("\(name), 오늘은 \(title)입니다.", "\(name), \(title)")
    }

    public func runningDetails(distance: String, elapsed: String, pace: String) -> [String] {
        [distance, localized("시간 \(elapsed)", "Time \(elapsed)"), localized("페이스 \(pace)", "Pace \(pace)")]
    }

    public func runningAccessibility(name: String, distance: String, pace: String, elapsed: String) -> String {
        "\(name), \(distance), \(pace), \(elapsed)"
    }

    public func caloriesValue(_ calories: Int) -> String { "\(calories) kcal" }

    public func locationMessage(for rawValue: String) -> String {
        switch rawValue {
        case "notDetermined":
            return localized(
                "위치 권한을 요청하는 중입니다. 권한을 결정하는 동안에도 러닝을 계속할 수 있습니다.",
                "Location permission is being requested. The run can continue while permission is decided."
            )
        case "denied":
            return localized("위치 접근이 거부되었습니다. 시간만 측정하는 러닝으로 계속합니다.", "Location access was denied. This run will continue as a time-only run.")
        case "restricted":
            return localized("위치 접근이 제한되었습니다. 시간만 측정하는 러닝으로 계속합니다.", "Location access is restricted. This run will continue as a time-only run.")
        case "unavailable":
            return localized("위치를 사용할 수 없습니다. 시간만 측정하는 러닝으로 계속합니다.", "Location is unavailable. This run will continue as a time-only run.")
        case "authorizedWhenInUse", "authorizedAlways":
            return ""
        default:
            return ""
        }
    }

    public func errorMessage(code: String) -> String? {
        switch code {
        case "timer.emptyName": return localized("이름을 입력해 주세요.", "Enter a name.")
        case "timer.durationTooShort": return localized("타이머는 1분 이상이어야 합니다.", "The timer must be at least 1 minute.")
        case "timer.durationTooLong": return localized("타이머는 8시간 이하여야 합니다.", "The timer cannot exceed 8 hours.")
        case "timer.alreadyActive": return localized("타이머가 이미 실행 중입니다.", "The timer is already active.")
        case "timer.notActive": return localized("실행 중인 타이머가 없습니다.", "The timer is not active.")
        case "timer.notPaused": return localized("일시정지된 타이머가 아닙니다.", "The timer is not paused.")
        case "timer.cannotModifyCompletedTimer": return localized("완료된 타이머는 수정할 수 없습니다.", "A completed timer cannot be modified.")
        case "timer.durationLimitReached": return localized("타이머는 최대 8시간까지 설정할 수 있습니다.", "The timer can be up to 8 hours.")
        case "travel.emptyTripName": return localized("여행 이름을 입력해 주세요.", "Enter a trip name.")
        case "travel.emptyDestination": return localized("목적지를 입력해 주세요.", "Enter a destination.")
        case "travel.invalidTimeZoneIdentifier": return localized("올바른 시간대를 입력해 주세요.", "Enter a valid timezone identifier.")
        case "composition.emptyTitle": return localized("제목을 입력해 주세요.", "Enter a title.")
        case "composition.titleTooLong": return localized("제목은 32자 이하여야 합니다.", "The title must be 32 characters or fewer.")
        case "composition.descriptionTooLong": return localized("설명은 80자 이하여야 합니다.", "The description must be 80 characters or fewer.")
        case "composition.completionMessageTooLong": return localized("완료 문구는 80자 이하여야 합니다.", "The completion message must be 80 characters or fewer.")
        case "composition.tooManyExpandedDetails": return localized("확장 상세 내용은 4개까지 설정할 수 있습니다.", "You can choose up to four expanded details.")
        default: return nil
        }
    }

    public func validationMessage(code: String) -> String {
        errorMessage(code: "composition.\(code)") ?? code
    }

    public func savedLayout(for kind: ActivityKind) -> String {
        localized("\(activityName(kind)) 레이아웃을 저장했습니다.", "Saved \(activityName(kind)) layout.")
    }
}
