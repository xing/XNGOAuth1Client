#import <XCTest/XCTest.h>
#import <XNGOAuth1Client/XNGOAuth1Client.h>
#import <XNGOAuth1Client/XNGOAuthToken.h>
#define EXP_SHORTHAND
#import <Expecta/Expecta.h>
#import <OHHTTPStubs/OHHTTPStubs.h>

@interface XNGOAuth1ClientTests : XCTestCase

@end

@implementation XNGOAuth1ClientTests

- (void)tearDown {
    [super tearDown];
    [OHHTTPStubs removeAllStubs];
}

- (void)testInitializer {
    NSURL *baseURL = [NSURL URLWithString:@"https://api.xing.com"];
    XNGOAuth1Client *classUnderTest = [[XNGOAuth1Client alloc] initWithBaseURL:baseURL];
    expect(classUnderTest.url).to.equal(baseURL);
    expect(classUnderTest.key).to.beNil();
    expect(classUnderTest.secret).to.beNil();
    expect(classUnderTest.signatureMethod).to.equal(AFHMACSHA1SignatureMethod);
    expect(classUnderTest.oauthAccessMethod).to.equal(@"GET");
    expect(classUnderTest.parameterEncoding).to.equal(AFFormURLParameterEncoding);
    expect(classUnderTest.stringEncoding).to.equal(NSUTF8StringEncoding);
    expect(classUnderTest.responseSerializer).to.beKindOf(AFHTTPResponseSerializer.class);
    expect(classUnderTest.defaultHeaders[@"User-Agent"]).to.equal(@"XNGOAuth1Client/1.0 (iPhone Simulator; iOS 8.1; Scale/2.00)");
    expect(classUnderTest.defaultHeaders[@"Accept-Language"]).to.equal(@"en;q=1");
}

- (void)testInitializerWithKeyAndSecret {
    NSURL *baseURL = [NSURL URLWithString:@"https://api.xing.com"];
    XNGOAuth1Client *classUnderTest = [[XNGOAuth1Client alloc] initWithBaseURL:baseURL key:@"some_key" secret:@"some_secret"];
    expect(classUnderTest.url).to.equal(baseURL);
    expect(classUnderTest.key).to.equal(@"some_key");
    expect(classUnderTest.secret).to.equal(@"some_secret");
    expect(classUnderTest.signatureMethod).to.equal(AFHMACSHA1SignatureMethod);
    expect(classUnderTest.oauthAccessMethod).to.equal(@"GET");
    expect(classUnderTest.parameterEncoding).to.equal(AFFormURLParameterEncoding);
    expect(classUnderTest.stringEncoding).to.equal(NSUTF8StringEncoding);
    expect(classUnderTest.responseSerializer).to.beKindOf(AFHTTPResponseSerializer.class);
    expect(classUnderTest.defaultHeaders[@"User-Agent"]).to.equal(@"XNGOAuth1Client/1.0 (iPhone Simulator; iOS 8.1; Scale/2.00)");
    expect(classUnderTest.defaultHeaders[@"Accept-Language"]).to.equal(@"en;q=1");
    expect(classUnderTest.key).to.equal(@"some_key");
    expect(classUnderTest.secret).to.equal(@"some_secret");
}

- (void)testAcquireOAuthRequestToken {
    NSURL *baseURL = [NSURL URLWithString:@"https://api.xing.com"];
    XNGOAuth1Client *classUnderTest = [[XNGOAuth1Client alloc] initWithBaseURL:baseURL key:@"some_key" secret:@"some_secret"];
    XCTestExpectation *expectation = [self expectationWithDescription:@"stub"];

    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.host isEqualToString:@"api.xing.com"];
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        NSData *data = [@"oauth_token=token&oauth_token_secret=somesecret&oauth_session_handle=handle&oauth_token_duration=123&oauth_token_renewable=true&user_info=info" dataUsingEncoding:NSUTF8StringEncoding];
        return [OHHTTPStubsResponse responseWithData:data
                                          statusCode:200
                                             headers:nil];
    }];

    [classUnderTest acquireOAuthRequestTokenWithPath:@"v1/request_token"
                                         callbackURL:[NSURL URLWithString:@"xingappsome_key://"]
                                        accessMethod:@"POST"
                                               scope:nil
                                             success:^(XNGOAuthToken *accessToken, id responseObject) {
                                                 expect(accessToken.key).to.equal(@"token");
                                                 expect(accessToken.secret).to.equal(@"somesecret");
                                                 expect(accessToken.session).to.equal(@"handle");
                                                 expect(accessToken.expiration).to.beLessThanOrEqualTo([NSDate dateWithTimeIntervalSinceNow:123]);
                                                 expect(accessToken.renewable).to.beTruthy();
                                                 expect(accessToken.userInfo).to.equal(@{@"user_info": @"info"});
                                                 [expectation fulfill];
                                             } failure:^(NSError *error) {
                                                 expect(error).to.beNil();
                                                 [expectation fulfill];
                                             }];
    [self waitForExpectationsWithTimeout:0.5 handler:nil];
}

@end
