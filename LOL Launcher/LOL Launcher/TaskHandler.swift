import Foundation

public class TaskHandler {
    private (set) public static var lastTask: Process? = nil
    
    private static func conditionallyDisplayInLog(_ message: String, silent: Bool = false, error: Bool = false) {
        if error {
            print(message)
        } else if !silent {
            print(message)
        }
    }
    
    public static func createTask(command: String, arguments: [String], silent isSilenced: Bool = false, returnEscaping: @escaping (String?) -> ()) {
        let task = Process()
        let errorPipe = Pipe()
        let standardPipe = Pipe()
        
        task.standardError = errorPipe
        task.standardOutput = standardPipe
        
        task.launchPath = command
        task.arguments = arguments
        
        lastTask = task
        task.terminationHandler = { (process) in
            if(process.isRunning == false) {
                let errorHandle = errorPipe.fileHandleForReading
                let errorData = errorHandle.readDataToEndOfFile()
                let taskErrorOutput = String (data: errorData, encoding: String.Encoding.utf8)
                
                let standardHandle = standardPipe.fileHandleForReading
                let standardData = standardHandle.readDataToEndOfFile()
                let taskStandardOutput = String (data: standardData, encoding: String.Encoding.utf8)
                
                if(taskErrorOutput != nil && taskErrorOutput!.count > 0) {
                    conditionallyDisplayInLog("Task \(task.launchPath ?? "") \(task.arguments.map { "\($0) " } ?? "") failed: \(taskErrorOutput ?? "No errors..") \(taskStandardOutput ?? "No standard output..")", silent: isSilenced, error: true)
                    returnEscaping("\(taskErrorOutput ?? "No errors..") \(taskStandardOutput ?? "No standard output..") ")
                } else if(taskErrorOutput != nil && taskErrorOutput!.count > 0) {
                    returnEscaping("\(taskErrorOutput ?? "No errors..") \(taskStandardOutput ?? "No standard output..") ")
                }
                
                conditionallyDisplayInLog("Task \(task.launchPath ?? "") \(task.arguments?.joined(separator: " ") ?? "") was executed", silent: isSilenced)
                returnEscaping(taskStandardOutput)
            }
        }
        
        conditionallyDisplayInLog("Task \(task.launchPath ?? "") \(task.arguments?.joined(separator: " ") ?? "") was scheduled.", silent: isSilenced)
        task.launch()
    }
    
    public static func createTask(command: String, arguments: [String], timeout: TimeInterval, silent isSilenced: Bool = false, returnEscaping: @escaping (String?) -> ()) {
        DispatchQueue.global(qos: .default).async {
            let task = Process()
            let errorPipe = Pipe()
            let standardPipe = Pipe()
            
            let standardHandle = standardPipe.fileHandleForReading
            standardHandle.waitForDataInBackgroundAndNotify()
            
            let errorHandle = errorPipe.fileHandleForReading
            errorHandle.waitForDataInBackgroundAndNotify()
            
            task.standardError = errorPipe
            task.standardOutput = standardPipe
            
            task.launchPath = command
            task.arguments = arguments
            
            conditionallyDisplayInLog("Task \(task.launchPath ?? "") \(task.arguments?.joined(separator: " ") ?? "") was scheduled with timeout \(timeout).", silent: isSilenced)
            
            var standardOutputDataListener: NSObjectProtocol!
            
            standardOutputDataListener = NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: standardHandle, queue: nil) { notification -> Void in
                let standardData = standardHandle.availableData
                if standardData.count > 0 {
                    if let outputString = String(data: standardData, encoding: String.Encoding.utf8) {
                        conditionallyDisplayInLog("Task \(task.launchPath ?? "") - \(outputString)", silent: isSilenced)
                    }
                    standardHandle.waitForDataInBackgroundAndNotify()
                } else {
                    NotificationCenter.default.removeObserver(standardOutputDataListener!)
                }
            }
            
            var errorOutputDataListener: NSObjectProtocol!
            
            errorOutputDataListener = NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: standardHandle, queue: nil) { notification -> Void in
                let errorData = errorHandle.availableData
                if errorData.count > 0 {
                    if let taskErrorOutput = String(data: errorData, encoding: String.Encoding.utf8) {
                        conditionallyDisplayInLog("Task \(task.launchPath ?? "") \(task.arguments.map { "\($0) " } ?? "") failed: \(taskErrorOutput)", silent: isSilenced, error: true)
                    }
                    errorHandle.waitForDataInBackgroundAndNotify()
                } else {
                    NotificationCenter.default.removeObserver(errorOutputDataListener!)
                }
            }
            
            var taskTerminatedListener: NSObjectProtocol!
            taskTerminatedListener = NotificationCenter.default.addObserver(forName: Process.didTerminateNotification, object: task, queue: nil) { _ -> Void in
                NotificationCenter.default.removeObserver(standardOutputDataListener!)
                NotificationCenter.default.removeObserver(errorOutputDataListener!)
                NotificationCenter.default.removeObserver(taskTerminatedListener!)
            }
            
            let taskGroup = DispatchGroup()
            task.terminationHandler = { (_) in
                taskGroup.leave()
            }
            
            lastTask = task
            taskGroup.enter()
            task.launch()
            
            let waitOutput = taskGroup.wait(timeout: DispatchTime.now() + DispatchTimeInterval.seconds(Int(timeout)))
            
            conditionallyDisplayInLog("Task \(task.launchPath ?? "") \(task.arguments?.joined(separator: " ") ?? "") wait output: \(waitOutput)", silent: isSilenced)
            
            DispatchQueue.main.sync {
                if(task.isRunning == false) {
                    let errorData = errorHandle.readDataToEndOfFile()
                    let taskErrorOutput = String (data: errorData, encoding: String.Encoding.utf8)
                    
                    let standardData = standardHandle.readDataToEndOfFile()
                    let taskStandardOutput = String (data: standardData, encoding: String.Encoding.utf8)
                    
                    if(taskErrorOutput != nil && taskErrorOutput!.count > 0) {
                        returnEscaping("\(taskErrorOutput ?? "No errors..") \(taskStandardOutput ?? "No standard output..") ")
                        return
                    }
                    
                    conditionallyDisplayInLog("Task \(task.launchPath ?? "") \(task.arguments?.joined(separator: " ") ?? "") was executed", silent: isSilenced)
                    
                    returnEscaping(taskStandardOutput)
                } else {
                    let status = kill(task.processIdentifier, Int32(15))
                    
                    conditionallyDisplayInLog("Task \(task.launchPath ?? "") \(task.arguments?.joined(separator: " ") ?? "") was killed: \(status)", silent: isSilenced)
                    
                    returnEscaping("Task \(task.launchPath ?? "") \(task.arguments?.joined(separator: " ") ?? "") was killed: \(status)")
                }
            }
        }
    }
    
    public static func createTaskWithStatus(command: String, arguments: [String]) -> Bool {
        let task = Process()
        let errorPipe = Pipe()
        let standardPipe = Pipe()
        
        task.standardError = errorPipe
        task.standardOutput = standardPipe
        
        task.launchPath = command
        task.arguments = arguments
        
        lastTask = task
        task.launch()
        task.waitUntilExit()
        
        let errorHandle = errorPipe.fileHandleForReading
        let errorData = errorHandle.readDataToEndOfFile()
        let taskErrorOutput = String (data: errorData, encoding: String.Encoding.utf8)
        
        let standardHandle = standardPipe.fileHandleForReading
        let standardData = standardHandle.readDataToEndOfFile()
        let taskStandardOutput = String (data: standardData, encoding: String.Encoding.utf8)
        
        if(taskErrorOutput != nil && taskErrorOutput!.count > 0) {
            conditionallyDisplayInLog("Task failed with: \(taskErrorOutput ?? "No errors..") \(taskStandardOutput ?? "No standard output..") ")
            return false
        }
        
        return true
    }
    
    public static func createTask(command: String, arguments: [String], callback: @escaping (String, String?) -> Void) {
        let task = Process()
        let errorPipe = Pipe()
        let standardPipe = Pipe()
        
        task.standardError = errorPipe
        task.standardOutput = standardPipe
        
        task.launchPath = command
        task.arguments = arguments
        
        lastTask = task
        task.launch()
        task.waitUntilExit()
        
        let errorHandle = errorPipe.fileHandleForReading
        let errorData = errorHandle.readDataToEndOfFile()
        let taskErrorOutput = String (data: errorData, encoding: String.Encoding.utf8)
        
        let standardHandle = standardPipe.fileHandleForReading
        let standardData = standardHandle.readDataToEndOfFile()
        let taskStandardOutput = String (data: standardData, encoding: String.Encoding.utf8)
        
        if let errorOutput = taskErrorOutput, let standardOutput = taskStandardOutput {
            if (errorOutput.count == 0) {
                callback(standardOutput, nil)
                return
            }
            callback(standardOutput, errorOutput)
            return
        }
        
        callback("No output", "No output")
    }
}
