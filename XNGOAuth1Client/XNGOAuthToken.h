@interface XNGOAuthToken : NSObject <NSCoding>

- (id)initWithToken:(NSString *)token secret:(NSString *)secret expiration:(NSDate *)expiration;

- (BOOL)isExpired;

@end
