import Foundation
import SwiftData

@Observable
final class RoutineListViewModel {
    var templates: [WorkoutTemplate] = []
    var errorMessage: String?

    private let templateService: WorkoutTemplateService
    private let user: User

    init(templateService: WorkoutTemplateService, user: User) {
        self.templateService = templateService
        self.user = user
    }

    func loadTemplates() {
        do {
            templates = try templateService.fetchTemplates(for: user)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteTemplate(_ template: WorkoutTemplate) {
        do {
            try templateService.deleteTemplate(template)
            templates.removeAll { $0.id == template.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
