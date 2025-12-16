// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

/// https://opml.org/spec2.opml
///
public struct OPML: Codable, Equatable {
    public struct Attribute: Codable, Hashable {
        public let name: String
        public let value: String
        public init(name: String, value: String) {
            self.name = name
            self.value = value
        }
    }
    /// A node contains a set of named attributes describing an XML feed
    public struct Outline: Codable, Equatable {
        /// Some text describing the feed
        public let text: String
        public let title: String
        public let attributes: [Attribute]?
        public let children: [Outline]?
        public var siteURL: URL? {
            URL(string: attributes?.first(where: { $0.name == "htmlUrl" })?.value ?? "")
        }
        public var feedURL: URL? {
            URL(string: attributes?.first(where: { $0.name == "xmlUrl" })?.value ?? "")
        }
        public init(text: String, title: String, attributes: [Attribute]? = nil, children: [Outline]? = nil) {
            self.text = text
            self.title = title
            self.attributes = attributes
            self.children = children
        }
    }
    /// A version string, of the form, x.y, where x and y are both numeric strings.
    public let version: String
    /// The title of the subscription list
    /// `<title>` is the title of the document.
    public var title: String?
    /// `<dateCreated>` is a date-time, indicating when the document was created.
    public let dateCreated: Date?
    /// `<dateModified>` is a date-time, indicating when the document was last modified.
    public let dateModified: Date?
    /// `<ownerName>` is a string, the owner of the document.#
    public let ownerName: String?
    /// `<ownerEmail>` is a string, the email address of the owner of the document.
    public let ownerEmail: String?
    /// `<ownerId>` is the http address of a web page that contains information that allows a human reader to communicate with the author of the document via email or other means.
    /// It also may be used to identify the author. No two authors have the same ownerId.#
    public let ownerID: URL?
    /// `<docs>` is the http address of documentation for the format used in the OPML file.
    /// It's probably a pointer to this page for people who might stumble across the file on a web server 25 years from now and wonder what it is.
    public let docs: URL?
    /// A list of all the feeds contained in the list
    public var outlines: [Outline]
    public init(
        version: String = "2.0",
        title: String? = nil,
        dateCreated: Date? = Date(),
        dateModified: Date? = nil,
        ownerName: String? = nil,
        ownerEmail: String? = nil,
        ownerID: URL? = nil,
        docs: URL? = URL(string: "https://opml.org/spec2.opml"),
        outlines: [Outline] = []
    ) {
        self.version = version
        self.title = title
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.ownerName = ownerName
        self.ownerEmail = ownerEmail
        self.ownerID = ownerID
        self.docs = docs
        self.outlines = outlines
    }
}

