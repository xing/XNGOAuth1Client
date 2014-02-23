@interface XNGOAuthToken : NSObject <NSCoding>

@property (nonatomic, readonly) NSString *token;
@property (nonatomic, readonly) NSString *secret;
@property (nonatomic, readonly) NSString *verifier;
@property (nonatomic) NSDictionary *userInfo;

- (id)initWithToken:(NSString *)token secret:(NSString *)secret expiration:(NSDate *)expiration;

- (id)initWithQueryString:(NSString *)queryString;

- (BOOL)isExpired;

@end
