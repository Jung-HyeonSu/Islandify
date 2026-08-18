import SwiftUI

enum IslandifyBrightPalette {
    static let background = Color(red: 0.969, green: 0.976, blue: 0.988)
    static let surface = Color.white
    static let text = Color(red: 0.090, green: 0.125, blue: 0.165)
    static let secondaryText = Color(red: 0.424, green: 0.467, blue: 0.522)
    static let accent = Color(red: 0.180, green: 0.420, blue: 1.000)
    static let accentSoft = Color(red: 0.898, green: 0.929, blue: 1.000)
    static let line = Color(red: 0.866, green: 0.886, blue: 0.918)
    static let shadow = Color(red: 0.180, green: 0.235, blue: 0.345).opacity(0.10)
}

struct IslandifyBrightCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .background(IslandifyBrightPalette.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(IslandifyBrightPalette.line, lineWidth: 1)
            }
            .shadow(color: IslandifyBrightPalette.shadow, radius: 18, y: 8)
    }
}

extension View {
    func islandifyBrightCardBackground(cornerRadius: CGFloat = 24) -> some View {
        background(
            IslandifyBrightPalette.surface,
            in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(IslandifyBrightPalette.line, lineWidth: 1)
        }
    }

    func islandifyBrightPageBackground() -> some View {
        background(IslandifyBrightPalette.background.ignoresSafeArea())
    }
}

enum IslandifyTab: Hashable {
    case home
    case timer
    case travel
    case relationship
    case running
}

struct HomeDashboardView: View {
    @EnvironmentObject private var model: IslandifyAppModel
    @Binding private var selectedTab: IslandifyTab
    @Binding private var showStyle: Bool

    private let copy = IslandifyCopy.current

    init(selectedTab: Binding<IslandifyTab>, showStyle: Binding<Bool>) {
        _selectedTab = selectedTab
        _showStyle = showStyle
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                header
                greeting
                activeSection
                nextActivities
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 28)
        }
        .islandifyBrightPageBackground()
        .onAppear { model.refresh() }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text(dateLabel)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(IslandifyBrightPalette.secondaryText)
                Text(copy.appName)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(IslandifyBrightPalette.text)
            }

            Spacer(minLength: 12)

            Button {
                showStyle = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(IslandifyBrightPalette.accent)
                    .frame(width: 42, height: 42)
                    .background(IslandifyBrightPalette.accentSoft, in: Circle())
            }
            .accessibilityLabel(copy.style)
        }
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(greetingTitle)
                .font(.system(size: 32, weight: .semibold, design: .rounded))
                .tracking(-0.8)
                .foregroundStyle(IslandifyBrightPalette.text)
            Text(greetingSubtitle)
                .font(.subheadline)
                .foregroundStyle(IslandifyBrightPalette.secondaryText)
        }
    }

    @ViewBuilder
    private var activeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(activeNowLabel)
                .font(.caption.weight(.semibold))
                .foregroundStyle(IslandifyBrightPalette.secondaryText)
                .textCase(.uppercase)
                .tracking(1.2)

            if let timer = model.activeTimer {
                timerCard(timer)
            } else if let travel = model.activeTravel {
                travelCard(travel)
            } else if let relationship = model.activeRelationship {
                relationshipCard(relationship)
            } else if let run = model.activeRun {
                runCard(run)
            } else {
                emptyActivityCard
            }
        }
    }

    private var emptyActivityCard: some View {
        IslandifyBrightCard {
            VStack(alignment: .leading, spacing: 13) {
                HStack {
                    Image(systemName: "circle.dashed")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(IslandifyBrightPalette.accent)
                    Spacer()
                    Text(copy.noActiveActivity)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(IslandifyBrightPalette.secondaryText)
                }
                Text(emptyActivityTitle)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(IslandifyBrightPalette.text)
                Text(emptyActivitySubtitle)
                    .font(.subheadline)
                    .foregroundStyle(IslandifyBrightPalette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func timerCard(_ state: TimerState) -> some View {
        let snapshot = TimerEngine.snapshot(for: state, at: model.now)
        return IslandifyBrightCard {
            VStack(alignment: .leading, spacing: 14) {
                activityHeader(
                    icon: state.configuration.icon,
                    title: state.configuration.name,
                    subtitle: copy.timer,
                    phase: copy.phaseLabel(state.phase)
                )

                Text(IslandifyTimeFormatter.duration(snapshot.remaining))
                    .font(.system(size: 52, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .tracking(-1.8)
                    .foregroundStyle(IslandifyBrightPalette.text)
                    .minimumScaleFactor(0.65)

                ProgressView(value: snapshot.progress)
                    .tint(IslandifyBrightPalette.accent)
                    .accessibilityValue(copy.progressPercent(Int((snapshot.progress * 100).rounded())))

                HStack(spacing: 8) {
                    Button {
                        Task {
                            if state.phase == .active {
                                await model.pauseTimer()
                            } else if state.phase == .paused {
                                await model.resumeTimer()
                            }
                        }
                    } label: {
                        Text(state.phase == .paused ? copy.resume : copy.pause)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(IslandifyBrightPalette.accent)
                    .disabled(state.phase == .completed || state.phase == .ended)

                    Button {
                        Task { await model.addMinute() }
                    } label: {
                        Text(copy.addMinute)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(IslandifyBrightPalette.accent)
                    .disabled(state.phase == .completed || state.phase == .ended)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(copy.timerRemaining(name: state.configuration.name, value: IslandifyTimeFormatter.duration(snapshot.remaining)))
    }

    private func travelCard(_ configuration: TravelConfiguration) -> some View {
        let state = TravelCalculator.state(for: configuration, at: model.now)
        return IslandifyBrightCard {
            VStack(alignment: .leading, spacing: 14) {
                activityHeader(
                    icon: configuration.icon,
                    title: configuration.tripName,
                    subtitle: copy.travel,
                    phase: state.label
                )
                Text(state.displayValue)
                    .font(.system(size: 48, weight: .semibold, design: .rounded))
                    .tracking(-1.3)
                    .foregroundStyle(IslandifyBrightPalette.text)
                Text(configuration.destination)
                    .font(.headline.weight(.medium))
                    .foregroundStyle(IslandifyBrightPalette.secondaryText)
                Button {
                    selectedTab = .travel
                } label: {
                    Label(copy.travel, systemImage: "arrow.up.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(IslandifyBrightPalette.accent)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(copy.travelAccessibility(tripName: configuration.tripName, destination: configuration.destination, value: state.displayValue))
    }

    private func relationshipCard(_ configuration: RelationshipConfiguration) -> some View {
        let snapshot = RelationshipCalculator.snapshot(for: configuration, at: model.now)
        return IslandifyBrightCard {
            VStack(alignment: .leading, spacing: 14) {
                activityHeader(
                    icon: configuration.icon,
                    title: configuration.name,
                    subtitle: copy.relationship,
                    phase: copy.relationshipDayMilestone(snapshot.dayCount)
                )
                Text(copy.relationshipDayMilestone(snapshot.dayCount))
                    .font(.system(size: 48, weight: .semibold, design: .rounded))
                    .tracking(-1.3)
                    .foregroundStyle(IslandifyBrightPalette.text)
                Text(snapshot.message)
                    .font(.headline.weight(.medium))
                    .foregroundStyle(IslandifyBrightPalette.secondaryText)
                    .lineLimit(2)
                if let next = snapshot.nextDayMilestone {
                    Text(copy.nextMilestone(next.title))
                        .font(.caption)
                        .foregroundStyle(IslandifyBrightPalette.secondaryText)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(snapshot.message)
    }

    private func runCard(_ state: RunningState) -> some View {
        let snapshot = RunningCalculator.snapshot(for: state, at: model.now)
        return IslandifyBrightCard {
            VStack(alignment: .leading, spacing: 14) {
                activityHeader(
                    icon: state.configuration.icon,
                    title: state.configuration.name,
                    subtitle: copy.running,
                    phase: IslandifyCopy.current.runningPhaseLabel(state.phase.rawValue)
                )
                HStack(alignment: .firstTextBaseline) {
                    Text(IslandifyTimeFormatter.distance(kilometers: snapshot.distanceKilometers))
                        .font(.system(size: 38, weight: .semibold, design: .rounded))
                        .tracking(-1.1)
                        .foregroundStyle(IslandifyBrightPalette.text)
                    Spacer()
                    Text(IslandifyTimeFormatter.duration(snapshot.elapsed))
                        .font(.title3.monospacedDigit().weight(.semibold))
                        .foregroundStyle(IslandifyBrightPalette.secondaryText)
                }
                HStack {
                    dashboardMetric(copy.averagePace, IslandifyTimeFormatter.pace(secondsPerKilometer: snapshot.averagePaceSecondsPerKilometer))
                    dashboardMetric(copy.calories, copy.caloriesValue(Int(snapshot.calories.rounded())))
                }
                Button {
                    selectedTab = .running
                } label: {
                    Label(copy.running, systemImage: "arrow.up.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(IslandifyBrightPalette.accent)
            }
        }
    }

    private var nextActivities: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(nextActivitiesLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(IslandifyBrightPalette.secondaryText)
                    .textCase(.uppercase)
                    .tracking(1.2)
                Spacer()
                Button {
                    selectedTab = .timer
                } label: {
                    Image(systemName: "plus")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(IslandifyBrightPalette.accent)
                        .frame(width: 30, height: 30)
                        .background(IslandifyBrightPalette.accentSoft, in: Circle())
                }
                .accessibilityLabel(copy.activity)
            }

            VStack(spacing: 8) {
                if model.activeTimer == nil { quickActivity(.timer, icon: "timer", title: copy.timerExampleName, subtitle: copy.timerDescription, value: copy.startTimer) }
                if model.activeTravel == nil { quickActivity(.travel, icon: "airplane.departure", title: copy.travelExampleName, subtitle: copy.travelDdayTitle, value: copy.startTripCountdown) }
                if model.activeRelationship == nil { quickActivity(.relationship, icon: "heart", title: copy.relationshipExampleName, subtitle: copy.relationship, value: copy.startRelationship) }
                if model.activeRun == nil { quickActivity(.running, icon: "figure.run", title: copy.runExampleName, subtitle: copy.running, value: copy.startRun) }
            }
        }
    }

    private func quickActivity(_ tab: IslandifyTab, icon: String, title: String, subtitle: String, value: String) -> some View {
        Button {
            selectedTab = tab
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.body.weight(.medium))
                    .foregroundStyle(IslandifyBrightPalette.accent)
                    .frame(width: 34, height: 34)
                    .background(IslandifyBrightPalette.accentSoft, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(IslandifyBrightPalette.text)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(IslandifyBrightPalette.secondaryText)
                }
                Spacer(minLength: 8)
                Text(value)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(IslandifyBrightPalette.accent)
                    .lineLimit(1)
            }
            .padding(12)
            .islandifyBrightCardBackground(cornerRadius: 18)
        }
        .buttonStyle(.plain)
        .accessibilityHint(value)
    }

    private func activityHeader(icon: ActivityIcon, title: String, subtitle: String, phase: String) -> some View {
        HStack(spacing: 11) {
            ActivityIconView(icon: icon)
                .font(.body.weight(.medium))
                .foregroundStyle(IslandifyBrightPalette.accent)
                .frame(width: 34, height: 34)
                .background(IslandifyBrightPalette.accentSoft, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(IslandifyBrightPalette.text)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(IslandifyBrightPalette.secondaryText)
            }
            Spacer(minLength: 8)
            Text(phase)
                .font(.caption.weight(.medium))
                .foregroundStyle(IslandifyBrightPalette.accent)
                .lineLimit(1)
        }
    }

    private func dashboardMetric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(IslandifyBrightPalette.secondaryText)
            Text(value)
                .font(.caption.monospacedDigit().weight(.semibold))
                .foregroundStyle(IslandifyBrightPalette.text)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("EEE, MMM d")
        return formatter.string(from: model.now)
    }

    private var greetingTitle: String {
        IslandifyLanguage.current == .korean ? "오늘을 가볍게" : "Keep today light"
    }

    private var greetingSubtitle: String {
        IslandifyLanguage.current == .korean ? "지금 필요한 활동만 선명하게 보여드릴게요." : "Only the activity you need, clearly in view."
    }

    private var activeNowLabel: String {
        IslandifyLanguage.current == .korean ? "지금 진행 중" : "Active now"
    }

    private var nextActivitiesLabel: String {
        IslandifyLanguage.current == .korean ? "다음 활동" : "Next activities"
    }

    private var emptyActivityTitle: String {
        IslandifyLanguage.current == .korean ? "오늘의 첫 활동을 시작해보세요." : "Start your first activity today."
    }

    private var emptyActivitySubtitle: String {
        IslandifyLanguage.current == .korean ? "아래에서 타이머, 여행, 함께, 러닝 중 하나를 선택할 수 있어요." : "Choose a timer, trip, relationship counter, or run below."
    }
}

private struct ActivityIconView: View {
    let icon: ActivityIcon

    var body: some View {
        Group {
            if icon.kind == .emoji {
                Text(icon.value)
            } else {
                Image(systemName: icon.value)
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    HomeDashboardView(selectedTab: .constant(.home), showStyle: .constant(false))
        .environmentObject(IslandifyAppModel())
}
