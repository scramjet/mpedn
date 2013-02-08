#import <Foundation/Foundation.h>

typedef enum
{
  ERROR_INVALID_NUMBER = 1
} EdnParserErrorCode;

@interface NSString (MPEdn)

- (id) ednStringToObject;

@end

@interface NSObject (MPEdn)

- (NSString *) objectToEdnString;

@end
