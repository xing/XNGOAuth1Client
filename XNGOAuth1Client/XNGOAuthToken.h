@interface XNGOAuthToken : NSObject <NSCoding>

- (id)initWithToken:(NSString *)token secret:(NSString *)secret expiration:(NSDate *)expiration;

- (id)initWithQueryString:(NSString *)queryString;

- (BOOL)isExpired;

@end
