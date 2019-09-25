#import "LSASIHTTPRequestHook.h"
#import "ASIHTTPRequestStub.h"
#import <objc/runtime.h>

@implementation LSASIHTTPRequestHook

- (void)load {
    if (!NSClassFromString(@"ASIHTTPRequest")) return;
    [self swizzleASIHTTPRequest];
}

- (void)unload {
    if (!NSClassFromString(@"ASIHTTPRequest")) return;
    [self swizzleASIHTTPRequest];
}

#pragma mark - Internal Methods

- (void)swizzleASIHTTPRequest {
    [self swizzleASIHTTPSelector:NSSelectorFromString(@"responseStatusCode") withSelector:@selector(stub_responseStatusCode)];
    [self swizzleASIHTTPSelector:NSSelectorFromString(@"responseData") withSelector:@selector(stub_responseData)];
    [self swizzleASIHTTPSelector:NSSelectorFromString(@"responseHeaders") withSelector:@selector(stub_responseHeaders)];
    [self swizzleASIHTTPSelector:NSSelectorFromString(@"startRequest") withSelector:@selector(stub_startRequest)];
    [self addMethodToASIHTTPRequest:NSSelectorFromString(@"stubResponse")];
    [self addMethodToASIHTTPRequest:NSSelectorFromString(@"setStubResponse:")];
}

- (void)swizzleASIHTTPSelector:(SEL)original withSelector:(SEL)stub {
    Class asiHttpRequest = NSClassFromString(@"ASIHTTPRequest");
    Method originalMethod = class_getInstanceMethod(asiHttpRequest, original);
    Method stubMethod = class_getInstanceMethod([ASIHTTPRequestStub class], stub);
    if (!originalMethod || !stubMethod) {
        [self fail];
    }
    method_exchangeImplementations(originalMethod, stubMethod);
}

- (void)addMethodToASIHTTPRequest:(SEL)newMethod {
    Method method = class_getInstanceMethod([ASIHTTPRequestStub class], newMethod);
    const char *types = method_getTypeEncoding(method);
    class_addMethod(NSClassFromString(@"ASIHTTPRequest"), newMethod, class_getMethodImplementation([ASIHTTPRequestStub class], newMethod), types);
}

- (void)fail {
    [NSException raise:NSInternalInconsistencyException format:@"Couldn't load ASIHTTPRequest hook."];
}

@end
