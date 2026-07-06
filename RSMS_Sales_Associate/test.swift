import Foundation

struct Dummy: Codable {
    var name: String
}

actor TestActor {
    func test() {
        let d = Dummy(name: "a")
        let _ = try? JSONEncoder().encode(d)
    }
}
