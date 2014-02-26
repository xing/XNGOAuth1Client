#import "NSString+XNGOAuth1Additions.h"

@implementation NSString (XNGOAuth1Additions)

- (NSString *)xng_URLEncode {
    return (__bridge_transfer NSString *)
            CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                    (__bridge CFStringRef)self,
                    NULL,
                    (__bridge CFStringRef)@"!*'\"();:@&=+$,/?%#[] ",
                    kCFStringEncodingUTF8);
}

- (NSString *)xng_URLDecode {
    return (__bridge_transfer NSString *)
            CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault,
                    (__bridge CFStringRef)self,
                    (__bridge CFStringRef)@"",
                    kCFStringEncodingUTF8);
}

@end
