#import <XCTest/XCTest.h>
#define EXP_SHORTHAND
#import <Expecta/Expecta.h>

#import <XNGOAuth1Client/XNGOAuthToken.h>
#import <XNGOAuth1Client/XNGOAuthToken_Private.h>

@interface XNGOAuthTokenTests : XCTestCase

@end

@implementation XNGOAuthTokenTests

- (void)testInitializer {
    NSDate *expirationDate = [NSDate date];
    XNGOAuthToken *classUnderTest = [[XNGOAuthToken alloc] initWithToken:@"token"
                                                                  secret:@"secret"
                                                              expiration:expirationDate];
    expect(classUnderTest.token).to.equal(@"token");
    expect(classUnderTest.secret).to.equal(@"secret");
    expect(classUnderTest.expiration).to.equal(expirationDate);

}

- (void)testExpired {
    XNGOAuthToken *classUnderTest = [[XNGOAuthToken alloc] initWithToken:@"token"
                                                                  secret:@"secret"
                                                              expiration:[NSDate dateWithTimeIntervalSince1970:0]];
    expect(classUnderTest.isExpired).to.beTruthy();
}

- (void)testExpiredWithNilExpiration {
    XNGOAuthToken *classUnderTest = [[XNGOAuthToken alloc] initWithToken:@"token"
                                                                  secret:@"secret"
                                                              expiration:nil];
    expect(classUnderTest.isExpired).to.beFalsy();
}

@end
