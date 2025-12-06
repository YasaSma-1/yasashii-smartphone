import SwiftUI

// ======================================
// 予定（1日表示がメイン）
// ※ YasasumaEvent の struct は EventsStore.swift 側にのみ定義しておくこと！
// ======================================
struct CalendarView: View {
    // 予定データのストア
    @EnvironmentObject var eventsStore: EventsStore
    // 課金状態のストア
    @EnvironmentObject var purchaseStore: PurchaseStore

    @State private var selectedDate: Date = Date()

    @State private var showingNewEvent = false
    @State private var showingCalendarPicker = false
    @State private var showingPaywall = false   // Free で1日1件の上限に達した時に表示

    private let calendar = Calendar.current

    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()

            VStack(spacing: 24) {

                // ===== 日付ヘッダー（前日 / 当日 / 翌日） =====
                HStack {
                    // 前の日へ
                    Button {
                        moveDay(by: -1)
                    } label: {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(Color.yasasumaGreen)
                    }

                    // 日付 + 曜日（中央）＋ 下に「カレンダーから日付を選択」ボタン
                    VStack(spacing: 14) {
                        VStack(spacing: 4) {
                            Text(dateTitle(for: selectedDate))
                                .font(.system(size: 32, weight: .bold, design: .rounded))

                            Text(weekdayTitle(for: selectedDate))
                                .font(.system(size: 28, weight: .medium, design: .rounded))
                                .foregroundColor(.primary)
                        }

                        Button {
                            showingCalendarPicker = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                Text("カレンダーから日付を選択")
                            }
                            .font(.system(size: 18, weight: .semibold))
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(Color.yasasumaGreen)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)

                    // 次の日へ
                    Button {
                        moveDay(by: 1)
                    } label: {
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(Color.yasasumaGreen)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                Divider()
                    .padding(.horizontal, 16)

                // ===== この日の予定一覧（メイン） =====
                VStack(alignment: .leading, spacing: 16) {
                    Text("この日の予定")
                        .font(.system(size: 24, weight: .bold, design: .rounded))

                    let list = eventsFor(date: selectedDate)

                    if list.isEmpty {
                        Text("予定はありません。")
                            .font(.system(size: 22))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 12)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(list) { event in
                                eventRow(event)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        // 下部ツールバーに「今日」「予定を追加」
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                // 今日の日付にもどる（左）
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

                // 予定を追加（右・アクセントカラー）
                Button {
                    handleAddEventButtonTapped()     // ★ ここで課金チェック & ペイウォール
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
        // 新規予定作成画面（シート）
        .sheet(isPresented: $showingNewEvent) {
            NewEventView(
                baseDate: selectedDate
            ) { newEvent in
                handleSave(newEvent)   // ★ ここでは単純に保存のみ
            }
        }
        // カレンダーから日付選択（シート）
        .sheet(isPresented: $showingCalendarPicker) {
            CalendarPickerView(selectedDate: $selectedDate)
        }
        // Free の1日1件制限に到達したときのペイウォール
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
                .environmentObject(purchaseStore)
        }
    }

    // MARK: - 予定を追加ボタンタップ時の処理（Free = 1日1件チェック）

    private func handleAddEventButtonTapped() {
        // 有料版ならそのまま予定追加シートを開く
        if purchaseStore.isProUnlocked {
            showingNewEvent = true
            return
        }

        // Free版：選択中の日付の予定件数をチェック
        let sameDayCount = eventsStore.events.filter {
            calendar.isDate($0.date, inSameDayAs: selectedDate)
        }.count

        if sameDayCount >= 1 {
            // すでにこの日に1件登録済み → シートは開かずにペイウォール表示
            showingPaywall = true
        } else {
            // まだ0件 → 予定入力シートを開く
            showingNewEvent = true
        }
    }

    // MARK: - 予定の1行

    private func eventRow(_ event: YasasumaEvent) -> some View {
        HStack(spacing: 16) {
            Text(timeString(from: event.date))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .frame(width: 90, alignment: .leading)

            Text(event.title)
                .font(.system(size: 22, weight: .regular, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.12),
                        radius: 3,
                        x: 0,
                        y: 2)
        )
    }

    // MARK: - 日付操作

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

    // MARK: - 保存時（ここでは単純に保存だけ）

    private func handleSave(_ newEvent: YasasumaEvent) {
        // 保存対象の日付を、画面側の選択日としても反映
        selectedDate = newEvent.date

        // 課金チェックは「予定を追加」ボタン側で済ませる想定なので、
        // ここでは単純に保存のみ行う
        eventsStore.events.append(newEvent)
    }

    // MARK: - 表示用文字列

    private func dateTitle(for date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "yyyy年M月d日"
        return f.string(from: date)
    }

    private func weekdayTitle(for date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "EEEE" // 月曜日 など
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
// 新規予定作成画面（ここはそのまま）
// ======================================

struct NewEventView: View {
    let baseDate: Date
    let onSave: (YasasumaEvent) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var date: Date

    init(baseDate: Date, onSave: @escaping (YasasumaEvent) -> Void) {
        self.baseDate = baseDate
        self.onSave = onSave
        _date = State(initialValue: baseDate)
    }

    var body: some View {
        NavigationStack {
            Form {
                // 予定の内容
                Section(header: Text("予定の内容").font(.system(size: 18, weight: .semibold))) {
                    TextField("例：病院、デイサービス、買い物", text: $title)
                        .font(.system(size: 20))
                }

                // 日付と時刻（1行でまとめて、その場で変更）
                Section(header: Text("日付と時刻").font(.system(size: 18, weight: .semibold))) {
                    HStack(spacing: 12) {
                        Text("日付と時刻")
                            .font(.system(size: 18))
                        Spacer()

                        // 日付
                        DatePicker(
                            "",
                            selection: $date,
                            displayedComponents: [.date]
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .font(.system(size: 18))

                        // 時刻
                        DatePicker(
                            "",
                            selection: $date,
                            displayedComponents: [.hourAndMinute]
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .font(.system(size: 18))
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("やめる") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        save()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        // 日付・時刻ピッカーを日本語表記にする
        .environment(\.locale, Locale(identifier: "ja_JP"))
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let event = YasasumaEvent(date: date, title: trimmed)
        onSave(event)
        dismiss()
    }
}


// ======================================
// カレンダーで日付をえらぶ画面（UI変更なし）
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
                // 月ヘッダー
                HStack {
                    Button {
                        moveMonth(by: -1)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 22, weight: .bold))
                    }

                    Spacer()

                    Text(monthTitle(for: currentMonth))
                        .font(.system(size: 24, weight: .bold, design: .rounded))

                    Spacer()

                    Button {
                        moveMonth(by: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 22, weight: .bold))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // 曜日（日本語）
                HStack {
                    ForEach(["日", "月", "火", "水", "木", "金", "土"], id: \.self) { w in
                        Text(w)
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .foregroundColor(w == "日" ? .red : (w == "土" ? .blue : .primary))
                    }
                }
                .padding(.horizontal, 16)

                // 日付マス
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
                    Button("とじる") {
                        dismiss()
                    }
                }
            }
        }
        .environment(\.locale, Locale(identifier: "ja_JP"))
    }

    // 1日のセル
    private func dayCell(_ date: Date) -> some View {
        let day = calendar.component(.day, from: date)
        let isSameMonth = calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)

        return Button {
            selectedDate = date
            dismiss()
        } label: {
            Text("\(day)")
                .font(.system(size: 20))
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(
                    Group {
                        if isSelected {
                            Circle().fill(Color.yasasumaGreen)
                        } else {
                            Color.clear
                        }
                    }
                )
                .foregroundColor(
                    isSameMonth
                    ? (isSelected ? Color.white : Color.primary)
                    : Color.secondary
                )
        }
        .buttonStyle(.plain)
    }

    // 月移動
    private func moveMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
        }
    }

    // 月タイトル（日本語）
    private func monthTitle(for date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "yyyy年M月"
        return f.string(from: date)
    }

    // 月の日付配列（カレンダー用）
    private func makeDaysInMonth(for baseDate: Date) -> [Date?] {
        var result: [Date?] = []

        guard let monthStart = calendar.date(
            from: calendar.dateComponents([.year, .month], from: baseDate)
        ),
        let range = calendar.range(of: .day, in: .month, for: baseDate) else {
            return result
        }

        let weekday = calendar.component(.weekday, from: monthStart) // 1 = 日曜
        let leadingEmpty = weekday - 1

        if leadingEmpty > 0 {
            result.append(contentsOf: Array(repeating: nil, count: leadingEmpty))
        }

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                result.append(date)
            }
        }

        while result.count % 7 != 0 {
            result.append(nil)
        }

        return result
    }
}

