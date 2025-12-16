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

    // ★ 削除機能用
    @State private var isEditing = false
    @State private var pendingDeleteEvent: YasasumaEvent? = nil

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

                    let list = eventsFor(date: selectedDate)

                    HStack(spacing: 12) {
                        Text("この日の予定")
                            .font(.system(size: 24, weight: .bold, design: .rounded))

                        Spacer()

                        // ★ 予定があるときだけ編集ボタンを出す（通常時はUIを増やさない）
                        if !list.isEmpty {
                            Button {
                                isEditing.toggle()
                            } label: {
                                Text(isEditing ? "完了" : "編集")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(Color.yasasumaGreen)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color.white)
                                            .shadow(color: .black.opacity(0.10),
                                                    radius: 2,
                                                    x: 0,
                                                    y: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if isEditing && !list.isEmpty {
                        Text("消したい予定のゴミ箱を押してください。")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)
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
                    // 今日に戻ったら編集モードは解除（事故防止）
                    isEditing = false
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
        // ★ 削除確認アラート
        .alert(item: $pendingDeleteEvent) { event in
            Alert(
                title: Text("この予定を削除しますか？"),
                message: Text("\(timeString(from: event.date))  \(event.title)"),
                primaryButton: .destructive(Text("削除")) {
                    deleteEvent(event)
                },
                secondaryButton: .cancel(Text("キャンセル"))
            )
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

    // MARK: - 予定の1行（★編集モード時のみ削除ボタン表示）

    private func eventRow(_ event: YasasumaEvent) -> some View {
        HStack(spacing: 16) {
            Text(timeString(from: event.date))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .frame(width: 90, alignment: .leading)

            Text(event.title)
                .font(.system(size: 22, weight: .regular, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .leading)

            if isEditing {
                Button {
                    pendingDeleteEvent = event
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: "trash.circle.fill")
                            .font(.system(size: 30))
                        Text("削除")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.red)
                    .frame(width: 62)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            }
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

    // MARK: - 削除

    private func deleteEvent(_ event: YasasumaEvent) {
        eventsStore.events.removeAll { $0.id == event.id }

        // その日の予定が空になったら、編集モードも自動解除（事故防止）
        if eventsFor(date: selectedDate).isEmpty {
            isEditing = false
        }
    }

    // MARK: - 日付操作

    private func moveDay(by value: Int) {
        if let newDate = calendar.date(byAdding: .day, value: value, to: selectedDate) {
            selectedDate = newDate
            // 日付移動したら編集モード解除（事故防止）
            isEditing = false
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
        if eventsStore.events.count >= 3 {
            ReviewRequestManager.shared.maybeRequestReview(trigger: .addedEvents)
        }
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
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - 月移動

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

    // MARK: - 日付配列（週×7）

    private func makeDaysInMonth(for month: Date) -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: month),
              let first = calendar.date(from: calendar.dateComponents([.year, .month], from: month))
        else { return [] }

        let firstWeekday = calendar.component(.weekday, from: first) // 1=日
        let leadingBlank = (firstWeekday - 1 + 7) % 7

        var days: [Date?] = Array(repeating: nil, count: leadingBlank)

        for day in range {
            if let d = calendar.date(byAdding: .day, value: day - 1, to: first) {
                days.append(d)
            }
        }

        while days.count % 7 != 0 {
            days.append(nil)
        }

        return days
    }

    // MARK: - 日セル

    private func dayCell(_ date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let day = calendar.component(.day, from: date)

        return Button {
            selectedDate = date
            dismiss()
        } label: {
            Text("\(day)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.yasasumaGreen.opacity(0.22) : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }
}

