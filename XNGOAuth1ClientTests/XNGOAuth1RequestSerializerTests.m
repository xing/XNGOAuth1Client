#import <XCTest/XCTest.h>
#define EXP_SHORTHAND
#import <Expecta/Expecta.h>

#import "XNGOAuth1RequestSerializer.h"
#import "XNGOAuthToken.h"

@interface XNGOAuthToken ()
@property (nonatomic) NSString *token;
@property (nonatomic) NSString *secret;
@property (nonatomic) NSDate *expiration;
@end

@interface XNGOAuth1RequestSerializer ()
@property (nonatomic) NSString *service;
@property (nonatomic) NSString *consumerKey;
@property (nonatomic) NSString *consumerSecret;
@end

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

@end
