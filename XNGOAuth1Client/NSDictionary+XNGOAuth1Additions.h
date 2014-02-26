@interface NSDictionary (XNGOAuth1Additions)

+ (id)xng_dictionaryFromQueryString:(NSString *)queryString;

- (id)xng_initWithQueryString:(NSString *)queryString;

- (NSString *)xng_queryStringRepresentation;

@end
