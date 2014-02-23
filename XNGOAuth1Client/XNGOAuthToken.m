#import "XNGOAuthToken.h"

@interface XNGOAuthToken ()

@property (nonatomic) NSString *token;
@property (nonatomic) NSString *secret;
@property (nonatomic) NSDate *expiration;

@end

@implementation XNGOAuthToken

- (id)initWithToken:(NSString *)token secret:(NSString *)secret expiration:(NSDate *)expiration {
    self = [super init];

    if (self) {
        _token = token;
        _secret = secret;
        _expiration = expiration;
    }

    return self;
}

- (BOOL)isExpired {
    if (!self.expiration) {
        return NO;
    }

    NSDate *now = [NSDate date];
    BOOL compareResult = [self.expiration compare:now] == NSOrderedAscending;

    return compareResult;
}

@end
