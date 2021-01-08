import Foundation
import ShellOut

do {
    try CLI().run()
} catch {
    fputs("❌ \(error)", stderr)
    exit(1)
}
