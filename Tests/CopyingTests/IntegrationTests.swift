import Copying
import Testing

@Suite("Integration Tests")
struct IntegrationTests {
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
}
