#import <XCTest/XCTest.h>
#define EXP_SHORTHAND
#import <Expecta/Expecta.h>
#import "XNGOAuth1RequestOperationManager.h"
#import "XNGOAuth1RequestSerializer.h"
#import "XNGOAuthToken.h"

@interface XNGOAuth1RequestSerializer ()
@property (nonatomic) NSString *service;
@property (nonatomic) NSString *consumerKey;
@property (nonatomic) NSString *consumerSecret;
@end

@interface XNGOAuth1RequestOperationManagerTests : XCTestCase

@end

@implementation XNGOAuth1RequestOperationManagerTests

- (void)testInitialization {
    XNGOAuth1RequestOperationManager *classUnderTest = [[XNGOAuth1RequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://api.xing.com"]
                                                                                                     consumerKey:@"consumerKey"
                                                                                                  consumerSecret:@"consumerSecret"];

    expect(classUnderTest.requestSerializer.service).to.equal(@"api.xing.com");
    expect(classUnderTest.requestSerializer.consumerKey).to.equal(@"consumerKey");
    expect(classUnderTest.requestSerializer.consumerSecret).to.equal(@"consumerSecret");
}

- (void)testAuthorizedWithValidExpirationDate {
    XNGOAuthToken *accessToken = [[XNGOAuthToken alloc] initWithToken:@"token"
                                                               secret:@"secret"
                                                           expiration:[NSDate dateWithTimeIntervalSinceNow:5]];
    XNGOAuth1RequestOperationManager *classUnderTest = [[XNGOAuth1RequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://api.xing.com"]
                                                                                                     consumerKey:@"consumerKey"
                                                                                                  consumerSecret:@"consumerSecret"];
    [classUnderTest.requestSerializer saveAccessToken:accessToken];

    expect(classUnderTest.isAuthorized).to.beTruthy();

    [classUnderTest.requestSerializer removeAccessToken];
}

- (void)testAuthorizedWithInvalidExpirationDate {
    XNGOAuthToken *accessToken = [[XNGOAuthToken alloc] initWithToken:@"token"
                                                               secret:@"secret"
                                                           expiration:[NSDate dateWithTimeIntervalSince1970:0]];
    XNGOAuth1RequestOperationManager *classUnderTest = [[XNGOAuth1RequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://api.xing.com"]
                                                                                                     consumerKey:@"consumerKey"
                                                                                                  consumerSecret:@"consumerSecret"];
    [classUnderTest.requestSerializer saveAccessToken:accessToken];

    expect(classUnderTest.isAuthorized).to.beFalsy();

    [classUnderTest.requestSerializer removeAccessToken];
}

- (void)testAuthorizedWithout {
    XNGOAuth1RequestOperationManager *classUnderTest = [[XNGOAuth1RequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://api.xing.com"]
                                                                                                     consumerKey:@"consumerKey"
                                                                                                  consumerSecret:@"consumerSecret"];

    expect(classUnderTest.isAuthorized).to.beFalsy();
}

- (void)testDeauthorize {
    XNGOAuthToken *accessToken = [[XNGOAuthToken alloc] initWithToken:@"token"
                                                               secret:@"secret"
                                                           expiration:[NSDate dateWithTimeIntervalSinceNow:5]];
    XNGOAuth1RequestOperationManager *classUnderTest = [[XNGOAuth1RequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://api.xing.com"]
                                                                                                     consumerKey:@"consumerKey"
                                                                                                  consumerSecret:@"consumerSecret"];
    [classUnderTest.requestSerializer saveAccessToken:accessToken];

    expect(classUnderTest.isAuthorized).to.beTruthy();

    [classUnderTest deauthorize];

    expect(classUnderTest.isAuthorized).to.beFalsy();
}

@end
