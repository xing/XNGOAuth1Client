#import <XCTest/XCTest.h>
#define EXP_SHORTHAND
#import <Expecta/Expecta.h>

#import <XNGOAuth1Client/XNGOAuthToken.h>

@interface XNGOAuthTokenTests : XCTestCase

@end

@implementation XNGOAuthTokenTests

- (void)testInitializer {
    NSDate *expirationDate = [NSDate date];
    XNGOAuthToken *classUnderTest = [[XNGOAuthToken alloc] initWithKey:@"token"
                                                                secret:@"secret"
                                                               session:@"session"
                                                            expiration:expirationDate
                                                             renewable:YES];
    expect(classUnderTest.key).to.equal(@"token");
    expect(classUnderTest.secret).to.equal(@"secret");
    expect(classUnderTest.session).to.equal(@"session");
    expect(classUnderTest.expiration).to.equal(expirationDate);

}

- (void)testExpired {
    XNGOAuthToken *classUnderTest = [[XNGOAuthToken alloc] initWithKey:@"token"
                                                                secret:@"secret"
                                                               session:@"session"
                                                            expiration:[NSDate dateWithTimeIntervalSince1970:0]
                                                             renewable:YES];
    expect(classUnderTest.isExpired).to.beTruthy();
}

- (void)testExpiredWithNilExpiration {
    XNGOAuthToken *classUnderTest = [[XNGOAuthToken alloc] initWithKey:@"token"
                                                                secret:@"secret"
                                                               session:@"session"
                                                            expiration:nil
                                                             renewable:YES];
    expect(classUnderTest.isExpired).to.beFalsy();
}

- (void)testInitializerFromEmptyQueryString {
    XNGOAuthToken *classUnderTest = [[XNGOAuthToken alloc] initWithQueryString:@""];
    expect(classUnderTest).to.beNil();
}

- (void)testInitializerFromQueryString {
    NSString *queryString = @"oauth_token=token&oauth_token_secret=somesecret&oauth_session_handle=handle&oauth_token_duration=123&oauth_token_renewable=true&user_info=info";
    XNGOAuthToken *classUnderTest = [[XNGOAuthToken alloc] initWithQueryString:queryString];
    expect(classUnderTest.key).to.equal(@"token");
    expect(classUnderTest.secret).to.equal(@"somesecret");
    expect(classUnderTest.session).to.equal(@"handle");
    expect(classUnderTest.expiration).to.beLessThanOrEqualTo([NSDate dateWithTimeIntervalSinceNow:123]);
    expect(classUnderTest.renewable).to.beTruthy();
    expect(classUnderTest.userInfo).to.equal(@{@"user_info": @"info"});
}

- (void)testStoreCredential {
    NSDate *expirationDate = [NSDate dateWithTimeIntervalSinceNow:1000];
    XNGOAuthToken *classUnderTest = [[XNGOAuthToken alloc] initWithKey:@"token"
                                                                secret:@"secret"
                                                               session:@"session"
                                                            expiration:expirationDate
                                                             renewable:YES];
    BOOL success = [XNGOAuthToken storeCredential:classUnderTest withIdentifier:@"XNGOAuthToken"];
    expect(success).to.beTruthy();

    XNGOAuthToken *retrievedToken = [XNGOAuthToken retrieveCredentialWithIdentifier:@"XNGOAuthToken"];
    expect(retrievedToken.key).to.equal(@"token");
    expect(retrievedToken.secret).to.equal(@"secret");
    expect(retrievedToken.session).to.equal(@"session");
    expect(retrievedToken.expiration).to.equal(expirationDate);
}

@end
