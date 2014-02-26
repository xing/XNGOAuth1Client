#import <XCTest/XCTest.h>
#define EXP_SHORTHAND
#import <Expecta/Expecta.h>

#import "NSDictionary+XNGOAuth1Additions.h"

@interface NSDictionaryAdditionsTests : XCTestCase

@end

@implementation NSDictionaryAdditionsTests

- (void)testInitializer {
    NSString *queryString = @"param1=HELLO&param2=XING";
    NSDictionary *resultDict = [[NSDictionary alloc] xngo_initWithQueryString:queryString];

    expect(resultDict[@"param1"]).to.equal(@"HELLO");
    expect(resultDict[@"param2"]).to.equal(@"XING");
}

- (void)testClassMethod {
    NSString *queryString = @"param1=HELLO&param2=XING";
    NSDictionary *resultDict = [NSDictionary xngo_dictionaryFromQueryString:queryString];

    expect(resultDict[@"param1"]).to.equal(@"HELLO");
    expect(resultDict[@"param2"]).to.equal(@"XING");
}

- (void)testQueryStringRepresentation {
    NSDictionary *dictionary = @{
            @"param1": @"HELLO",
            @"param2": @"XING"};
    NSString *queryString = [dictionary xngo_queryStringRepresentation];
    expect(queryString).to.equal(@"param1=HELLO&param2=XING");
}

@end
