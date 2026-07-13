import Foundation

/// Object representation of an xcodeproj's file entry.
struct File: Hashable {
    let path: String

    /// The name portion of the file's path.
    var name: String {
        (path as NSString).pathComponents.last ?? ""
    }
    
    var nameWithoutExtension: String {
        ((path as NSString).lastPathComponent as NSString).deletingPathExtension
    }
    
    var `extension`: String {
        (path as NSString).pathExtension
    }
    
    var directory: String {
        (path as NSString).deletingLastPathComponent
    }
    
    func appendPathComponent(_ comp: String) -> File {
        return File(path: (path as NSString).appendingPathComponent(comp))
    }
    
    func appendExtension(_ ext: String) -> File? {
        guard let newPath = (path as NSString).appendingPathExtension(ext) else {
            return nil
        }
        
        return File(path: newPath)
    }

    /// Returns the disk contents of the file.
    func read() throws -> String {
        try String(contentsOfFile: path, encoding: .utf8)
    }

    /// Writes contents to the file.
    func write(contents: String) throws {
        try contents.write(toFile: path, atomically: false, encoding: .utf8)
    }
}
