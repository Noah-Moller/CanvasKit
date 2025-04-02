# Views Guide

This guide covers the SwiftUI views provided by CanvasKit for displaying Canvas LMS content.

## Core Views

### CanvasKitDemoView

The main demo view showcasing CanvasKit functionality:

```swift
struct CanvasKitDemoView: View {
    @StateObject private var viewModel: CanvasKitDemoViewModel
    
    init(client: CanvasClient = .shared) {
        _viewModel = StateObject(wrappedValue: CanvasKitDemoViewModel(client: client))
    }
    
    var body: some View {
        NavigationView {
            CourseList(viewModel: viewModel)
                .navigationTitle("Courses")
        }
    }
}
```

### CourseList

Displays a list of courses:

```swift
struct CourseList: View {
    @ObservedObject var viewModel: CourseViewModel
    
    var body: some View {
        List(viewModel.courses) { course in
            NavigationLink(destination: CourseDetail(course: course)) {
                CourseRow(course: course)
            }
        }
        .refreshable {
            await viewModel.loadCourses()
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
    }
}
```

### CourseDetail

Shows detailed course information:

```swift
struct CourseDetail: View {
    let course: Course
    @StateObject private var viewModel: CourseDetailViewModel
    
    var body: some View {
        List {
            Section("Modules") {
                ForEach(viewModel.modules) { module in
                    NavigationLink(destination: ModuleDetail(module: module)) {
                        ModuleRow(module: module)
                    }
                }
            }
            
            Section("Assignments") {
                ForEach(viewModel.assignments) { assignment in
                    NavigationLink(destination: AssignmentDetail(assignment: assignment)) {
                        AssignmentRow(assignment: assignment)
                    }
                }
            }
            
            if let grades = viewModel.grades {
                Section("Grades") {
                    ForEach(grades) { grade in
                        GradeRow(grade: grade)
                    }
                }
            }
        }
        .navigationTitle(course.name)
        .task {
            await viewModel.loadCourseContent()
        }
    }
}
```

## Supporting Views

### ModuleDetail

Displays module items and content:

```swift
struct ModuleDetail: View {
    let module: Module
    @StateObject private var viewModel: ModuleDetailViewModel
    
    var body: some View {
        List {
            if let items = module.items {
                ForEach(items) { item in
                    NavigationLink(destination: ModuleItemDetail(item: item)) {
                        ModuleItemRow(item: item)
                    }
                }
            }
        }
        .navigationTitle(module.name)
    }
}
```

### AssignmentDetail

Shows assignment details and submission options:

```swift
struct AssignmentDetail: View {
    let assignment: Assignment
    @StateObject private var viewModel: AssignmentDetailViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let description = assignment.htmlDescription {
                    Text(.init(description))
                }
                
                if let dueAt = assignment.dueAt {
                    Label("Due \(dueAt.formatted())", systemImage: "calendar")
                }
                
                if let points = assignment.pointsPossible {
                    Label("\(points) points", systemImage: "star")
                }
            }
            .padding()
        }
        .navigationTitle(assignment.name)
    }
}
```

### GradeRow

Displays grade information:

```swift
struct GradeRow: View {
    let grade: Grade
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(grade.assignmentName)
                .font(.headline)
            
            if let score = grade.score {
                Text("Score: \(score)")
                    .foregroundColor(.secondary)
            }
            
            if let comments = grade.comments, !comments.isEmpty {
                Text("Comments: \(comments.count)")
                    .foregroundColor(.secondary)
            }
        }
    }
}
```

## View Models

### CanvasKitDemoViewModel

Manages the main demo view state:

```swift
class CanvasKitDemoViewModel: ObservableObject {
    @Published private(set) var courses: [Course] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    
    private let client: CanvasClient
    
    init(client: CanvasClient) {
        self.client = client
    }
    
    @MainActor
    func loadCourses() async {
        isLoading = true
        do {
            courses = try await client.getCourses()
        } catch {
            self.error = error
        }
        isLoading = false
    }
}
```

### CourseDetailViewModel

Manages course detail view state:

```swift
class CourseDetailViewModel: ObservableObject {
    @Published private(set) var modules: [Module] = []
    @Published private(set) var assignments: [Assignment] = []
    @Published private(set) var grades: [Grade]?
    @Published private(set) var error: Error?
    
    private let client: CanvasClient
    private let courseId: Int
    
    init(client: CanvasClient, courseId: Int) {
        self.client = client
        self.courseId = courseId
    }
    
    @MainActor
    func loadCourseContent() async {
        async let modulesTask = client.getModules(courseId: courseId)
        async let assignmentsTask = client.getAssignments(courseId: courseId)
        async let gradesTask = client.getGrades(courseId: courseId)
        
        do {
            let (modules, assignments, grades) = try await (modulesTask, assignmentsTask, gradesTask)
            self.modules = modules
            self.assignments = assignments
            self.grades = grades
        } catch {
            self.error = error
        }
    }
}
```

## Customization

### Styling

Apply custom styles to views:

```swift
extension CourseRow {
    func courseStyle() -> some View {
        self
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(radius: 2)
    }
}

struct CourseRow: View {
    let course: Course
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(course.name)
                .font(.headline)
            Text(course.courseCode)
                .foregroundColor(.secondary)
        }
        .courseStyle()
    }
}
```

### Error Views

Custom error handling views:

```swift
struct ErrorView: View {
    let error: Error
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Error")
                .font(.headline)
            Text(error.localizedDescription)
                .multilineTextAlignment(.center)
            Button("Retry") {
                retryAction()
            }
        }
        .padding()
    }
}
```

### Loading Views

Custom loading indicators:

```swift
struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
            Text("Loading...")
                .foregroundColor(.secondary)
        }
    }
}
```

## Best Practices

1. **State Management**
   - Use `@StateObject` for view models
   - Use `@Published` for observable properties
   - Handle loading and error states

2. **Navigation**
   - Use `NavigationView` for hierarchical content
   - Implement proper back navigation
   - Handle deep linking

3. **Performance**
   - Implement lazy loading
   - Cache network responses
   - Use `AsyncImage` for remote images

4. **Accessibility**
   - Add accessibility labels
   - Support dynamic type
   - Test with VoiceOver

5. **Error Handling**
   - Show user-friendly error messages
   - Provide retry options
   - Handle offline state

## See Also

- [Client API Reference](client-api.md)
- [Models Documentation](models.md)
- [Best Practices](advanced/best-practices.md) 