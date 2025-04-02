import Foundation

public struct Course: Codable, Identifiable, Sendable {
    public let id: Int
    public let name: String
    public let courseCode: String
    public let startAt: Date?
    public let endAt: Date?
    public let enrollmentTerm: EnrollmentTerm?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case courseCode = "course_code"
        case startAt = "start_at"
        case endAt = "end_at"
        case enrollmentTerm = "enrollment_term"
    }
}

public struct EnrollmentTerm: Codable, Identifiable, Sendable {
    public let id: Int
    public let name: String
    public let startAt: Date?
    public let endAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case startAt = "start_at"
        case endAt = "end_at"
    }
} 