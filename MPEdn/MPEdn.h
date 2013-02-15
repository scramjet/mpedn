#import <Foundation/Foundation.h>

#import "MPEdnParser.h"

@interface NSString (MPEdn)

/**
 * Shortcut to parse a single string with [MPEdnParser parseString:].
 */
- (id) ednStringToObject;

@end

@interface NSObject (MPEdn)

- (NSString *) objectToEdnString;

@end
