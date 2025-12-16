import Testing
import Foundation
@testable import OPML

@Test func testFeedlyOPMLParsing() async throws {
    // Get the test bundle
    let bundle = Bundle.module
    guard let url = bundle.url(forResource: "feedly", withExtension: "opml") else {
        throw TestError.resourceNotFound("feedly.opml")
    }
    
    // Parse the OPML file
    let opml = try OPMLParser.parse(contentsOf: url)
    
    // Verify basic structure
    #expect(opml.version == "2.0")
    #expect(opml.title == "Feedly")
    #expect(opml.outlines.isEmpty == false)
    
    // Check that we have the expected number of feeds
    #expect(opml.outlines.count > 30) // The feedly.opml has many feeds
    
    // Verify some specific feeds
    let ashFurrowFeed = opml.outlines.first { $0.title == "Ash Furrow's Blog" }
    #expect(ashFurrowFeed != nil)
    #expect(ashFurrowFeed?.feedURL?.absoluteString == "https://feed.ashfurrow.com/feed.xml")
    #expect(ashFurrowFeed?.siteURL?.absoluteString == "https://ashfurrow.com")
    
    let daringFireballFeed = opml.outlines.first { $0.title == "Daring Fireball (Articles)" }
    #expect(daringFireballFeed != nil)
    #expect(daringFireballFeed?.feedURL?.absoluteString == "https://daringfireball.net/feeds/articles")
}

@Test func testRSParserOPMLParsing() async throws {
    // Get the test bundle  
    let bundle = Bundle.module
    guard let fileURL = bundle.url(forResource: "rsparser", withExtension: "opml") else {
        throw TestError.resourceNotFound("rsparser.opml")
    }
    
    // Parse the OPML file
    let parser = try OPMLParser(contentsOf: fileURL)
    let opml = try parser.parse()
    
    // Verify basic structure
    #expect(opml.version == "1.1")
    #expect(opml.outlines.isEmpty == false)
    guard let child = opml.outlines.first(where: { $0.text == "Programming" }) else {
        return
    }
    #expect(child.title == "Programming")
    #expect(child.children!.count > 30)
}

@Test func testOPMLParsingWithData() async throws {
    let xmlString = """
    <?xml version="1.0" encoding="UTF-8"?>
    <opml version="2.0">
    <head>
    <title>Test OPML</title>
    <ownerName>Test Owner</ownerName>
    <ownerEmail>test@example.com</ownerEmail>
    </head>
    <body>
        <outline type="rss" xmlUrl="https://example.com/feed.xml" title="Example Feed" text="Example Feed" htmlUrl="https://example.com" />
    </body>
    </opml>
    """
    
    let data = xmlString.data(using: .utf8)!
    let opml = try OPMLParser.parse(data: data)
    
    #expect(opml.version == "2.0")
    #expect(opml.title == "Test OPML")
    #expect(opml.ownerName == "Test Owner")
    #expect(opml.ownerEmail == "test@example.com")
    #expect(opml.outlines.count == 1)
    
    let feed = opml.outlines.first!
    #expect(feed.title == "Example Feed")
    #expect(feed.text == "Example Feed")
    #expect(feed.feedURL?.absoluteString == "https://example.com/feed.xml")
    #expect(feed.siteURL?.absoluteString == "https://example.com")
}

@Test func testOPMLToXML() async throws {
    let opml = OPML(
        title: "Feedly",
        outlines: [
            OPML.Outline(
                text: "The Confusatory",
                title: "The Confusatory",
                attributes: [
                    .init(name: "xmlUrl", value: "http://confusatory.org/rss"),
                    .init(name: "htmlUrl", value: "http://confusatory.org"),
                ]
            ),
            .init(text: "Programming", title: "Programming", children: [])
        ]
    )
    
    // Convert to XML
    let xmlString = opml.toXMLString()
    
    // Verify XML structure
    #expect(xmlString.contains("<?xml version=\"1.0\" encoding=\"UTF-8\"?>"))
    #expect(xmlString.contains("<opml version=\"2.0\">"))
    #expect(xmlString.contains("<title>Feedly</title>"))
    #expect(xmlString.contains("text=\"The Confusatory\""))
    #expect(xmlString.contains("xmlUrl=\"http://confusatory.org/rss\""))
    #expect(xmlString.contains("htmlUrl=\"http://confusatory.org\""))
    #expect(xmlString.contains("text=\"Programming\""))
    #expect(xmlString.contains("</opml>"))
    
    // Test round-trip: XML -> OPML -> XML
    guard let data = xmlString.data(using: .utf8) else {
        throw TestError.conversionFailed
    }
    
    let parsedOPML = try OPMLParser.parse(data: data)
    #expect(parsedOPML.title == opml.title)
    #expect(parsedOPML.outlines.count == opml.outlines.count)
    #expect(parsedOPML.outlines.first?.text == "The Confusatory")
    #expect(parsedOPML.outlines.first?.feedURL?.absoluteString == "http://confusatory.org/rss")
}

@Test func testOPMLToXMLWithNestedOutlines() async throws {
    let opml = OPML(
        title: "Test OPML with Nested Outlines",
        ownerName: "Test User",
        outlines: [
            OPML.Outline(
                text: "Technology",
                title: "Technology",
                children: [
                    OPML.Outline(
                        text: "Apple News",
                        title: "Apple News",
                        attributes: [
                            .init(name: "xmlUrl", value: "https://apple.com/rss"),
                            .init(name: "htmlUrl", value: "https://apple.com")
                        ]
                    ),
                    OPML.Outline(
                        text: "Swift Blog",
                        title: "Swift Blog",
                        attributes: [
                            .init(name: "xmlUrl", value: "https://swift.org/rss"),
                            .init(name: "htmlUrl", value: "https://swift.org")
                        ]
                    )
                ]
            )
        ]
    )
    
    let xmlString = opml.toXMLString()
    print("xmlString:", xmlString)
    // Verify nested structure
    #expect(xmlString.contains("<ownerName>Test User</ownerName>"))
    #expect(xmlString.contains("text=\"Technology\""))
    #expect(xmlString.contains("text=\"Apple News\""))
    #expect(xmlString.contains("text=\"Swift Blog\""))
    #expect(xmlString.contains("</outline>")) // Should have closing tags for nested elements
    
    // Test that we can parse it back
    let data = xmlString.data(using: .utf8)!
    let parsedOPML = try OPMLParser.parse(data: data)
    
    #expect(parsedOPML.title == "Test OPML with Nested Outlines")
    #expect(parsedOPML.ownerName == "Test User")
    #expect(parsedOPML.outlines.count == 1)
    
    let techCategory = parsedOPML.outlines.first!
    #expect(techCategory.text == "Technology")
    #expect(techCategory.children?.count == 2)
    
    let appleNews = techCategory.children?.first { $0.text == "Apple News" }
    #expect(appleNews?.feedURL?.absoluteString == "https://apple.com/rss")
}

@Test func testXMLEscaping() async throws {
    let opml = OPML(
        title: "Test & Special Characters <XML>",
        outlines: [
            OPML.Outline(
                text: "Feed with \"quotes\" & ampersands",
                title: "Feed with \"quotes\" & ampersands",
                attributes: [
                    .init(name: "xmlUrl", value: "https://example.com/feed?param=value&other=<test>"),
                ]
            )
        ]
    )
    
    let xmlString = opml.toXMLString()
    
    // Verify proper XML escaping
    #expect(xmlString.contains("Test &amp; Special Characters &lt;XML&gt;"))
    #expect(xmlString.contains("Feed with &quot;quotes&quot; &amp; ampersands"))
    #expect(xmlString.contains("xmlUrl=\"https://example.com/feed?param=value&amp;other=&lt;test&gt;\""))
    
    // Should be able to parse escaped XML
    let data = xmlString.data(using: .utf8)!
    let parsedOPML = try OPMLParser.parse(data: data)
    
    #expect(parsedOPML.title == "Test & Special Characters <XML>")
    #expect(parsedOPML.outlines.first?.text == "Feed with \"quotes\" & ampersands")
}

enum TestError: Error {
    case resourceNotFound(String)
    case conversionFailed
}
