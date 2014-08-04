#import <XCTest/XCTest.h>
#define EXP_SHORTHAND
#import <Expecta/Expecta.h>

#import <XNGOAuth1Client/XNGOAuth1RequestSerializer.h>
#import <XNGOAuth1Client/XNGOAuth1RequestSerializer_Private.h>
#import <XNGOAuth1Client/XNGOAuthToken.h>
#import <XNGOAuth1Client/XNGOAuthToken_Private.h>

@interface XNGOAuth1RequestSerializerTests : XCTestCase

@end

@implementation XNGOAuth1RequestSerializerTests

- (void)testInitialization {
    XNGOAuth1RequestSerializer *classUnderTest = [[XNGOAuth1RequestSerializer alloc] initWithService:@"service"
                                                                                         consumerKey:@"consumerKey"
                                                                                              secret:@"consumerSecret"];
    expect(classUnderTest.service).to.equal(@"service");
    expect(classUnderTest.consumerKey).to.equal(@"consumerKey");
    expect(classUnderTest.consumerSecret).to.equal(@"consumerSecret");
}

- (void)testSavingAndRetrievingOAuthToken {
    NSDate *expirationDate = [NSDate date];
    XNGOAuthToken *token = [[XNGOAuthToken alloc] initWithToken:@"token"
                                                         secret:@"secret"
                                                     expiration:expirationDate];
    XNGOAuth1RequestSerializer *classUnderTest = [[XNGOAuth1RequestSerializer alloc] initWithService:@"service"
                                                                                         consumerKey:@"consumerKey"
                                                                                              secret:@"consumerSecret"];

    // saving
    expect([classUnderTest saveAccessToken:token]).to.beTruthy();

    // retrieving
    XNGOAuthToken *accessToken = [classUnderTest accessToken];
    expect(accessToken).toNot.beNil();
    expect(accessToken.token).to.equal(@"token");
    expect(accessToken.secret).to.equal(@"secret");
    expect(accessToken.expiration).to.equal(expirationDate);
}

- (void)testRemovingOAuthToken {
    NSDate *expirationDate = [NSDate date];
    XNGOAuthToken *token = [[XNGOAuthToken alloc] initWithToken:@"token"
                                                         secret:@"secret"
                                                     expiration:expirationDate];
    XNGOAuth1RequestSerializer *classUnderTest = [[XNGOAuth1RequestSerializer alloc] initWithService:@"service"
                                                                                         consumerKey:@"consumerKey"
                                                                                              secret:@"consumerSecret"];

    // saving
    expect([classUnderTest saveAccessToken:token]).to.beTruthy();

    // removing
    expect([classUnderTest removeAccessToken]).to.beTruthy();
}

@end
