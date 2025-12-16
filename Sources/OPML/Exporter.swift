//
//  Exporter.swift
//  OPML
//
//  Created by wong on 12/16/25.
//

import Foundation

public extension OPML {
    // MARK: - XML Export
    
    /// Converts the OPML object to XML string representation
    /// - Returns: A formatted XML string representing the OPML document
    func toXMLString() -> String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        xml += "<opml version=\"\(version)\">\n"
        xml += "  <head>\n"
        // Add head elements
        if let title = title {
            xml += "    <title>\(xmlEscaped(title))</title>\n"
        }
        
        if let dateCreated = dateCreated {
            xml += "    <dateCreated>\(dateFormatter.string(from: dateCreated))</dateCreated>\n"
        }
        
        if let dateModified = dateModified {
            xml += "    <dateModified>\(dateFormatter.string(from: dateModified))</dateModified>\n"
        }
        
        if let ownerName = ownerName {
            xml += "    <ownerName>\(xmlEscaped(ownerName))</ownerName>\n"
        }
        
        if let ownerEmail = ownerEmail {
            xml += "    <ownerEmail>\(xmlEscaped(ownerEmail))</ownerEmail>\n"
        }
        
        if let ownerID = ownerID {
            xml += "    <ownerId>\(xmlEscaped(ownerID.absoluteString))</ownerId>\n"
        }
        
        if let docs = docs {
            xml += "    <docs>\(xmlEscaped(docs.absoluteString))</docs>\n"
        }
        xml += "  </head>\n"
        xml += "  <body>\n"
        // Add outlines
        for outline in outlines {
            xml += outlineToXML(outline, indentLevel: 2)
        }
        xml += "  </body>\n"
        xml += "</opml>\n"
        
        return xml
    }
    
    /// Converts an outline to XML representation
    /// - Parameters:
    ///   - outline: The outline to convert
    ///   - indentLevel: The current indentation level
    /// - Returns: XML string representation of the outline
    private func outlineToXML(_ outline: Outline, indentLevel: Int) -> String {
        let indent = String(repeating: " ", count: indentLevel)
        var xml = "\(indent)<outline"
        
        // Add text attribute
        xml += " text=\"\(xmlEscaped(outline.text))\""
        
        // Add title attribute if different from text
        xml += " title=\"\(xmlEscaped(outline.title))\""
        
        // Add other attributes
        if let attributes = outline.attributes {
            for attribute in attributes {
                xml += " \(attribute.name)=\"\(xmlEscaped(attribute.value))\""
            }
        }
        
        // Check if outline has children
        if let children = outline.children, !children.isEmpty {
            xml += ">\n"
            
            // Add children
            for child in children {
                xml += outlineToXML(child, indentLevel: indentLevel + 2)
            }
            
            xml += "\(indent)</outline>\n"
        } else {
            xml += " />\n"
        }
        
        return xml
    }
    
    /// Escapes special XML characters in a string
    /// - Parameter string: The string to escape
    /// - Returns: The escaped string
    private func xmlEscaped(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
    
    /// Date formatter for OPML date fields
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }
}
