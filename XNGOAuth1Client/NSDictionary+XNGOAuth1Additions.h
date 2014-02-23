@interface NSDictionary (XNGOAuth1Additions)

+ (id)dictionaryFromQueryString:(NSString *)queryString;

- (id)initWithQueryString:(NSString *)queryString;

- (NSString *)queryStringRepresentation;

@end
