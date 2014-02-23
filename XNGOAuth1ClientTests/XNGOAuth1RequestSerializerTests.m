#import <XCTest/XCTest.h>
#define EXP_SHORTHAND
#import <Expecta/Expecta.h>

#import "XNGOAuth1RequestSerializer.h"

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

@end
