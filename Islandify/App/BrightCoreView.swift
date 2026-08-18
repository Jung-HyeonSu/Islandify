import SwiftUI

enum IslandifyBrightPalette {
    static let background = Color(red: 0.985, green: 0.987, blue: 0.995)
    static let surface = Color.white
    static let surfaceSoft = Color(red: 0.972, green: 0.978, blue: 0.994)
    static let text = Color(red: 0.105, green: 0.125, blue: 0.205)
    static let secondaryText = Color(red: 0.420, green: 0.450, blue: 0.550)
    static let mutedText = Color(red: 0.590, green: 0.610, blue: 0.700)
    static let blue = Color(red: 0.240, green: 0.620, blue: 0.985)
    static let accent = blue
    static let lavender = Color(red: 0.520, green: 0.470, blue: 0.965)
    static let pink = Color(red: 0.965, green: 0.490, blue: 0.820)
    static let mint = Color(red: 0.360, green: 0.780, blue: 0.830)
    static let line = Color(red: 0.900, green: 0.910, blue: 0.950)
    static let shadow = Color(red: 0.260, green: 0.300, blue: 0.470).opacity(0.11)

    static let heroGradient = LinearGradient(
        colors: [
            Color(red: 0.370, green: 0.820, blue: 0.985),
            Color(red: 0.450, green: 0.570, blue: 0.985),
            Color(red: 0.820, green: 0.560, blue: 0.950),
            Color(red: 0.985, green: 0.650, blue: 0.875)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let brandGradient = LinearGradient(
        colors: [blue, lavender, pink],
        startPoint: .leading,
        endPoint: .trailing
    )

    static func activityTint(_ tab: IslandifyTab) -> Color {
        switch tab {
        case .home: return blue
        case .timer: return blue
        case .travel: return lavender
        case .relationship: return pink
        case .running: return mint
        }
    }
}

struct IslandifyBrightCard<Content: View>: View {
    private let padding: CGFloat
    private let cornerRadius: CGFloat
    private let content: Content

    init(
        padding: CGFloat = 18,
        cornerRadius: CGFloat = 28,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(IslandifyBrightPalette.surface, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(IslandifyBrightPalette.line, lineWidth: 1)
            }
            .shadow(color: IslandifyBrightPalette.shadow, radius: 20, y: 8)
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
        .shadow(color: IslandifyBrightPalette.shadow, radius: 16, y: 6)
    }

    func islandifyBrightPageBackground() -> some View {
        background {
            ZStack {
                IslandifyBrightPalette.background.ignoresSafeArea()
                Circle()
                    .fill(IslandifyBrightPalette.blue.opacity(0.08))
                    .frame(width: 250, height: 250)
                    .blur(radius: 48)
                    .offset(x: -150, y: -300)
                Circle()
                    .fill(IslandifyBrightPalette.pink.opacity(0.07))
                    .frame(width: 260, height: 260)
                    .blur(radius: 52)
                    .offset(x: 160, y: 390)
            }
            .ignoresSafeArea()
        }
    }

    func islandifyInputStyle() -> some View {
        padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(IslandifyBrightPalette.surfaceSoft, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(IslandifyBrightPalette.line, lineWidth: 1)
            }
    }
}

struct IslandifyBrandWordmark: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Islandify")
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .tracking(-1.1)
                .foregroundStyle(IslandifyBrightPalette.brandGradient)
            Text(IslandifyLanguage.current == .korean ? "시간을 더 가치 있게" : "Make every moment count")
                .font(.caption.weight(.medium))
                .foregroundStyle(IslandifyBrightPalette.secondaryText)
        }
    }
}

struct IslandifyPageHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    let symbolName: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(eyebrow.uppercased())
                    .font(.caption.weight(.bold))
                    .tracking(1.4)
                    .foregroundStyle(IslandifyBrightPalette.secondaryText)
                Text(title)
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .tracking(-0.7)
                    .foregroundStyle(IslandifyBrightPalette.text)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(IslandifyBrightPalette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 10)
            Image(systemName: symbolName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(IslandifyBrightPalette.brandGradient)
                .frame(width: 48, height: 48)
                .background(IslandifyBrightPalette.surface, in: Circle())
                .overlay { Circle().stroke(IslandifyBrightPalette.line, lineWidth: 1) }
                .shadow(color: IslandifyBrightPalette.shadow, radius: 12, y: 5)
                .accessibilityHidden(true)
        }
    }
}

struct IslandifyHeroCard: View {
    let eyebrow: String
    let value: String
    let detail: String
    let progress: Double?
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        eyebrow: String,
        value: String,
        detail: String,
        progress: Double? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.eyebrow = eyebrow
        self.value = value
        self.detail = detail
        self.progress = progress
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: 14) {
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 52, style: .continuous)
                    .fill(IslandifyBrightPalette.heroGradient)
                    .overlay {
                        RoundedRectangle(cornerRadius: 52, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.9), IslandifyBrightPalette.pink.opacity(0.75)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    }
                    .shadow(color: IslandifyBrightPalette.lavender.opacity(0.33), radius: 22, y: 12)

                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(eyebrow)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.84))
                        Text(value)
                            .font(.system(size: 42, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .tracking(-1.6)
                            .foregroundStyle(.white)
                            .minimumScaleFactor(0.55)
                            .lineLimit(1)
                        Text(detail)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white.opacity(0.86))
                            .lineLimit(1)
                    }
                    Spacer(minLength: 8)
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.95), IslandifyBrightPalette.pink.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 34, height: 34)
                        .overlay { Circle().stroke(.white.opacity(0.6), lineWidth: 1) }
                        .shadow(color: .white.opacity(0.55), radius: 10)
                }
                .padding(.horizontal, 24)
                .padding(.top, 22)
                .padding(.bottom, 38)

                IslandifyMascot(size: 88)
                    .offset(y: -10)
            }
            .frame(height: 176)

            if let progress {
                IslandifyGradientProgressBar(value: progress)
                    .accessibilityValue(IslandifyCopy.current.progressPercent(Int((progress * 100).rounded())))
            }

            if let actionTitle, let action {
                IslandifyGradientButton(title: actionTitle, action: action)
            }
        }
    }
}

struct IslandifyMascot: View {
    let size: CGFloat

    var body: some View {
        ZStack(alignment: .bottom) {
            HStack(spacing: size * 0.64) {
                Circle()
                    .fill(LinearGradient(colors: [.white, Color(red: 0.86, green: 0.80, blue: 1)], startPoint: .top, endPoint: .bottom))
                    .frame(width: size * 0.36, height: size * 0.30)
                Circle()
                    .fill(LinearGradient(colors: [.white, Color(red: 0.98, green: 0.78, blue: 0.92)], startPoint: .top, endPoint: .bottom))
                    .frame(width: size * 0.36, height: size * 0.30)
            }
            .offset(y: size * 0.10)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [.white, Color(red: 0.89, green: 0.84, blue: 1.0), Color(red: 0.98, green: 0.78, blue: 0.92)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size * 0.86)
                .overlay { Circle().stroke(.white.opacity(0.9), lineWidth: 1) }
                .shadow(color: IslandifyBrightPalette.pink.opacity(0.26), radius: 12, y: 5)

            HStack(spacing: size * 0.20) {
                IslandifyMascotEye(size: size * 0.16)
                IslandifyMascotEye(size: size * 0.16)
            }
            .offset(y: -size * 0.12)

            Capsule()
                .fill(Color(red: 0.32, green: 0.06, blue: 0.28))
                .frame(width: size * 0.28, height: size * 0.18)
                .overlay(alignment: .bottom) {
                    Capsule()
                        .fill(IslandifyBrightPalette.pink)
                        .frame(width: size * 0.15, height: size * 0.07)
                        .offset(y: -size * 0.025)
                }
                .offset(y: size * 0.13)
        }
        .frame(width: size * 1.55, height: size * 1.02)
        .accessibilityHidden(true)
    }
}

private struct IslandifyMascotEye: View {
    let size: CGFloat

    var body: some View {
        Capsule()
            .fill(Color(red: 0.04, green: 0.08, blue: 0.30))
            .frame(width: size * 0.62, height: size)
            .overlay(alignment: .topLeading) {
                Circle()
                    .fill(.white)
                    .frame(width: size * 0.25, height: size * 0.25)
                    .offset(x: size * 0.14, y: size * 0.15)
            }
    }
}

struct IslandifyGradientProgressBar: View {
    let value: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(IslandifyBrightPalette.surfaceSoft)
                Capsule()
                    .fill(IslandifyBrightPalette.brandGradient)
                    .frame(width: max(10, proxy.size.width * min(max(value, 0), 1)))
            }
        }
        .frame(height: 10)
        .clipShape(Capsule())
    }
}

struct IslandifyActivityTile: View {
    let title: String
    let icon: String
    let tint: Color
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(tint)
                    .frame(width: 42, height: 42)
                    .background(tint.opacity(selected ? 0.16 : 0.09), in: Circle())
                Text(title)
                    .font(.caption.weight(selected ? .semibold : .medium))
                    .foregroundStyle(IslandifyBrightPalette.text)
                    .lineLimit(1)
            }
            .frame(width: 64, height: 90)
            .background(IslandifyBrightPalette.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(selected ? tint.opacity(0.72) : IslandifyBrightPalette.line, lineWidth: selected ? 1.5 : 1)
            }
            .shadow(color: selected ? tint.opacity(0.14) : IslandifyBrightPalette.shadow.opacity(0.55), radius: 12, y: 5)
        }
        .buttonStyle(.plain)
    }
}

struct IslandifyGradientButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(IslandifyBrightPalette.brandGradient, in: Capsule())
                .shadow(color: IslandifyBrightPalette.lavender.opacity(0.24), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
    }
}

struct IslandifyPickerOption<Value: Hashable>: Identifiable {
    let value: Value
    let title: String

    var id: String { String(describing: value) }
}

struct IslandifyPickerRow<Value: Hashable>: View {
    let title: String
    @Binding var selection: Value
    let options: [IslandifyPickerOption<Value>]

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(IslandifyBrightPalette.text)
            Spacer(minLength: 8)
            Menu {
                ForEach(options) { option in
                    Button {
                        selection = option.value
                    } label: {
                        HStack {
                            Text(option.title)
                            if selection == option.value {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(options.first(where: { $0.value == selection })?.title ?? "—")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(IslandifyBrightPalette.lavender)
                        .lineLimit(1)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(IslandifyBrightPalette.mutedText)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(IslandifyBrightPalette.surfaceSoft, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(IslandifyBrightPalette.line, lineWidth: 1)
        }
    }
}

struct IslandifyMessageBanner: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "sparkles")
                .foregroundStyle(IslandifyBrightPalette.lavender)
            Text(message)
                .font(.footnote)
                .foregroundStyle(IslandifyBrightPalette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(IslandifyBrightPalette.surfaceSoft, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(IslandifyBrightPalette.line, lineWidth: 1)
        }
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

    init(selectedTab: Binding<IslandifyTab>, showStyle: Binding<Bool>) {
        _selectedTab = selectedTab
        _showStyle = showStyle
    }

    var body: some View {
        let copy = IslandifyCopy.current
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                header
                greeting
                activeHero
                activityRail
                todaySummary
                relationshipShortcut

                if let message = model.message {
                    IslandifyMessageBanner(message: message)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .islandifyBrightPageBackground()
        .onAppear { model.refresh() }
        .accessibilityLabel(copy.appName)
    }

    private var header: some View {
        HStack(alignment: .top) {
            IslandifyBrandWordmark()
            Spacer(minLength: 12)
            Button { showStyle = true } label: {
                Image(systemName: "gearshape")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(IslandifyBrightPalette.secondaryText)
                    .frame(width: 44, height: 44)
                    .background(IslandifyBrightPalette.surface, in: Circle())
                    .overlay { Circle().stroke(IslandifyBrightPalette.line, lineWidth: 1) }
                    .shadow(color: IslandifyBrightPalette.shadow, radius: 12, y: 5)
            }
            .accessibilityLabel(IslandifyCopy.current.style)
        }
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(IslandifyLanguage.current == .korean ? "오늘의 흐름" : "Your flow today")
                .font(.system(size: 25, weight: .semibold, design: .rounded))
                .tracking(-0.6)
                .foregroundStyle(IslandifyBrightPalette.text)
            Text(IslandifyLanguage.current == .korean ? "중요한 시간 하나를 선명하게 남겨보세요." : "Keep one important moment clearly in view.")
                .font(.subheadline)
                .foregroundStyle(IslandifyBrightPalette.secondaryText)
        }
    }

    @ViewBuilder
    private var activeHero: some View {
        let copy = IslandifyCopy.current
        if let timer = model.activeTimer {
            let snapshot = TimerEngine.snapshot(for: timer, at: model.now)
            let actionTitle: String? = timer.phase == .active ? copy.pause : timer.phase == .paused ? copy.resume : nil
            IslandifyHeroCard(
                eyebrow: copy.timer,
                value: IslandifyTimeFormatter.duration(snapshot.remaining),
                detail: timer.configuration.name,
                progress: snapshot.progress,
                actionTitle: actionTitle,
                action: actionTitle == nil ? nil : {
                    Task {
                        if timer.phase == .active { await model.pauseTimer() } else { await model.resumeTimer() }
                    }
                }
            )
            .accessibilityElement(children: .contain)
            .accessibilityLabel(copy.timerRemaining(name: timer.configuration.name, value: IslandifyTimeFormatter.duration(snapshot.remaining)))
        } else if let travel = model.activeTravel {
            let state = TravelCalculator.state(for: travel, at: model.now)
            IslandifyHeroCard(eyebrow: copy.travel, value: state.displayValue, detail: travel.destination)
                .accessibilityLabel(copy.travelAccessibility(tripName: travel.tripName, destination: travel.destination, value: state.displayValue))
        } else if let relationship = model.activeRelationship {
            let snapshot = RelationshipCalculator.snapshot(for: relationship, at: model.now)
            IslandifyHeroCard(eyebrow: copy.relationship, value: "D+\(snapshot.dayCount)", detail: snapshot.message)
                .accessibilityLabel(snapshot.message)
        } else if let run = model.activeRun {
            let snapshot = RunningCalculator.snapshot(for: run, at: model.now)
            IslandifyHeroCard(eyebrow: copy.running, value: IslandifyTimeFormatter.distance(kilometers: snapshot.distanceKilometers), detail: IslandifyTimeFormatter.duration(snapshot.elapsed))
                .accessibilityLabel(run.configuration.name)
        } else {
            IslandifyHeroCard(
                eyebrow: copy.timer,
                value: "00:00",
                detail: IslandifyLanguage.current == .korean ? "첫 활동을 시작해보세요" : "Start your first activity",
                actionTitle: copy.startTimer,
                action: { selectedTab = .timer }
            )
        }
    }

    private var activityRail: some View {
        let copy = IslandifyCopy.current
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                IslandifyActivityTile(title: copy.timer, icon: "timer", tint: IslandifyBrightPalette.blue, selected: selectedTab == .timer) { selectedTab = .timer }
                IslandifyActivityTile(title: copy.travel, icon: "airplane.departure", tint: IslandifyBrightPalette.lavender, selected: selectedTab == .travel) { selectedTab = .travel }
                IslandifyActivityTile(title: copy.relationship, icon: "heart.fill", tint: IslandifyBrightPalette.pink, selected: selectedTab == .relationship) { selectedTab = .relationship }
                IslandifyActivityTile(title: copy.running, icon: "figure.run", tint: IslandifyBrightPalette.mint, selected: selectedTab == .running) { selectedTab = .running }
                IslandifyActivityTile(title: copy.style, icon: "sparkles", tint: IslandifyBrightPalette.lavender, selected: false) { showStyle = true }
            }
        }
    }

    private var todaySummary: some View {
        let copy = IslandifyCopy.current
        return IslandifyBrightCard(padding: 20, cornerRadius: 30) {
            VStack(alignment: .leading, spacing: 15) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(IslandifyLanguage.current == .korean ? "오늘의 시간" : "Today's time")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(IslandifyBrightPalette.text)
                        Text(IslandifyLanguage.current == .korean ? "집중한 시간" : "Focused time")
                            .font(.caption)
                            .foregroundStyle(IslandifyBrightPalette.secondaryText)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(IslandifyBrightPalette.lavender)
                }
                HStack(alignment: .firstTextBaseline) {
                    Text(todayValue)
                        .font(.system(size: 42, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .tracking(-1.2)
                        .foregroundStyle(IslandifyBrightPalette.blue)
                    Spacer()
                    Text(IslandifyLanguage.current == .korean ? "오늘" : "Today")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(IslandifyBrightPalette.secondaryText)
                }
                IslandifyGradientProgressBar(value: todayProgress)
                    .accessibilityValue(copy.progressPercent(Int((todayProgress * 100).rounded())))
                HStack(spacing: 8) {
                    ForEach(Array(weekBars.enumerated()), id: \.offset) { index, value in
                        VStack(spacing: 5) {
                            Capsule()
                                .fill(index == 6 ? AnyShapeStyle(IslandifyBrightPalette.brandGradient) : AnyShapeStyle(IslandifyBrightPalette.lavender.opacity(0.32)))
                                .frame(height: max(10, 42 * value))
                            Text(weekdayLabel(for: index))
                                .font(.caption2)
                                .foregroundStyle(IslandifyBrightPalette.mutedText)
                        }
                        .frame(maxWidth: .infinity, alignment: .bottom)
                    }
                }
                .frame(height: 64, alignment: .bottom)
            }
        }
    }

    private var relationshipShortcut: some View {
        let copy = IslandifyCopy.current
        return Button {
            selectedTab = .relationship
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "heart.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(IslandifyBrightPalette.pink)
                    .frame(width: 42, height: 42)
                    .background(IslandifyBrightPalette.pink.opacity(0.12), in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text(model.activeRelationship.map { copy.relationshipDayMilestone(RelationshipCalculator.dayCount(for: $0, at: model.now)) } ?? copy.relationshipExampleName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(IslandifyBrightPalette.text)
                    Text(model.activeRelationship?.nickname.isEmpty == false ? model.activeRelationship!.nickname : copy.relationship)
                        .font(.caption)
                        .foregroundStyle(IslandifyBrightPalette.secondaryText)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(IslandifyBrightPalette.mutedText)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .islandifyBrightCardBackground(cornerRadius: 22)
        }
        .buttonStyle(.plain)
    }

    private var todayValue: String {
        if let timer = model.activeTimer {
            let snapshot = TimerEngine.snapshot(for: timer, at: model.now)
            return IslandifyTimeFormatter.duration(snapshot.elapsed)
        }
        if let run = model.activeRun {
            return IslandifyTimeFormatter.duration(RunningCalculator.snapshot(for: run, at: model.now).elapsed)
        }
        return "00:00"
    }

    private var todayProgress: Double {
        if let timer = model.activeTimer { return TimerEngine.snapshot(for: timer, at: model.now).progress }
        if let run = model.activeRun { return min(1, RunningCalculator.snapshot(for: run, at: model.now).elapsed / 3_600) }
        return 0.08
    }

    private var weekBars: [Double] {
        let calendar = Calendar.current
        return (0..<7).map { index in
            let day = calendar.date(byAdding: .day, value: index - 6, to: model.now) ?? model.now
            let duration = model.runRecords
                .filter { calendar.isDate($0.endDate, inSameDayAs: day) }
                .reduce(0) { $0 + $1.duration }
            return min(1, duration / 3_600)
        }
    }

    private func weekdayLabel(for index: Int) -> String {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: index - 6, to: model.now) ?? model.now
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("E")
        return formatter.string(from: date).prefix(1).description
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
