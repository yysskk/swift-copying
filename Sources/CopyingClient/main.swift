import Copying

// Example with struct
@Copying
struct Person {
    let name: String
    let age: Int
    let email: String
}

// Example with class
@Copying
class User {
    let id: Int
    let username: String
    var isActive: Bool

    init(id: Int, username: String, isActive: Bool) {
        self.id = id
        self.username = username
        self.isActive = isActive
    }
}

// Usage examples
let john = Person(name: "John", age: 30, email: "john@example.com")
print("Original: \(john)")

let olderJohn = john.copying(age: 31)
print("After birthday: \(olderJohn)")

let johnNewEmail = john.copying(email: "john.doe@example.com")
print("New email: \(johnNewEmail)")

let completelyDifferent = john.copying(name: "Jane", age: 25, email: "jane@example.com")
print("All changed: \(completelyDifferent)")

// Class example
let user = User(id: 1, username: "johndoe", isActive: true)
print("\nOriginal user: id=\(user.id), username=\(user.username), isActive=\(user.isActive)")

let inactiveUser = user.copying(isActive: false)
print("Inactive user: id=\(inactiveUser.id), username=\(inactiveUser.username), isActive=\(inactiveUser.isActive)")
