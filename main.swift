//
//  main.swift
//  To-Do
//
//  Created by Dillon Teakell on 9/21/24.
//

import Foundation

struct Todo: Identifiable, Codable, Equatable, CustomStringConvertible {
    var description: String
    var id = UUID()
    var title: String
    var isCompleted: Bool
}

protocol Cache {
    // Saves the tasks
    func save(todos: [Todo]) -> Bool
    
    // Loads the tasks if there are any, but returns nil if empty
    func load() ->[Todo]?
}

// Caching system to persist data using FileManager
// With guidance from Paul Hudson: https://www.hackingwithswift.com/books/ios-swiftui/writing-data-to-the-documents-directory
final class JSONFileManagerCache: Cache {
    
    private let fileURL: URL
    private let fileManager = FileManager.default
    
    // When initialized, the file manager will attempt to locate the file
    init() {
        // Locate file and set it to the fileURL
        if let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            fileURL = documentDirectory.appendingPathComponent("todos.json")
        } else {
            fatalError("Could not find document directory")
        }
    }
    
    
    func save(todos: [Todo]) -> Bool {
        
        // Do - catch block to handle any errors
        do {
            // Encode the data to JSON
            let jsonData = try? JSONEncoder().encode(todos)
            // Attempt to write to the file
            try jsonData?.write(to: fileURL, options: .atomic)
            print("Tasks successfully saved!")
            return true
        } catch {
            print("An error occurred when writing: \(error.localizedDescription)")
            return false
        }
    }
    
    func load() -> [Todo]? {
        do {
            let data = try Data(contentsOf: fileURL)
            let todos = try JSONDecoder().decode([Todo].self, from: data)
            return todos
        } catch {
            print("Failed to load tasks: \(error.localizedDescription)")
            return nil
        }
    }
    
    
    // First-time setup function
    func firstTimeSetup() {
        
        // Check if the file exists
        print("Checking for file...")
        
        // File exists - Do nothing
        if fileManager.fileExists(atPath: fileURL.path()) == true {
            print("File Exists. Proceeding...")
        } else {
            // File doesn't exist - create initial data and file
            let initialData: [String] = []
            
            // Encodes the initial data and stores it in the file
            do {
                let jsonData = try JSONEncoder().encode(initialData)
                try jsonData.write(to: fileURL)
                print("First-time setup complete! File has been created")
            } catch {
                print("Failed to write data. \(error)")
            }
        }
    }
}

// Caching system to persist data in memory
final class InMemoryCache: Cache {
    
    // Create an empty array to store todos
    private var todos: [Todo] = []
    
    func save(todos: [Todo]) -> Bool {
        if self.todos == todos {
            print("Todos saved to memory")
            return true
        } else {
            print("Todos unable to be saved")
            return false
        }
    }

    func load() -> [Todo]? {
        if todos.isEmpty {
            print("No todos in memory")
        }
        return todos
    }
}

// Class to manage tasks
final class TodosManager {
    
    // Create todo list automatically
    private let cache: Cache
    var todoList: [Todo] = []
    
    // The initializer will create a cache and load data from the cache using the function 'loadFromCache'
    init(cache: Cache) {
        self.cache = cache
        loadFromCache()
    }
    
    // Loads data from the cache
    private func loadFromCache() {
        if let todos = cache.load() {
            todoList = todos
        } else {
            print("No todos in memory or in file")
        }
    }
    
    // Method to add todo
    func addTodo(title: String, description: String) -> Todo {
        let newTodo = Todo(description: description, title: title, isCompleted: false)
        
        todoList.append(newTodo)
        return newTodo
    }
    
    // Method to remove todo
    func removeTodo(at index: Int) -> Todo {
        let todoToRemove = todoList.remove(at: index)
        return todoToRemove
    }
    
    // Method to view a particular todo and get the description
    func getTodoInformation(forTodo index: Int) -> Todo {
        let selectedTodo = todoList[index]
        print("Title - \(selectedTodo.title)")
        print("Description - \(selectedTodo.description)")
        print(selectedTodo.isCompleted ? "Status - ✅ Complete" : "Status - ❌ Incomplete")
        return selectedTodo
        
    }
    
    // Method to view all todos
    func listTodos() {
        for (index, todo) in todoList.enumerated() {
            print(
                todo.isCompleted ? "\(index + 1) - \(todo.title) - ✅ Complete" : "\(index + 1) - \(todo.title) - ❌ Not Complete"
            )
        }
        
        if todoList.isEmpty {
            print("No todos in list.\n")
        }
    }
    
    // Method to toggle completion status
    func toggleStatus(forTodo index: Int) -> Todo {
        todoList[index].isCompleted.toggle()
        return todoList[index]
    }
    
}


final class App {
    
    // Enum for commands to use while the app is running
    enum Command: String {
        case add = "add"
        case remove = "remove"
        case view = "view"
        case complete = "complete"
        case exit = "exit"
    }
    
    
    // Print a welcome message to the console
    func displayWelcomeMessage() {
        print("Welcome!\n")
    }
    
    
    // Create a cache and todoManager to initialize later
    let cache = JSONFileManagerCache()
    let todoManager: TodosManager
    
    
    // Creates a todoManager every time the class is initialized
    init() {
        self.todoManager = TodosManager(cache: cache)
    }
    
    
    // Get user input
    func getUserInput() {
        
        // Create boolean to control while loop
        var isExitEntered: Bool = false
        
        // Show menu until exit is entered
        while isExitEntered == false {
            
            // Display menu
            viewTodos()
            print("Please select an option (add, remove, view, complete, exit): ")
            
            // User input
            if let input = readLine(), let command = Command(rawValue: input) {
                handleCommand(command: command.rawValue)
            } else {
                print("Input invalid. Please try again.")
            }
        }
        
        // Function to handle command
        func handleCommand(command: String) {
            switch command {
            case Command.add.rawValue:
                addTodo()
                
            case Command.remove.rawValue:
                removeTodo()
                
            case Command.view.rawValue:
                viewTodoDetails()
                
            case Command.complete.rawValue:
                toggleTodoStatus()
                
            case Command.exit.rawValue:
                isExitEntered.toggle()
                
            default:
                print("Command Unknown. Please try again.")
            }
        }
        
        
        
        // Add Todo
        func addTodo() {
            // Get title
            print("Please enter a title: ")
            if let title = readLine() {
                
                // Get description
                print("Please enter a description: ")
                if let description = readLine() {
                    
                    // Add task
                    let todo = todoManager.addTodo(
                        title: title,
                        description: description
                    )
                    _ = cache.save(todos: todoManager.todoList)
                    
                    print("'\(todo.title)' has been added!\n")
                    
                    
                    // Invalid Description
                } else {
                    print("Description Invalid. Please try again")
                }
                
                // Invalid Title
            } else {
                print("Title Invalid. Please try again.")
            }
        }
        
        // Remove Todo
        func removeTodo() {
            
            if todoManager.todoList.isEmpty {
                print("No todos in list. Returning to menu...\n")
                getUserInput()
                
            } else {
                print("Please select a todo you'd like to remove\n")
                viewTodos()
                
                print("Enter todo number below: ")
                
                // Get user input from readLine, convert to an integer, and then check if it's greater or equal to zero and less than the task list count
                guard let input = readLine(), let indexToRemove = Int(input), indexToRemove > 0, indexToRemove <= todoManager.todoList.count else {
                    print("Input invalid. Please enter a valid task index.")
                    return
                }
                
                let adjustedIndex = indexToRemove - 1
                
                let todoToRemove = todoManager.removeTodo(at: adjustedIndex)
                _ = cache.save(todos: todoManager.todoList)
                print("\(todoToRemove.title) has been removed!\n")
            }
        }
        
        // View Todos
        func viewTodos() {
            todoManager.listTodos()
        }
        
        // View Specific Todo Details
        func viewTodoDetails() {
            
            if todoManager.todoList.isEmpty {
                print("No todos in list. Returning to menu...\n")
                getUserInput()
            } else {
                print("Which todo would you like more information of?")
                viewTodos()
                
                print("Enter todo number below:")
                
                guard let input = readLine(), let indexToView = Int(
                    input
                ), indexToView > 0, indexToView <= todoManager.todoList.count else {
                    print("Input invalid. Please enter a valid todo index.")
                    return
                }
                
                let adjustedIndex = indexToView - 1
                
                _ = todoManager.getTodoInformation(forTodo: adjustedIndex)
            }
        }
        
        // Complete Todo
        func toggleTodoStatus() {
            
            if todoManager.todoList.isEmpty {
                print("No todos in list. Returning to menu...\n")
                getUserInput()
            } else {
                print("Which todo would you like to toggle?\n")
                viewTodos()
                
                print("Enter todo number below:")
                guard let input = readLine(), let indexToToggle = Int(input), indexToToggle > 0, indexToToggle <= todoManager.todoList.count else {
                    print("Input invalid. Please enter a valid todo index.")
                    return
                }
                
                // Adjust index to match zero-index
                let adjustedIndex = indexToToggle - 1
                
                let toggledTodo = todoManager.toggleStatus(forTodo: adjustedIndex)
                _ = cache.save(todos: todoManager.todoList)
                print(toggledTodo.isCompleted ? "'\(toggledTodo.title)' has been completed! Good job!\n" : "'\(toggledTodo.title)' is incomplete.\n")
            }
        }
    }
    
    
    func run() {
        cache.firstTimeSetup()
        displayWelcomeMessage()
        getUserInput()
    }
}

let app = App()

app.run()
