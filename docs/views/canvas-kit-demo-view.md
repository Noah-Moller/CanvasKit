# CanvasKitDemoView

`CanvasKitDemoView` is a SwiftUI view that provides a complete user interface for interacting with Canvas LMS. It serves as both a demonstration of CanvasKit's capabilities and a ready-to-use component for Canvas integration.

## Features

- Course listing and navigation
- Module and assignment viewing
- Grade display with comments
- Upcoming assignments view
- Error handling and loading states

## Usage

```swift
import SwiftUI
import CanvasKit

struct ContentView: View {
    let client = CanvasClient(
        domain: "your-canvas-domain.com",
        token: "your-api-token"
    )
    
    var body: some View {
        CanvasKitDemoView(client: client)
    }
}
```

## View Structure

### Main Navigation

The main view uses a `NavigationView` with a list containing:
- Courses section with course links
- Upcoming assignments section

```swift
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
}
```

### Course Detail View

Each course view shows:
- Modules with expandable items
- Assignments with due dates
- Grades with comments

```swift
List {
    Section("Modules") {
        // Module list with expandable items
    }
    
    Section("Assignments") {
        // Assignment list with due dates
    }
    
    Section("Grades") {
        // Grades with comments
    }
}
```

### Upcoming View

Shows upcoming assignments across all courses:
- Assignment name and course
- Due date
- Description (if available)

```swift
List {
    if viewModel.upcomingAssignments.isEmpty {
        Text("No upcoming assignments")
    } else {
        ForEach(viewModel.upcomingAssignments) { assignment in
            // Assignment details
        }
    }
}
```

## View Model

The `CanvasKitDemoViewModel` manages the state and data fetching:

```swift
@MainActor
class CanvasKitDemoViewModel: ObservableObject {
    @Published var courses: [Course] = []
    @Published var modules: [Module] = []
    @Published var assignments: [Assignment] = []
    @Published var grades: [Grade] = []
    @Published var showError = false
    @Published var errorMessage = ""
    
    // Computed property for upcoming assignments
    var upcomingAssignments: [Assignment] {
        // Filter and sort assignments by due date
    }
    
    // Data loading methods
    func loadCourses() async
    func loadModules(for courseId: Int) async
    func loadAssignments(for courseId: Int) async
    func loadGrades(for courseId: Int) async
    func loadAllAssignments() async
}
```

## Customization

### Styling

The view uses standard SwiftUI styling that respects the system appearance:
- System fonts and colors
- Dynamic type support
- Dark mode compatibility

### Error Handling

Errors are displayed using SwiftUI alerts:

```swift
.alert("Error", isPresented: $viewModel.showError) {
    Button("OK", role: .cancel) {}
} message: {
    Text(viewModel.errorMessage)
}
```

## Best Practices

1. **State Management**
   - Use the view model for all data operations
   - Keep views focused on presentation
   - Handle loading and error states

2. **Performance**
   - Load data only when needed
   - Use `task` modifiers for async loading
   - Cache data appropriately

3. **User Experience**
   - Show loading indicators
   - Provide clear error messages
   - Use proper navigation patterns

## Example Customization

```swift
struct CustomCanvasView: View {
    @StateObject private var viewModel: CanvasKitDemoViewModel
    
    init(client: CanvasClient) {
        _viewModel = StateObject(wrappedValue: CanvasKitDemoViewModel(client: client))
    }
    
    var body: some View {
        CanvasKitDemoView(client: viewModel.client)
            .navigationViewStyle(.stack) // iOS 15+ style
            .accentColor(.blue)
            .preferredColorScheme(.light)
    }
}
```

## See Also

- [Course Views](course-views.md) for details on course-specific views
- [Module Views](module-views.md) for module item presentation
- [Assignment Views](assignment-views.md) for assignment display 