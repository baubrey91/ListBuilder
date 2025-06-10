import XCTest
import GoogleSignIn
@testable import OptiNote

final class HomeViewModelTests: XCTestCase {
    var sut: HomeViewModel!
    var mockGIDSignIn: MockGIDSignIn!
    
    override func setUp() {
        super.setUp()
        mockGIDSignIn = MockGIDSignIn()
        sut = HomeViewModel(selectedTab: .importImageView)
    }
    
    override func tearDown() {
        sut = nil
        mockGIDSignIn = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() {
        XCTAssertEqual(sut.state, .loading)
        XCTAssertEqual(sut.selectedTab, .importImageView)
    }
    
    // MARK: - Authentication Tests
    
    func testValidateUserWhenLoggedIn() {
        // Given
        let mockUser = MockGIDGoogleUser()
        mockGIDSignIn.mockCurrentUser = mockUser
        
        // When
        sut.validateUser()
        
        // Then
        XCTAssertEqual(sut.state, .loggedIn)
    }
    
    func testValidateUserWhenLoggedOut() {
        // Given
        mockGIDSignIn.mockCurrentUser = nil
        
        // When
        sut.validateUser()
        
        // Then
        XCTAssertEqual(sut.state, .loggedOut)
    }
    
    func testGoogleSignOut() {
        // Given
        sut.state = .loggedIn
        
        // When
        sut.googleSignOut()
        
        // Then
        XCTAssertEqual(sut.state, .loggedOut)
        XCTAssertTrue(mockGIDSignIn.signOutCalled)
    }
    
    // MARK: - Tab Selection Tests
    
    func testTabSelection() {
        // Given
        let expectedTab: Tab = .googleDriveListView
        
        // When
        sut.selectedTab = expectedTab
        
        // Then
        XCTAssertEqual(sut.selectedTab, expectedTab)
    }
}

// MARK: - Mock Classes

class MockGIDSignIn: GIDSignIn {
    var mockCurrentUser: GIDGoogleUser?
    var signOutCalled = false
    
    override var currentUser: GIDGoogleUser? {
        return mockCurrentUser
    }
    
    override func signOut() {
        signOutCalled = true
    }
}

class MockGIDGoogleUser: GIDGoogleUser {
    override var accessToken: GIDAccessToken {
        return MockGIDAccessToken()
    }
}

class MockGIDAccessToken: GIDAccessToken {
    override var tokenString: String {
        return "mock_token"
    }
    
    override var expirationDate: Date {
        return Date().addingTimeInterval(3600) // 1 hour from now
    }
} 