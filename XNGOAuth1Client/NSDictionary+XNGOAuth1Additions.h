@interface NSDictionary (XNGOAuth1Additions)

+ (id)xngo_dictionaryFromQueryString:(NSString *)queryString;

- (id)xngo_initWithQueryString:(NSString *)queryString;

- (NSString *)xngo_queryStringRepresentation;

@end
