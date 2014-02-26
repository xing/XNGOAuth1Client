#import "NSDictionary+XNGOAuth1Additions.h"
#import "NSString+XNGOAuth1Additions.h"

@implementation NSDictionary (XNGOAuth1Additions)

+ (id)xng_dictionaryFromQueryString:(NSString *)queryString {
    return [[NSDictionary alloc] xng_initWithQueryString:queryString];
}

- (id)xng_initWithQueryString:(NSString *)queryString {
    NSArray *components = [queryString componentsSeparatedByString:@"&"];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    for (NSString *component in components) {
        NSArray *keyValue = [component componentsSeparatedByString:@"="];
        NSString *key = [keyValue[0] xng_URLDecode];
        NSString *value = [keyValue[1] xng_URLDecode];
        [dictionary setObject:value forKey:key];
    }

    return dictionary;
}

- (NSString *)xng_queryStringRepresentation {
    NSMutableArray *paramArray = [NSMutableArray array];

    [self enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        NSString *param = [NSString stringWithFormat:@"%@=%@", [key xng_URLEncode], [value xng_URLEncode]];
        [paramArray addObject:param];
    }];

    return [paramArray componentsJoinedByString:@"&"];
}



@end
