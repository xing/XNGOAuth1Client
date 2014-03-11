#import <XCTest/XCTest.h>
#define EXP_SHORTHAND
#import <Expecta/Expecta.h>
#import "XNGOAuth1RequestOperationManager.h"
#import <XNGOAuth1Client/XNGOAuthToken.h>
#import "OHHTTPStubs.h"

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

- (void)testAuthorizeUsingOAuthWithRequestTokenPath {
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        NSURL *url = [NSURL URLWithString:@"https://www.xing.com/v1/request_token"];
        NSString *parameterString = [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding];
        if ([request.URL isEqual:url] &&
             [parameterString isEqualToString:@"oauth_callback=xingapp%3A%2F%2Fauthorize"]) {
            return YES;
        }

        XCTAssert(NO, @"Wrong URL");
        return NO;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        NSString *responseString = @"oauth_token=1234&oauth_token_secret=456&oauth_verifier=verifier";
        NSData *returnData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
        return [OHHTTPStubsResponse responseWithData:returnData statusCode:200 headers:nil];
    }];

    XNGOAuth1RequestOperationManager *classUnderTest = [[XNGOAuth1RequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://www.xing.com"]
                                                                                                     consumerKey:@"consumerKey"
                                                                                                  consumerSecret:@"consumerSecret"];
    [classUnderTest authorizeUsingOAuthWithRequestTokenPath:@"v1/request_token"
                                      userAuthorizationPath:@"v1/authorize"
                                                callbackURL:[NSURL URLWithString:@"xingapp://authorize"]
                                            accessTokenPath:@"v1/access_token"
                                               accessMethod:@"POST"
                                                      scope:nil
                                                    success:^(XNGOAuthToken *oAuthToken, id responseObject) {
                                                                expect(oAuthToken).toNot.beNil();
                                                                expect(oAuthToken.token).to.equal(@"1234");
                                                                expect(oAuthToken.secret).to.equal(@"456");
                                                                expect(oAuthToken.verifier).to.equal(@"verifier");
                                                            }
                                                    failure:^(NSError *error) {
                                                                XCTAssert(NO, @"SHOULD NOT HAPPEN");
                                                            }];

    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
}

- (void)testAcquireOAuthRequestTokenWithPath {
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        NSURL *url = [NSURL URLWithString:@"https://www.xing.com/v1/request_token"];
        NSString *parameterString = [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding];
        if ([request.URL isEqual:url] &&
                [parameterString isEqualToString:@"oauth_token=token&oauth_verifier=verifier"]) {
            return YES;
        }

        XCTAssert(NO, @"Wrong URL");
        return NO;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        NSString *responseString = @"oauth_token=1234&oauth_token_secret=456&oauth_verifier=verifier";
        NSData *returnData = [responseString dataUsingEncoding:NSUTF8StringEncoding];
        return [OHHTTPStubsResponse responseWithData:returnData statusCode:200 headers:nil];
    }];


    XNGOAuthToken *token = [[XNGOAuthToken alloc] initWithToken:@"token" secret:@"secret" expiration:nil];
    [token setValue:@"verifier" forKeyPath:@"verifier"];
    XNGOAuth1RequestOperationManager *classUnderTest = [[XNGOAuth1RequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://www.xing.com"]
                                                                                                     consumerKey:@"consumerKey"
                                                                                                  consumerSecret:@"consumerSecret"];

    [classUnderTest acquireOAuthRequestTokenWithPath:@"v1/request_token"
                                         callbackURL:[NSURL URLWithString:@"xingapp://authorize"]
                                        accessMethod:@"POST"
                                        requestToken:token
                                               scope:nil
                                             success:^(XNGOAuthToken *requestToken, id responseObject) {
                                                 expect(requestToken).toNot.beNil();
                                                 expect(requestToken.token).to.equal(@"1234");
                                                 expect(requestToken.secret).to.equal(@"456");
                                                 expect(requestToken.verifier).to.equal(@"verifier");
                                             }
                                             failure:^(NSError *error) {
                                                 XCTAssert(NO, @"SHOULD NOT HAPPEN");
                                             }];

    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
}

@end
