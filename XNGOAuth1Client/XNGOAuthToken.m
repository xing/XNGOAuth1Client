#import "XNGOAuthToken.h"
#import "NSDictionary+XNGOAuth1Additions.h"

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

- (id)initWithQueryString:(NSString *)queryString {

    if (queryString || queryString.length == 0) {
        return nil;
    }

    NSDictionary *attributes = [NSDictionary dictionaryFromQueryString:queryString];

    if (attributes.allKeys.count == 0) {
        return nil;
    }

    NSString *token = attributes[@"oauth_token"];
    NSString *secret = attributes[@"oauth_token_secret"];
    NSString *verifier = attributes[@"oauth_verifier"];

    NSDate *expiration;
    if (attributes[@"oauth_token_duration"]) {
        expiration = [NSDate dateWithTimeIntervalSinceNow:[attributes[@"oauth_token_duration"] doubleValue]];
    }

    self = [self initWithToken:token secret:secret expiration:expiration];

    if (self) {
        _verifier = verifier;

        NSMutableDictionary *mutableUserInfo = [attributes mutableCopy];
        [mutableUserInfo removeObjectsForKeys:@[@"oauth_token", @"oauth_token_secret", @"oauth_verifier", @"oauth_token_duration"]];
        if (mutableUserInfo.allKeys.count > 0) {
            _userInfo = [NSDictionary dictionaryWithDictionary:mutableUserInfo];
        }
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
