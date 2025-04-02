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
                ForEach(viewModel.courses) { course in
                    NavigationLink(destination: CourseDetailView(course: course, viewModel: viewModel)) {
                        CourseRowView(course: course)
                    }
                }
            }
            .navigationTitle("Canvas Courses")
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
        }
        .navigationTitle(course.name)
        .task {
            await viewModel.loadModules(for: course.id)
            await viewModel.loadAssignments(for: course.id)
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
class CanvasKitDemoViewModel: ObservableObject {
    private let client: CanvasClient
    
    @Published var courses: [Course] = []
    @Published var modules: [Module] = []
    @Published var assignments: [Assignment] = []
    @Published var moduleItemContents: [Int: ModuleItemContent] = [:]
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var loadingItemId: Int?
    
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
} 