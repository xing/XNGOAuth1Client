#import "XNGOAuthToken.h"
#import "NSDictionary+XNGOAuth1Additions.h"

static NSString *const XNGOAuthTokenTokenKey = @"oauth_token";
static NSString *const XNGOAuthTokenSecretKey = @"oauth_token_secret";
static NSString *const XNGOauthTokenVerifierKey = @"oauth_verifier";
static NSString *const XNGOAuthTokenDurationKey = @"oauth_token_duration";

@interface XNGOAuthToken ()

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

    if (!queryString || queryString.length == 0) {
        return nil;
    }

    NSDictionary *attributes = [NSDictionary xngo_dictionaryFromQueryString:queryString];

    if (attributes.allKeys.count == 0) {
        return nil;
    }

    NSString *token = attributes[XNGOAuthTokenTokenKey];
    NSString *secret = attributes[XNGOAuthTokenSecretKey];
    NSString *verifier = attributes[XNGOauthTokenVerifierKey];

    NSDate *expiration;
    if (attributes[XNGOAuthTokenDurationKey]) {
        expiration = [NSDate dateWithTimeIntervalSinceNow:[attributes[XNGOAuthTokenDurationKey] doubleValue]];
    }

    self = [self initWithToken:token secret:secret expiration:expiration];

    if (self) {
        _verifier = verifier;

        NSMutableDictionary *mutableUserInfo = [attributes mutableCopy];
        [mutableUserInfo removeObjectsForKeys:@[XNGOAuthTokenTokenKey, XNGOAuthTokenSecretKey, XNGOauthTokenVerifierKey, XNGOAuthTokenDurationKey]];
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
        _verifier = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(verifier))];
        _userInfo = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(userInfo))];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.token forKey:NSStringFromSelector(@selector(token))];
    [aCoder encodeObject:self.secret forKey:NSStringFromSelector(@selector(secret))];
    [aCoder encodeObject:self.expiration forKey:NSStringFromSelector(@selector(expiration))];
    [aCoder encodeObject:self.verifier forKey:NSStringFromSelector(@selector(verifier))];
    [aCoder encodeObject:self.userInfo forKey:NSStringFromSelector(@selector(userInfo))];
}

@end
