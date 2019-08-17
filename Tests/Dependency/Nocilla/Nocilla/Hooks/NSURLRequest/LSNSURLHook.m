#import "LSNSURLHook.h"
#import "LSHTTPStubURLProtocol.h"

@implementation LSNSURLHook

- (void)load {
    [NSURLProtocol registerClass:[LSHTTPStubURLProtocol class]];
}

- (void)unload {
    [NSURLProtocol unregisterClass:[LSHTTPStubURLProtocol class]];
}

@end
