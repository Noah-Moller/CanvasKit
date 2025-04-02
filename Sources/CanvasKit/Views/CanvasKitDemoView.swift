import SwiftUI

@MainActor
public struct CanvasKitDemoView: View {
    @StateObject private var viewModel: CanvasKitDemoViewModel
    
    public init(client: CanvasClient) {
        _viewModel = StateObject(wrappedValue: CanvasKitDemoViewModel(client: client))
    }
    
    public var body: some View {
        NavigationView {
            List {
                Section("Courses") {
                    ForEach(viewModel.courses) { course in
                        NavigationLink(destination: CourseDetailView(course: course, viewModel: viewModel)) {
                            CourseRowView(course: course)
                        }
                    }
                }
                
                Section {
                    NavigationLink(destination: UpcomingView(viewModel: viewModel)) {
                        Label("Upcoming", systemImage: "calendar")
                    }
                }
            }
            .navigationTitle("Canvas")
            .task {
                await viewModel.loadCourses()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
}

private struct CourseRowView: View {
    let course: Course
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(course.name)
                .font(.headline)
            Text(course.courseCode)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

@MainActor
private struct CourseDetailView: View {
    let course: Course
    @ObservedObject var viewModel: CanvasKitDemoViewModel
    
    var body: some View {
        List {
            Section("Modules") {
                ForEach(viewModel.modules) { module in
                    VStack(alignment: .leading) {
                        Text(module.name)
                            .font(.headline)
                        if let items = module.items {
                            ForEach(items) { item in
                                ModuleItemView(courseId: course.id, item: item, viewModel: viewModel)
                            }
                        }
                    }
                }
            }
            
            Section("Assignments") {
                ForEach(viewModel.assignments) { assignment in
                    VStack(alignment: .leading) {
                        Text(assignment.name)
                            .font(.headline)
                        if let dueAt = assignment.dueAt {
                            Text("Due: \(dueAt, style: .date)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Section("Grades") {
                ForEach(viewModel.grades) { grade in
                    VStack(alignment: .leading) {
                        if let assignment = viewModel.assignments.first(where: { $0.id == grade.assignmentId }) {
                            Text(assignment.name)
                                .font(.headline)
                        }
                        HStack {
                            if let score = grade.score {
                                Text("Score: \(score, specifier: "%.1f")")
                                    .font(.subheadline)
                            }
                            if let gradeStr = grade.grade {
                                Text("Grade: \(gradeStr)")
                                    .font(.subheadline)
                            }
                        }
                        .foregroundColor(.secondary)
                        
                        if let comments = grade.comments, !comments.isEmpty {
                            DisclosureGroup("Comments") {
                                ForEach(comments, id: \.id) { comment in
                                    VStack(alignment: .leading) {
                                        Text(comment.authorName)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(comment.comment)
                                            .font(.body)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle(course.name)
        .task {
            await viewModel.loadModules(for: course.id)
            await viewModel.loadAssignments(for: course.id)
            await viewModel.loadGrades(for: course.id)
        }
    }
}

@MainActor
private struct ModuleItemView: View {
    let courseId: Int
    let item: ModuleItem
    @ObservedObject var viewModel: CanvasKitDemoViewModel
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("• \(item.title)")
                    .font(.subheadline)
                Spacer()
                if viewModel.loadingItemId == item.id {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isExpanded.toggle()
                if isExpanded && viewModel.moduleItemContents[item.id] == nil {
                    Task {
                        await viewModel.loadModuleItemContent(courseId: courseId, item: item)
                    }
                }
            }
            
            if isExpanded, let content = viewModel.moduleItemContents[item.id] {
                VStack(alignment: .leading, spacing: 8) {
                    if let description = content.description {
                        Text(description)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    
                    if let contentText = content.content {
                        Text(contentText)
                            .font(.body)
                    }
                    
                    if let url = content.url {
                        Link("Open in browser", destination: URL(string: url)!)
                            .font(.caption)
                    }
                }
                .padding(.leading)
                .transition(.opacity)
            }
        }
    }
}

@MainActor
private struct UpcomingView: View {
    @ObservedObject var viewModel: CanvasKitDemoViewModel
    
    var body: some View {
        List {
            if viewModel.upcomingAssignments.isEmpty {
                Text("No upcoming assignments")
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.upcomingAssignments) { assignment in
                    VStack(alignment: .leading) {
                        Text(assignment.name)
                            .font(.headline)
                        if let course = viewModel.courses.first(where: { $0.id == assignment.courseId }) {
                            Text("Course: \(course.name)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        if let dueAt = assignment.dueAt {
                            Text("Due: \(dueAt, style: .date)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        if let description = assignment.description {
                            Text(description)
                                .font(.body)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Upcoming")
        .task {
            await viewModel.loadAllAssignments()
        }
    }
}

@MainActor
class CanvasKitDemoViewModel: ObservableObject {
    private let client: CanvasClient
    
    @Published var courses: [Course] = []
    @Published var modules: [Module] = []
    @Published var assignments: [Assignment] = []
    @Published var moduleItemContents: [Int: ModuleItemContent] = [:]
    @Published var grades: [Grade] = []
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var loadingItemId: Int?
    
    var upcomingAssignments: [Assignment] {
        let now = Date()
        return assignments
            .filter { assignment in
                guard let dueAt = assignment.dueAt else { return false }
                return dueAt > now
            }
            .sorted { a, b in
                guard let aDate = a.dueAt, let bDate = b.dueAt else { return false }
                return aDate < bDate
            }
    }
    
    init(client: CanvasClient) {
        self.client = client
    }
    
    func loadCourses() async {
        do {
            courses = try await client.getCourses()
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
    }
    
    func loadModules(for courseId: Int) async {
        do {
            modules = try await client.getModules(courseId: courseId)
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
    }
    
    func loadAssignments(for courseId: Int) async {
        do {
            assignments = try await client.getAssignments(courseId: courseId)
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
    }
    
    func loadModuleItemContent(courseId: Int, item: ModuleItem) async {
        loadingItemId = item.id
        defer { loadingItemId = nil }
        
        do {
            let content = try await client.getModuleItemContent(courseId: courseId, moduleItem: item)
            moduleItemContents[item.id] = content
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
    }
    
    func loadGrades(for courseId: Int) async {
        do {
            grades = try await client.getGrades(courseId: courseId)
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
    }
    
    func loadAllAssignments() async {
        do {
            assignments.removeAll()
            for course in courses {
                let courseAssignments = try await client.getAssignments(courseId: course.id)
                assignments.append(contentsOf: courseAssignments)
            }
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
    }
} 