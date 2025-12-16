//
//  OPMLParser.swift
//  OPML
//
//  Created by wong on 12/16/25.
//

import Foundation


public class OPMLParser: NSObject, XMLParserDelegate {
    private let xmlParser: XMLParser
    private var parsedOPML: OPML?
    
    // Parsing state
    private var currentElement: String = ""
    private var currentCharacters: String = ""
    private var currentOutline: OPML.Outline?
    private var outlineStack: [OPML.Outline] = []
    
    // Header information
    private var version: String = "2.0"
    private var title: String?
    private var dateCreated: Date?
    private var dateModified: Date?
    private var ownerName: String?
    private var ownerEmail: String?
    private var ownerID: URL?
    private var docs: URL?
    private var outlines: [OPML.Outline] = []
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        return formatter
    }()
    
    public init(contentsOf url: URL) throws {
        guard let xmlParser = XMLParser(contentsOf: url) else { 
            throw Error.unableToOpenURL(url) 
        }
        self.xmlParser = xmlParser
        super.init()
        xmlParser.delegate = self
    }
    
    public init(data: Data) throws {
        self.xmlParser = XMLParser(data: data)
        super.init()
        xmlParser.delegate = self
    }
    
    public func parse() throws -> OPML {
        guard xmlParser.parse() else {
            if let error = xmlParser.parserError {
                throw Error.parseError(error)
            } else {
                throw Error.invalidDocument
            }
        }
        
        guard let parsedOPML = parsedOPML else {
            throw Error.invalidDocument
        }
        return parsedOPML
    }
    
    // MARK: - Convenience Methods
    
    public static func parse(contentsOf url: URL) throws -> OPML {
        let parser = try OPMLParser(contentsOf: url)
        return try parser.parse()
    }
    
    public static func parse(data: Data) throws -> OPML {
        let parser = try OPMLParser(data: data)
        return try parser.parse()
    }
    
    // MARK: - XMLParserDelegate
    
    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        currentCharacters = ""
        
        switch elementName {
        case "opml":
            // Extract version from opml element
            version = attributeDict["version"] ?? "2.0"
        case "outline":
            let text = attributeDict["text"] ?? ""
            let title = attributeDict["title"] ?? attributeDict["text"] ?? ""
            
            let attributes = attributeDict.map { OPML.Attribute(name: $0.key, value: $0.value) }
            
            let outline = OPML.Outline(
                text: text,
                title: title,
                attributes: attributes.isEmpty ? nil : attributes,
                children: nil
            )
            
            if !outlineStack.isEmpty {
                // Add to parent's children (will be handled when we pop the stack)
                currentOutline = outline
            } else {
                // Top-level outline
                outlines.append(outline)
            }
            
            outlineStack.append(outline)
        default:
            break
        }
    }
    
    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentCharacters += string.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        defer { currentCharacters = "" }
        
        switch elementName {
        case "opml":
            // Create the final OPML object
            parsedOPML = OPML(
                version: version,
                title: title,
                dateCreated: dateCreated,
                dateModified: dateModified,
                ownerName: ownerName,
                ownerEmail: ownerEmail,
                ownerID: ownerID,
                docs: docs,
                outlines: outlines
            )
        case "title":
            title = currentCharacters.isEmpty ? nil : currentCharacters
        case "dateCreated":
            dateCreated = Self.dateFormatter.date(from: currentCharacters)
        case "dateModified":
            dateModified = Self.dateFormatter.date(from: currentCharacters)
        case "ownerName":
            ownerName = currentCharacters.isEmpty ? nil : currentCharacters
        case "ownerEmail":
            ownerEmail = currentCharacters.isEmpty ? nil : currentCharacters
        case "ownerId":
            ownerID = URL(string: currentCharacters)
        case "docs":
            docs = URL(string: currentCharacters)
        case "outline":
            // Handle nested outlines
            if outlineStack.count > 1 {
                let childOutline = outlineStack.removeLast()
                let parentOutline = outlineStack[outlineStack.count - 1]
                
                // Create a new parent with updated children
                var children = parentOutline.children ?? []
                children.append(childOutline)
                
                let updatedParent = OPML.Outline(
                    text: parentOutline.text,
                    title: parentOutline.title,
                    attributes: parentOutline.attributes,
                    children: children
                )
                
                // Replace the parent in the stack
                outlineStack[outlineStack.count - 1] = updatedParent
                
                // Also update in the top-level outlines if this is a top-level parent
                if outlineStack.count == 1 {
                    if let index = outlines.firstIndex(where: { $0.text == parentOutline.text && $0.title == parentOutline.title }) {
                        outlines[index] = updatedParent
                    }
                }
            } else {
                // Top-level outline - just remove from stack
                outlineStack.removeLast()
            }
        default:
            break
        }
    }
    
    public func parser(_ parser: XMLParser, parseErrorOccurred parseError: Swift.Error) {
        // Error will be handled in parse() method
    }
    
    public enum Error: LocalizedError {
        case invalidDocument
        case parseError(Swift.Error)
        case unableToOpenURL(URL)
        
        public var errorDescription: String? {
            switch self {
            case .invalidDocument: 
                return "Invalid or missing XML document"
            case .parseError(let error): 
                return "XML parsing error: \(error.localizedDescription)"
            case .unableToOpenURL(let url): 
                return "Unable to open a file at the given URL \(url)"
            }
        }
    }
}
