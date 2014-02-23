#import "NSDictionary+XNGOAuth1Additions.h"
#import "NSString+XNGOAuth1Additions.h"

@implementation NSDictionary (XNGOAuth1Additions)

+ (id)dictionaryFromQueryString:(NSString *)queryString {
    return [[NSDictionary alloc] initWithQueryString:queryString];
}

- (id)initWithQueryString:(NSString *)queryString {
    NSArray *components = [queryString componentsSeparatedByString:@"&"];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];

    for (NSString *component in components) {
        NSArray *keyValue = [component componentsSeparatedByString:@"="];
        NSString *key = [keyValue[0] URLDecode];
        NSString *value = [keyValue[1] URLDecode];
        [dictionary setObject:value forKey:key];
    }

    return dictionary;
}

- (NSString *)queryStringRepresentation {
    NSMutableArray *paramArray = [NSMutableArray array];

    [self enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        NSString *param = [NSString stringWithFormat:@"%@=%@", [key URLEncode], [value URLEncode]];
        [paramArray addObject:param];
    }];

    return [paramArray componentsJoinedByString:@"&"];
}



@end
