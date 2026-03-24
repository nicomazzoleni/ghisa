import Foundation
@testable import GHISA
import SwiftData
import Testing

struct DailyLogViewModelTests {
    @Test("isToday returns true for today")
    func isTodayTrue() throws {
        let vm = try makeMockViewModel()
        vm.selectedDate = Calendar.current.startOfDay(for: Date())
        #expect(vm.isToday)
    }

    @Test("canGoForward is false when on today")
    func canGoForwardFalseToday() throws {
        let vm = try makeMockViewModel()
        vm.selectedDate = Calendar.current.startOfDay(for: Date())
        #expect(!vm.canGoForward)
    }

    @Test("canGoForward is true when on yesterday")
    func canGoForwardTrueYesterday() throws {
        let vm = try makeMockViewModel()
        vm.selectedDate = try #require(Calendar.current.date(byAdding: .day, value: -1, to: Date()))
        #expect(vm.canGoForward)
    }

    @Test("formattedDate returns Today for today")
    func formattedDateToday() throws {
        let vm = try makeMockViewModel()
        vm.selectedDate = Calendar.current.startOfDay(for: Date())
        #expect(vm.formattedDate == "Today")
    }

    @Test("formattedDate returns Yesterday for yesterday")
    func formattedDateYesterday() throws {
        let vm = try makeMockViewModel()
        vm.selectedDate = try #require(Calendar.current.date(
            byAdding: .day,
            value: -1,
            to: Calendar.current.startOfDay(for: Date())
        ))
        #expect(vm.formattedDate == "Yesterday")
    }

    @Test("formattedDate returns formatted date for older dates")
    func formattedDateOlder() throws {
        let vm = try makeMockViewModel()
        vm.selectedDate = try #require(Calendar.current.date(byAdding: .day, value: -5, to: Date()))
        #expect(vm.formattedDate != "Today")
        #expect(vm.formattedDate != "Yesterday")
    }

    @Test("goToNextDay does not advance past today")
    func goToNextDayStopsAtToday() throws {
        let vm = try makeMockViewModel()
        vm.selectedDate = Calendar.current.startOfDay(for: Date())
        vm.goToNextDay()
        #expect(vm.isToday)
    }

    @Test("goToPreviousDay moves back one day")
    func goToPreviousDayMovesBack() throws {
        let vm = try makeMockViewModel()
        let today = Calendar.current.startOfDay(for: Date())
        vm.selectedDate = today
        vm.goToPreviousDay()
        let expected = try #require(Calendar.current.date(byAdding: .day, value: -1, to: today))
        #expect(Calendar.current.isDate(vm.selectedDate, inSameDayAs: expected))
    }

    // MARK: - Helpers

    private func makeMockViewModel() throws -> DailyLogViewModel {
        let (context, user) = try TestModelContainer.makeContext()
        let dailyLogService = DailyLogService(modelContext: context)
        let healthKitService = HealthKitService()
        return DailyLogViewModel(
            dailyLogService: dailyLogService,
            healthKitService: healthKitService,
            user: user
        )
    }
}
