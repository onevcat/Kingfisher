#import "NSURLRequest+LSHTTPRequest.h"

@implementation NSURLRequest (LSHTTPRequest)

- (NSURL*)url {
    return self.URL;
}

- (NSString *)method {
    return self.HTTPMethod;
}

- (NSDictionary *)headers {
    return self.allHTTPHeaderFields;
}

- (NSData *)body {
    if (self.HTTPBodyStream) {
        NSInputStream *stream = self.HTTPBodyStream;
        NSMutableData *data = [NSMutableData data];
        [stream open];
        size_t bufferSize = 4096;
        uint8_t *buffer = malloc(bufferSize);
        if (buffer == NULL) {
            [NSException raise:@"NocillaMallocFailure" format:@"Could not allocate %zu bytes to read HTTPBodyStream", bufferSize];
        }
        while ([stream hasBytesAvailable]) {
            NSInteger bytesRead = [stream read:buffer maxLength:bufferSize];
            if (bytesRead > 0) {
                NSData *readData = [NSData dataWithBytes:buffer length:bytesRead];
                [data appendData:readData];
            } else if (bytesRead < 0) {
                [NSException raise:@"NocillaStreamReadError" format:@"An error occurred while reading HTTPBodyStream (%ld)", (long)bytesRead];
            } else if (bytesRead == 0) {
                break;
            }
        }
        free(buffer);
        [stream close];

        return data;
    }

    return self.HTTPBody;
}

@end
