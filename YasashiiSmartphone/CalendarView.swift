import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var eventsStore: EventsStore
    @EnvironmentObject var purchaseStore: PurchaseStore

    @State private var selectedDate: Date = Date()

    @State private var showingNewEvent = false
    @State private var showingCalendarPicker = false
    @State private var showingPaywall = false

    @State private var selectedEventID: SelectedEventID?

    private let calendar = Calendar.current

    struct SelectedEventID: Identifiable {
        let id: UUID
    }

    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()

            VStack(spacing: 24) {
                header

                Divider().padding(.horizontal, 16)

                dayEventsSection

                Spacer()
            }
        }
        .toolbar { bottomBar }
        .sheet(isPresented: $showingNewEvent) {
            NewEventView(baseDate: selectedDate) { newEvent in
                handleSave(newEvent)
            }
        }
        .sheet(isPresented: $showingCalendarPicker) {
            CalendarPickerView(selectedDate: $selectedDate)
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
                .environmentObject(purchaseStore)
        }
        .sheet(item: $selectedEventID) { item in
            EventDetailView(
                eventID: item.id,
                onUpdate: { updated in
                    // Free の「同日1件」制限を編集で迂回できないようにガード
                    if !purchaseStore.isProUnlocked {
                        let otherCount = eventsStore.events.filter { ev in
                            ev.id != updated.id && calendar.isDate(ev.date, inSameDayAs: updated.date)
                        }.count
                        if otherCount >= 1 {
                            showingPaywall = true
                            return
                        }
                    }

                    updateEvent(updated)
                    selectedDate = updated.date
                },
                onDelete: { id in
                    deleteEvent(id)
                }
            )
            .environmentObject(eventsStore)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button { moveDay(by: -1) } label: {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(Color.yasasumaGreen)
            }

            VStack(spacing: 10) {
                Text(dateTitle(for: selectedDate))
                    .font(.system(size: 32, weight: .bold, design: .rounded))

                HStack(spacing: 10) {
                    Text(weekdayTitle(for: selectedDate))
                        .font(.system(size: 28, weight: .medium, design: .rounded))
                        .foregroundColor(.primary)

                    // ✅ 文言なし、アイコンのみ。曜日の右に配置。
                    Button {
                        showingCalendarPicker = true
                    } label: {
                        Image(systemName: "calendar")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(Color.yasasumaGreen)
                            .frame(width: 44, height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.10), radius: 2, x: 0, y: 1)
                            )
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("カレンダーで日付を選ぶ")
                }
            }
            .frame(maxWidth: .infinity)

            Button { moveDay(by: 1) } label: {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(Color.yasasumaGreen)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    // MARK: - Day events section

    private var dayEventsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            let list = eventsFor(date: selectedDate)

            HStack(spacing: 12) {
                Text("この日の予定")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                Spacer()
                // ✅ ここに編集ボタンは置かない（要望）
            }

            if list.isEmpty {
                Text("予定はありません。")
                    .font(.system(size: 22))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
            } else {
                VStack(spacing: 12) {
                    ForEach(list) { event in
                        Button {
                            selectedEventID = .init(id: event.id)
                        } label: {
                            eventRow(event)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }

    private func eventRow(_ event: YasasumaEvent) -> some View {
        HStack(spacing: 16) {
            Text(timeString(from: event.date))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .frame(width: 90, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
                Text(event.title)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let memo = event.memo?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !memo.isEmpty {
                    Text(memo)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.secondary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.12), radius: 3, x: 0, y: 2)
        )
        .contentShape(Rectangle())
    }

    // MARK: - Bottom bar

    private var bottomBar: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            Button {
                selectedDate = Date()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.uturn.backward.circle")
                    Text("今日にもどる")
                }
            }
            .font(.system(size: 18, weight: .semibold))

            Spacer()

            Button {
                handleAddEventButtonTapped()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                    Text("予定を追加")
                }
            }
            .font(.system(size: 18, weight: .semibold))
            .tint(Color.yasasumaGreen)
        }
    }

    // MARK: - Add (Free = 同日1件制限)

    private func handleAddEventButtonTapped() {
        if purchaseStore.isProUnlocked {
            showingNewEvent = true
            return
        }

        let sameDayCount = eventsStore.events.filter {
            calendar.isDate($0.date, inSameDayAs: selectedDate)
        }.count

        if sameDayCount >= 1 {
            showingPaywall = true
        } else {
            showingNewEvent = true
        }
    }

    // MARK: - CRUD

    private func handleSave(_ newEvent: YasasumaEvent) {
        selectedDate = newEvent.date
        eventsStore.events.append(newEvent)

        if eventsStore.events.count >= 3 {
            ReviewRequestManager.shared.maybeRequestReview(trigger: .addedEvents)
        }
    }

    private func updateEvent(_ updated: YasasumaEvent) {
        guard let idx = eventsStore.events.firstIndex(where: { $0.id == updated.id }) else { return }
        eventsStore.events[idx] = updated
    }

    private func deleteEvent(_ id: UUID) {
        eventsStore.events.removeAll { $0.id == id }
    }

    // MARK: - Date nav / format

    private func moveDay(by value: Int) {
        if let newDate = calendar.date(byAdding: .day, value: value, to: selectedDate) {
            selectedDate = newDate
        }
    }

    private func eventsFor(date: Date) -> [YasasumaEvent] {
        eventsStore.events
            .filter { calendar.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.date < $1.date }
    }

    private func dateTitle(for date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "yyyy年M月d日"
        return f.string(from: date)
    }

    private func weekdayTitle(for date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "EEEE"
        return f.string(from: date)
    }

    private func timeString(from date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "H:mm"
        return f.string(from: date)
    }
}

// ======================================
// 予定詳細（ボタン：面全体タップ可能）
// ======================================

struct EventDetailView: View {
    @EnvironmentObject var eventsStore: EventsStore
    @Environment(\.dismiss) private var dismiss

    let eventID: UUID
    let onUpdate: (YasasumaEvent) -> Void
    let onDelete: (UUID) -> Void

    @State private var showingEdit = false
    @State private var showingDeleteConfirm = false

    private var event: YasasumaEvent? {
        eventsStore.events.first(where: { $0.id == eventID })
    }

    var body: some View {
        NavigationStack {
            Group {
                if let event {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {

                            VStack(alignment: .leading, spacing: 6) {
                                Text(dateTimeString(from: event.date))
                                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                                    .foregroundColor(.secondary)

                                Text(event.title)
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.10), radius: 3, x: 0, y: 2)
                            )

                            if let memo = event.memo,
                               !memo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("メモ")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundColor(.secondary)

                                    Text(memo)
                                        .font(.system(size: 20, weight: .regular, design: .rounded))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color.white)
                                                .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
                                        )
                                }
                            }

                            // ✅ タップ範囲最大化（面全体がタップできる）
                            VStack(spacing: 12) {
                                Button {
                                    showingEdit = true
                                } label: {
                                    HStack {
                                        Spacer(minLength: 0)
                                        Text("編集する")
                                            .font(.system(size: 20, weight: .bold, design: .rounded))
                                        Spacer(minLength: 0)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 58)
                                    .background(
                                        RoundedRectangle(cornerRadius: 18)
                                            .fill(Color.yasasumaGreen)
                                    )
                                    .foregroundColor(.white)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)

                                Button {
                                    showingDeleteConfirm = true
                                } label: {
                                    HStack {
                                        Spacer(minLength: 0)
                                        Text("削除する")
                                            .font(.system(size: 20, weight: .bold, design: .rounded))
                                        Spacer(minLength: 0)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 58)
                                    .background(
                                        RoundedRectangle(cornerRadius: 18)
                                            .fill(Color.white)
                                            .shadow(color: .black.opacity(0.10), radius: 2, x: 0, y: 1)
                                    )
                                    .foregroundColor(.red)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.top, 6)

                            Spacer(minLength: 20)
                        }
                        .padding(16)
                    }
                    .sheet(isPresented: $showingEdit) {
                        EditEventView(event: event) { updated in
                            onUpdate(updated)
                            showingEdit = false
                        }
                    }
                    .alert("この予定を削除しますか？", isPresented: $showingDeleteConfirm) {
                        Button("削除", role: .destructive) {
                            onDelete(eventID)
                            dismiss()
                        }
                        Button("キャンセル", role: .cancel) {}
                    } message: {
                        Text("\(timeString(from: event.date))  \(event.title)")
                    }
                } else {
                    VStack(spacing: 12) {
                        Text("この予定は見つかりませんでした。")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)
                        Button("閉じる") { dismiss() }
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(Color.yasasumaGreen)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("予定の詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }

    private func timeString(from date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "H:mm"
        return f.string(from: date)
    }

    private func dateTimeString(from date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "yyyy年M月d日（EEE） H:mm"
        return f.string(from: date)
    }
}

// ======================================
// 予定編集（タイトル/日時/メモ）
// ======================================

struct EditEventView: View {
    let event: YasasumaEvent
    let onSave: (YasasumaEvent) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var date: Date
    @State private var memo: String

    init(event: YasasumaEvent, onSave: @escaping (YasasumaEvent) -> Void) {
        self.event = event
        self.onSave = onSave
        _title = State(initialValue: event.title)
        _date  = State(initialValue: event.date)
        _memo  = State(initialValue: event.memo ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("予定の内容").font(.system(size: 18, weight: .semibold))) {
                    TextField("例：病院、デイサービス、買い物", text: $title)
                        .font(.system(size: 20))
                }

                Section(header: Text("日付と時刻").font(.system(size: 18, weight: .semibold))) {
                    HStack(spacing: 12) {
                        Text("日付と時刻")
                            .font(.system(size: 18))
                        Spacer()

                        DatePicker("", selection: $date, displayedComponents: [.date])
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .font(.system(size: 18))

                        DatePicker("", selection: $date, displayedComponents: [.hourAndMinute])
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .font(.system(size: 18))
                    }
                    .padding(.vertical, 4)
                }

                Section(header: Text("メモ").font(.system(size: 18, weight: .semibold))) {
                    TextEditor(text: $memo)
                        .frame(minHeight: 140)
                        .font(.system(size: 18))
                }
            }
            .navigationTitle("予定を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("やめる") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .environment(\.locale, Locale(identifier: "ja_JP"))
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let trimmedMemo = memo.trimmingCharacters(in: .whitespacesAndNewlines)
        let updated = YasasumaEvent(
            id: event.id,
            date: date,
            title: trimmedTitle,
            memo: trimmedMemo.isEmpty ? nil : trimmedMemo
        )
        onSave(updated)
        dismiss()
    }
}

// ======================================
// 新規予定作成（メモ付き）
// ======================================

struct NewEventView: View {
    let baseDate: Date
    let onSave: (YasasumaEvent) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var date: Date
    @State private var memo: String = ""

    init(baseDate: Date, onSave: @escaping (YasasumaEvent) -> Void) {
        self.baseDate = baseDate
        self.onSave = onSave
        _date = State(initialValue: baseDate)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("予定の内容").font(.system(size: 18, weight: .semibold))) {
                    TextField("例：病院、デイサービス、買い物", text: $title)
                        .font(.system(size: 20))
                }

                Section(header: Text("日付と時刻").font(.system(size: 18, weight: .semibold))) {
                    HStack(spacing: 12) {
                        Text("日付と時刻")
                            .font(.system(size: 18))
                        Spacer()

                        DatePicker("", selection: $date, displayedComponents: [.date])
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .font(.system(size: 18))

                        DatePicker("", selection: $date, displayedComponents: [.hourAndMinute])
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .font(.system(size: 18))
                    }
                    .padding(.vertical, 4)
                }

                Section(header: Text("メモ").font(.system(size: 18, weight: .semibold))) {
                    TextEditor(text: $memo)
                        .frame(minHeight: 140)
                        .font(.system(size: 18))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("やめる") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .environment(\.locale, Locale(identifier: "ja_JP"))
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let trimmedMemo = memo.trimmingCharacters(in: .whitespacesAndNewlines)

        let event = YasasumaEvent(
            date: date,
            title: trimmedTitle,
            memo: trimmedMemo.isEmpty ? nil : trimmedMemo
        )
        onSave(event)
        dismiss()
    }
}

// ======================================
// カレンダーで日付をえらぶ画面
// ======================================

struct CalendarPickerView: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss

    @State private var currentMonth: Date

    private let calendar = Calendar.current

    init(selectedDate: Binding<Date>) {
        _selectedDate = selectedDate
        _currentMonth = State(initialValue: selectedDate.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                HStack {
                    Button { moveMonth(by: -1) } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 22, weight: .bold))
                    }

                    Spacer()

                    Text(monthTitle(for: currentMonth))
                        .font(.system(size: 24, weight: .bold, design: .rounded))

                    Spacer()

                    Button { moveMonth(by: 1) } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 22, weight: .bold))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                HStack {
                    ForEach(["日", "月", "火", "水", "木", "金", "土"], id: \.self) { w in
                        Text(w)
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .foregroundColor(w == "日" ? .red : (w == "土" ? .blue : .primary))
                    }
                }
                .padding(.horizontal, 16)

                let days = makeDaysInMonth(for: currentMonth)

                VStack(spacing: 6) {
                    ForEach(0..<days.count, id: \.self) { row in
                        HStack(spacing: 4) {
                            ForEach(0..<7, id: \.self) { col in
                                let index = row * 7 + col
                                if index < days.count, let day = days[index] {
                                    dayCell(day)
                                } else {
                                    Spacer().frame(maxWidth: .infinity)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 10)

                Spacer()
            }
            .navigationTitle("日付をえらぶ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }

    private func moveMonth(by value: Int) {
        if let d = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = d
        }
    }

    private func monthTitle(for date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "yyyy年M月"
        return f.string(from: date)
    }

    private func makeDaysInMonth(for date: Date) -> [Int?] {
        guard
            let range = calendar.range(of: .day, in: .month, for: date),
            let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: date))
        else { return [] }

        let firstWeekday = calendar.component(.weekday, from: firstDay) // 1=日
        let leadingEmpty = firstWeekday - 1

        var days: [Int?] = Array(repeating: nil, count: leadingEmpty)
        days += range.map { Optional($0) }

        while days.count % 7 != 0 { days.append(nil) }
        return days
    }

    private func dayCell(_ day: Int) -> some View {
        let cellDate = makeDate(day: day, base: currentMonth)
        let isSelected = calendar.isDate(cellDate, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(cellDate)

        return Button {
            selectedDate = cellDate
            dismiss()
        } label: {
            Text("\(day)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity, minHeight: 42)
                .foregroundColor(isSelected ? .white : .primary)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.yasasumaGreen : (isToday ? Color.black.opacity(0.08) : Color.clear))
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func makeDate(day: Int, base: Date) -> Date {
        var comps = calendar.dateComponents([.year, .month], from: base)
        comps.day = day
        return calendar.date(from: comps) ?? base
    }
}

