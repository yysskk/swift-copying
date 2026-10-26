import Copying
import Testing

// Every declaration in this module without an isolation of its own is isolated to the
// main actor, as `.defaultIsolation(MainActor.self)` in Package.swift asks. A type
// therefore hands the main actor to its `copying` method unless it opts out.

@Copying
struct Profile {
    var name: String
    var age: Int
}

@Copying
nonisolated struct Point {
    var x: Double
    var y: Double
}

@Copying
nonisolated struct Badge {
    @MainActor var title: String
    var count: Int
}

@Copying
nonisolated final class Account {
    @MainActor var displayName: String
    let id: Int

    init(displayName: String, id: Int) {
        self.displayName = displayName
        self.id = id
    }
}

@Copying
actor Ledger {
    var balance: Int

    init(balance: Int) {
        self.balance = balance
    }
}

/// Copies `point` from outside the main actor, which compiles only because a
/// `nonisolated` type hands no isolation to its `copying` method.
nonisolated func movedRight(_ point: Point) -> Point {
    point.copying(x: point.x + 1)
}

/// Copies `badge` from outside the main actor. Its main-actor property leaves the
/// method nonisolated, since a value type's own methods can read such a property
/// synchronously (SE-0434).
nonisolated func incremented(_ badge: Badge) -> Badge {
    badge.copying(count: badge.count + 1)
}

@Suite("Default Isolation Tests")
struct DefaultIsolationTests {
    @Test("Generated code for a type on the main actor by default is callable on the main actor")
    func mainActorByDefaultCompileTest() {
        let profile = Profile(name: "Ada", age: 36)
        let copied = profile.copying(age: 37)

        #expect(copied.name == "Ada")
        #expect(copied.age == 37)
    }

    @Test("Generated code for a nonisolated struct is callable from any isolation")
    func nonisolatedStructCompileTest() {
        let moved = movedRight(Point(x: 1, y: 2))

        #expect(moved.x == 2)
        #expect(moved.y == 2)
    }

    @Test("Generated code for a nonisolated struct with a main-actor property is callable from any isolation")
    func nonisolatedStructWithMainActorPropertyCompileTest() {
        let badge = incremented(Badge(title: "Inbox", count: 1))

        #expect(badge.title == "Inbox")
        #expect(badge.count == 2)
    }

    @Test("Generated code for a nonisolated class with a main-actor property compiles and works correctly")
    func nonisolatedClassWithMainActorPropertyCompileTest() {
        let account = Account(displayName: "Ada", id: 1)
        let copied = account.copying(displayName: "Ada L.")

        #expect(copied.displayName == "Ada L.")
        #expect(copied.id == 1)
    }

    @Test("Generated code for an actor compiles and works correctly")
    func actorCompileTest() async {
        let ledger = Ledger(balance: 10)
        let copied = await ledger.copying(balance: 20)

        #expect(await copied.balance == 20)
    }
}
