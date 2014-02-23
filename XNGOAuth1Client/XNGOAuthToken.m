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

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];

    if (self) {
        _token = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(token))];
        _secret = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(secret))];
        _expiration = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(expiration))];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.token forKey:NSStringFromSelector(@selector(token))];
    [aCoder encodeObject:self.secret forKey:NSStringFromSelector(@selector(secret))];
    [aCoder encodeObject:self.expiration forKey:NSStringFromSelector(@selector(expiration))];
}

@end
