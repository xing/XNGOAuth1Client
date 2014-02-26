#import "NSDictionary+XNGOAuth1Additions.h"
#import "NSString+XNGOAuth1Additions.h"

@implementation NSDictionary (XNGOAuth1Additions)

+ (id)xngo_dictionaryFromQueryString:(NSString *)queryString {
    return [[NSDictionary alloc] xngo_initWithQueryString:queryString];
}

- (id)xngo_initWithQueryString:(NSString *)queryString {
    NSArray *components = [queryString componentsSeparatedByString:@"&"];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    for (NSString *component in components) {
        NSArray *keyValue = [component componentsSeparatedByString:@"="];
        NSString *key = [keyValue[0] xngo_URLDecode];
        NSString *value = [keyValue[1] xngo_URLDecode];
        [dictionary setObject:value forKey:key];
    }

    return dictionary;
}

- (NSString *)xngo_queryStringRepresentation {
    NSMutableArray *paramArray = [NSMutableArray array];

    [self enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        NSString *param = [NSString stringWithFormat:@"%@=%@", [key xngo_URLEncode], [value xngo_URLEncode]];
        [paramArray addObject:param];
    }];

    return [paramArray componentsJoinedByString:@"&"];
}



@end
