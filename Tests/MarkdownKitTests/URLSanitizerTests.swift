import XCTest
@testable import MarkdownKit

final class URLSanitizerTests: XCTestCase {
    
    func testSafeSchemesAllowed() {
        XCTAssertEqual(URLSanitizer.sanitize("https://apple.com"), "https://apple.com")
        XCTAssertEqual(URLSanitizer.sanitize("http://example.org"), "http://example.org")
        XCTAssertEqual(URLSanitizer.sanitize("mailto:test@example.com"), "mailto:test@example.com")
        XCTAssertEqual(URLSanitizer.sanitize("tel:+1234567890"), "tel:+1234567890")
        XCTAssertEqual(URLSanitizer.sanitize("sms:12345"), "sms:12345")
    }
    
    func testRelativePathsAllowed() {
        XCTAssertEqual(URLSanitizer.sanitize("/assets/image.png"), "/assets/image.png")
        XCTAssertEqual(URLSanitizer.sanitize("page.html"), "page.html")
        XCTAssertEqual(URLSanitizer.sanitize("./local/path"), "./local/path")
        XCTAssertEqual(URLSanitizer.sanitize("../parent"), "../parent")
    }
    
    func testDangerousSchemesFiltered() {
        XCTAssertNil(URLSanitizer.sanitize("javascript:alert(1)"))
        XCTAssertNil(URLSanitizer.sanitize("vbscript:msgbox(1)"))
        XCTAssertNil(URLSanitizer.sanitize("data:text/html,<script>alert(1)</script>"))
    }
    
    func testCaseInsensitiveFiltering() {
        XCTAssertNil(URLSanitizer.sanitize("JaVaScRiPt:alert(1)"))
        XCTAssertNil(URLSanitizer.sanitize("VBSCRIPT:msgbox(1)"))
    }
    
    func testWhitespaceHandling() {
        XCTAssertEqual(URLSanitizer.sanitize("  https://apple.com  "), "https://apple.com")
        XCTAssertNil(URLSanitizer.sanitize("  javascript:alert(1)  "))
        XCTAssertNil(URLSanitizer.sanitize(" \n javascript:alert(1) \t "))
    }
    
    func testControlCharacterEvasion() {
        // Attackers sometimes insert invisible control characters to bypass raw string prefix checks.
        // `\u{0001}` is a control character that might be ignored by the browser parser but defeats `hasPrefix("javascript:")`
        XCTAssertNil(URLSanitizer.sanitize("jav\u{0001}ascript:alert(1)"))
        XCTAssertNil(URLSanitizer.sanitize("\u{0000}javascript:alert(1)"))
        XCTAssertNil(URLSanitizer.sanitize("java\u{0009}script:alert(1)")) // tab
    }
    
    func testUnknownSchemesFiltered() {
        // By default, unknown schemes like foo:// should be blocked unless allowlisted.
        XCTAssertNil(URLSanitizer.sanitize("unknown://host/path"))
        XCTAssertNil(URLSanitizer.sanitize("myapp://deep/link"))
    }
    
    func testCustomAllowlist() {
        let customAllowed: Set<String> = ["myapp", "https"]
        XCTAssertEqual(URLSanitizer.sanitize("myapp://deep/link", allowedSchemes: customAllowed), "myapp://deep/link")
        XCTAssertEqual(URLSanitizer.sanitize("https://apple.com", allowedSchemes: customAllowed), "https://apple.com")
        
        // http is NOT in our custom list now
        XCTAssertNil(URLSanitizer.sanitize("http://apple.com", allowedSchemes: customAllowed))
        // javascript is still definitely not allowed implicitly
        XCTAssertNil(URLSanitizer.sanitize("javascript:alert(1)", allowedSchemes: customAllowed))
    }
}
