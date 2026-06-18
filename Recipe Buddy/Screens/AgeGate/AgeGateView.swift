import SwiftUI

struct AgeGateView: View {
    @ObservedObject var coordinator: AppCoordinator

    @State private var step: BirthStep = .day
    @State private var selectedDay: Int
    @State private var selectedMonth: Int
    @State private var selectedYear: Int
    @State private var isSaving: Bool = false

    private let minimumAge: Int = 13

    init(coordinator: AppCoordinator) {
        self.coordinator = coordinator

        let today = Date()
        let calendar = Calendar.current
        let y = calendar.component(.year, from: today) - 18
        let m = calendar.component(.month, from: today)
        let d = calendar.component(.day, from: today)

        _selectedYear = State(initialValue: y)
        _selectedMonth = State(initialValue: m)
        _selectedDay = State(initialValue: d)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.Background, Color.Surface.opacity(0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 22) {
                Spacer(minLength: 10)

                VStack(spacing: 8) {
                    Text(LocalizedStringKey(step.title))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.AppPrimary)

                    Text("Doğum tarihini seçerek hesabını tamamla.")
                        .font(.subheadline)
                        .foregroundStyle(.TextSecondary)
                        .multilineTextAlignment(.center)
                }

                StepDots(step: step)

                RulerSelector(
                    value: currentValueBinding,
                    range: currentRange,
                    displayText: currentDisplay,
                    centerCaption: step.caption,
                    rangeCaption: step.rangeText(for: currentRange),
                    majorStep: step.majorStep
                )
                .frame(height: 250)
                .padding(.horizontal, 16)

                VStack(spacing: 4) {
                    Text(LocalizedText.selectedDate(selectedDateText))
                        .font(.footnote)
                        .foregroundStyle(.TextSecondary)

                    Text(LocalizedText.ageLabel(calculatedAge))
                        .font(.footnote)
                        .foregroundStyle(calculatedAge >= minimumAge ? .TextSecondary : .Danger)
                }

                if step == .year && calculatedAge < minimumAge {
                    Text("Bu uygulama 13 yaş ve üzeri kullanıcılar içindir.")
                        .font(.footnote)
                        .foregroundStyle(.Danger)
                }

                HStack(spacing: 12) {
                    if step != .day {
                        Button {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                                step = step.previous
                            }
                        } label: {
                            Text("Geri")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(Color.Surface.opacity(0.8))
                                .foregroundStyle(.TextPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }

                    Button {
                        handlePrimaryAction()
                    } label: {
                        HStack(spacing: 8) {
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(step == .year ? "Devam Et" : "İleri")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(primaryEnabled ? Color.AppPrimary : Color.SurfaceBorder)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(!primaryEnabled)
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 24)
            }
        }
        .onChange(of: selectedYear) { _, _ in
            normalizeDayForMonthYear()
        }
        .onChange(of: selectedMonth) { _, _ in
            normalizeDayForMonthYear()
        }
    }

    private var currentRange: ClosedRange<Int> {
        switch step {
        case .day:
            return 1...maxDayInSelectedMonth
        case .month:
            return 1...12
        case .year:
            let currentYear = Calendar.current.component(.year, from: Date())
            return (currentYear - 100)...currentYear
        }
    }

    private var currentValueBinding: Binding<Int> {
        switch step {
        case .day:
            return $selectedDay
        case .month:
            return $selectedMonth
        case .year:
            return $selectedYear
        }
    }

    private var currentDisplay: (Int) -> String {
        switch step {
        case .day:
            return { "\($0)" }
        case .month:
            return { monthShortName($0) }
        case .year:
            return { "\($0)" }
        }
    }

    private var selectedDate: Date? {
        var comps = DateComponents()
        comps.year = selectedYear
        comps.month = selectedMonth
        comps.day = selectedDay
        comps.hour = 12
        comps.minute = 0
        comps.second = 0
        return Calendar.current.date(from: comps)
    }

    private var selectedDateText: String {
        guard let selectedDate else { return "-" }
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: selectedDate)
    }

    private var calculatedAge: Int {
        guard let selectedDate else { return 0 }
        return Calendar.current.dateComponents([.year], from: selectedDate, to: Date()).year ?? 0
    }

    private var maxDayInSelectedMonth: Int {
        var comps = DateComponents()
        comps.year = selectedYear
        comps.month = selectedMonth
        return Calendar.current.range(of: .day, in: .month, for: Calendar.current.date(from: comps) ?? Date())?.count ?? 31
    }

    private var primaryEnabled: Bool {
        if isSaving { return false }
        if step == .year {
            return selectedDate != nil && calculatedAge >= minimumAge
        }
        return true
    }

    private func handlePrimaryAction() {
        if step != .year {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                step = step.next
            }
            return
        }

        guard let birthDate = selectedDate, calculatedAge >= minimumAge else { return }

        Task {
            isSaving = true
            await coordinator.completeAgeGate(withBirthDate: birthDate)
            isSaving = false
        }
    }

    private func normalizeDayForMonthYear() {
        let maxDay = maxDayInSelectedMonth
        if selectedDay > maxDay {
            selectedDay = maxDay
        }
    }

    private func monthShortName(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        return formatter.shortMonthSymbols[max(1, min(12, month)) - 1]
    }
}

private enum BirthStep: Int, CaseIterable {
    case day = 0
    case month = 1
    case year = 2

    var title: String {
        switch self {
        case .day: return "Günü Seç"
        case .month: return "Ayı Seç"
        case .year: return "Yılı Seç"
        }
    }

    var caption: String {
        switch self {
        case .day: return "GÜN"
        case .month: return "AY"
        case .year: return "YIL"
        }
    }

    var majorStep: Int {
        switch self {
        case .day: return 5
        case .month: return 1
        case .year: return 5
        }
    }

    var next: BirthStep { BirthStep(rawValue: rawValue + 1) ?? .year }
    var previous: BirthStep { BirthStep(rawValue: rawValue - 1) ?? .day }

    func rangeText(for range: ClosedRange<Int>) -> String {
        LocalizedText.range(range)
    }
}

private struct StepDots: View {
    let step: BirthStep

    var body: some View {
        HStack(spacing: 8) {
            ForEach(BirthStep.allCases, id: \.rawValue) { value in
                Capsule()
                    .fill(value.rawValue <= step.rawValue ? Color.AppPrimary : Color.SurfaceBorder)
                    .frame(width: value == step ? 26 : 10, height: 7)
                    .animation(.spring(response: 0.25, dampingFraction: 0.86), value: step)
            }
        }
    }
}

private struct RulerSelector: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let displayText: (Int) -> String
    let centerCaption: String
    let rangeCaption: String
    let majorStep: Int

    @State private var currentValue: Double = 18
    @State private var dragStartValue: Double?

    private let tickSpacing: CGFloat = 14

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let midX = width / 2
            let rulerTopY: CGFloat = height * 0.58

            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(.thinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color.SurfaceBorder, lineWidth: 1)
                    )

                ForEach(range.lowerBound...range.upperBound, id: \.self) { candidate in
                    let x = midX + CGFloat(Double(candidate) - currentValue) * tickSpacing
                    if x > -16 && x < width + 16 {
                        let isMajor = candidate % max(1, majorStep) == 0
                        let lineHeight: CGFloat = isMajor ? 34 : 18

                        Capsule()
                            .fill(Color.TextSecondary.opacity(isMajor ? 0.65 : 0.35))
                            .frame(width: 2, height: lineHeight)
                            .position(x: x, y: rulerTopY)
                    }
                }

                Rectangle()
                    .fill(Color.AppPrimary)
                    .frame(width: 3, height: 52)
                    .position(x: midX, y: rulerTopY)

                Image(systemName: "triangle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.AppPrimary)
                    .rotationEffect(.degrees(180))
                    .position(x: midX, y: rulerTopY + 40)

                VStack(spacing: 3) {
                    Text(displayText(Int(currentValue.rounded())))
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(.TextPrimary)
                        .monospacedDigit()

                    Text(centerCaption)
                        .font(.caption)
                        .foregroundStyle(.TextSecondary)

                    Text(rangeCaption)
                        .font(.caption2)
                        .foregroundStyle(.TextSecondary)
                }
                .position(x: midX, y: height * 0.25)
            }
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        if dragStartValue == nil {
                            dragStartValue = currentValue
                        }
                        let delta = -Double(gesture.translation.width / tickSpacing)
                        currentValue = clamped((dragStartValue ?? currentValue) + delta)
                    }
                    .onEnded { _ in
                        dragStartValue = nil
                        let snapped = clamped(currentValue.rounded())
                        withAnimation(.interactiveSpring(response: 0.28, dampingFraction: 0.84)) {
                            currentValue = snapped
                        }
                        value = Int(snapped)
                    }
            )
            .onAppear {
                currentValue = clamped(Double(value))
            }
            .onChange(of: value) { _, newValue in
                withAnimation(.interactiveSpring(response: 0.22, dampingFraction: 0.86)) {
                    currentValue = clamped(Double(newValue))
                }
            }
        }
    }

    private func clamped(_ raw: Double) -> Double {
        min(max(raw, Double(range.lowerBound)), Double(range.upperBound))
    }
}

#Preview {
    AgeGateView(coordinator: AppCoordinator())
}
