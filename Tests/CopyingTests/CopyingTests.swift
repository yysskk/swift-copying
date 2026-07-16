import Copying
import Testing

// A file-scope private type: the generated method must be callable from
// everywhere the type itself is visible, i.e. anywhere in this file.
@Copying
private struct PrivatePerson {
    let name: String
}

@Suite("Copying Tests")
struct CopyingTests {
    @Test("Generated method of a private type is callable where the type is visible")
    func privateTypeCompileTest() {
        let person = PrivatePerson(name: "John")
        let copied = person.copying(name: "Jane")

        #expect(copied.name == "Jane")
    }

    @Test("Generated code for struct compiles and works correctly")
    func structCompileTest() {
        @Copying
        struct Person {
            let name: String
            let age: Int
        }

        let person = Person(name: "John", age: 30)
        let copied = person.copying(age: 31)

        #expect(copied.name == "John")
        #expect(copied.age == 31)
    }

    @Test("Generated code for class compiles and works correctly")
    func classCompileTest() {
        @Copying
        class User {
            let id: Int
            let username: String

            init(id: Int, username: String) {
                self.id = id
                self.username = username
            }
        }

        let user = User(id: 1, username: "john")
        let copied = user.copying(username: "jane")

        #expect(copied.id == 1)
        #expect(copied.username == "jane")
    }

    @Test("Generated code for generic struct compiles and works correctly")
    func genericStructCompileTest() {
        @Copying
        struct Box<T> {
            let value: T
        }

        let intBox = Box(value: 42)
        let copiedIntBox = intBox.copying(value: 100)

        #expect(copiedIntBox.value == 100)

        let stringBox = Box(value: "hello")
        let copiedStringBox = stringBox.copying(value: "world")

        #expect(copiedStringBox.value == "world")
    }

    @Test("Generated code for generic struct with multiple parameters compiles and works correctly")
    func multipleGenericParametersCompileTest() {
        @Copying
        struct Pair<K, V> {
            let key: K
            let value: V
        }

        let pair = Pair(key: "name", value: 123)
        let copiedPair = pair.copying(value: 456)

        #expect(copiedPair.key == "name")
        #expect(copiedPair.value == 456)
    }

    @Test("Generated code for generic class compiles and works correctly")
    func genericClassCompileTest() {
        @Copying
        class Container<T> {
            let item: T

            init(item: T) {
                self.item = item
            }
        }

        let container = Container(item: "Hello")
        let copiedContainer = container.copying(item: "World")

        #expect(copiedContainer.item == "World")
    }

    @Test("Copying without arguments returns equivalent instance")
    func copyingWithoutArguments() {
        @Copying
        struct Point {
            let x: Int
            let y: Int
        }

        let point = Point(x: 10, y: 20)
        let copied = point.copying()

        #expect(copied.x == point.x)
        #expect(copied.y == point.y)
    }

    @Test("Generated code for multiple bindings in a single declaration works correctly")
    func multipleBindingsCompileTest() {
        @Copying
        struct Point {
            let x: Int, y: Int
        }

        let point = Point(x: 10, y: 20)
        let copied = point.copying(y: 99)

        #expect(copied.x == 10)
        #expect(copied.y == 99)
    }

    @Test("Generated code for multiple bindings of different types works correctly")
    func multipleBindingsOfDifferentTypesCompileTest() {
        @Copying
        struct Person {
            let name: String, age: Int
            let email: String
        }

        let person = Person(name: "John", age: 30, email: "john@example.com")
        let copied = person.copying(age: 31)

        #expect(copied.name == "John")
        #expect(copied.age == 31)
        #expect(copied.email == "john@example.com")
    }

    @Test("Generated code for struct with initialized let constants compiles and works correctly")
    func initializedLetConstantCompileTest() {
        @Copying
        struct Counter {
            let maxValue: Int = 100
            var value: Int
        }

        let counter = Counter(value: 1)
        let copied = counter.copying(value: 5)

        #expect(copied.maxValue == 100)
        #expect(copied.value == 5)
    }

    @Test("Generated code for struct with an initialized let sharing a declaration compiles and works correctly")
    func initializedLetInMixedDeclarationCompileTest() {
        @Copying
        struct Sample {
            let a: Int = 1, b: Int
        }

        let sample = Sample(b: 2)
        let copied = sample.copying(b: 3)

        #expect(copied.a == 1)
        #expect(copied.b == 3)
    }

    @Test("Generated code for struct with lazy properties compiles and works correctly")
    func lazyPropertyCompileTest() {
        @Copying
        struct DataStore {
            var name: String
            lazy var cache: [String] = ["cached"]
        }

        let store = DataStore(name: "original")
        var copied = store.copying(name: "copy")

        #expect(copied.name == "copy")
        #expect(copied.cache == ["cached"])
    }

    @Test("Copying with optional property works correctly")
    func optionalPropertyCompileTest() {
        @Copying
        struct Config {
            let name: String
            let value: Int?
        }

        let config = Config(name: "test", value: 42)
        let copiedWithNil = config.copying(value: nil)
        let copiedWithValue = config.copying(value: 100)

        #expect(copiedWithNil.value == 42)
        #expect(copiedWithValue.value == 100)
    }

    @Test("Generated code for actor compiles and works correctly")
    func actorCompileTest() async {
        @Copying
        actor Counter {
            let id: Int
            let value: Int

            init(id: Int, value: Int) {
                self.id = id
                self.value = value
            }
        }

        let counter = Counter(id: 1, value: 0)
        let copied = await counter.copying(value: 10)

        #expect(copied.id == 1)
        #expect(copied.value == 10)
    }

    @Test("Generated code for generic actor compiles and works correctly")
    func genericActorCompileTest() async {
        @Copying
        actor Storage<T: Sendable> {
            let data: T

            init(data: T) {
                self.data = data
            }
        }

        let storage = Storage(data: "Hello")
        let copied = await storage.copying(data: "World")

        #expect(copied.data == "World")
    }

    @Test("Generated code with function type property compiles and works correctly")
    func functionTypePropertyCompileTest() {
        @Copying
        struct Handler {
            let transform: (Int) -> String
            let completion: () -> Void
        }

        let handler = Handler(transform: { "value: \($0)" }, completion: {})
        let copied = handler.copying(transform: { "number: \($0)" })

        #expect(handler.transform(1) == "value: 1")
        #expect(copied.transform(1) == "number: 1")
        // The unchanged property keeps the original closure.
        #expect(handler.copying().transform(2) == "value: 2")
    }

    @Test("Generated code with existential type property compiles and works correctly")
    func existentialTypePropertyCompileTest() {
        @Copying
        struct Wrapper {
            let value: any CustomStringConvertible
        }

        let wrapper = Wrapper(value: 42)
        let copied = wrapper.copying(value: "hello")

        #expect(wrapper.value.description == "42")
        #expect(copied.value.description == "hello")
    }

    // The initializer requirement is satisfied by more shapes than an exact
    // memberwise match. These compile warning-free, proving the check does not flag
    // an initializer the generated call can actually reach.

    @Test("Generated code for a struct with its own memberwise-shaped initializer works correctly")
    func structWithHandWrittenInitializerCompileTest() {
        @Copying
        struct Temperature {
            let celsius: Double

            init(celsius: Double) {
                self.celsius = celsius
            }

            init(fahrenheit: Double) {
                self.celsius = (fahrenheit - 32) / 1.8
            }
        }

        let boiling = Temperature(fahrenheit: 212)
        let copied = boiling.copying(celsius: 0)

        #expect(boiling.celsius == 100)
        #expect(copied.celsius == 0)
    }

    @Test("Generated code for an implicitly unwrapped failable initializer works correctly")
    func implicitlyUnwrappedFailableInitializerCompileTest() {
        // `init!` returns an implicitly unwrapped optional, which converts to the type
        // itself, so the generated call type-checks and no diagnostic is warranted.
        @Copying
        class Port {
            let number: Int

            init!(number: Int) {
                guard (1...65535).contains(number) else {
                    return nil
                }
                self.number = number
            }
        }

        // Annotated because an inferred binding would widen the result back to `Port?`.
        let port: Port = Port(number: 80)
        let copied = port.copying(number: 443)

        #expect(copied.number == 443)
    }

    @Test("Generated code for an initializer with extra omittable parameters works correctly")
    func initializerWithOmittableParametersCompileTest() {
        @Copying
        class Document {
            let title: String
            let tags: [String]

            init(draft: Bool = true, title: String, revisions: Int..., tags: [String]) {
                self.title = title
                self.tags = tags
            }
        }

        let document = Document(title: "Notes", tags: ["a"])
        let copied = document.copying(title: "Final")

        #expect(copied.title == "Final")
        #expect(copied.tags == ["a"])
    }

    @Test("Generated code carries a weak reference through a copy without retaining it")
    func weakReferenceCompileTest() {
        @Copying
        final class Node {
            var name: String
            weak var next: Node?

            init(name: String, next: Node?) {
                self.name = name
                self.next = next
            }
        }

        var target: Node? = Node(name: "target", next: nil)
        let holder = Node(name: "holder", next: target)
        let copied = holder.copying(name: "holder copy")

        // The copy keeps the same referent and stays weak.
        #expect(copied.name == "holder copy")
        #expect(copied.next === target)

        // Dropping the last strong reference frees the referent, proving the copied
        // property remained `weak` rather than silently becoming a strong reference.
        target = nil
        #expect(copied.next == nil)
    }

    @Test("Generated code preserves an unowned reference through a copy")
    func unownedReferenceCompileTest() {
        final class Account {}

        @Copying
        final class Card {
            unowned var account: Account
            var number: String

            init(account: Account, number: String) {
                self.account = account
                self.number = number
            }
        }

        let account = Account()
        let card = Card(account: account, number: "1111")
        let copied = card.copying(number: "2222")

        #expect(copied.account === account)
        #expect(copied.number == "2222")
    }
}
