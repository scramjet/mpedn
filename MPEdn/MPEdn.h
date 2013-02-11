#import <Foundation/Foundation.h>

typedef enum
{
  ERROR_OK,
  ERROR_INVALID_NUMBER,
  ERROR_NO_EXPRESSION,
  ERROR_UNSUPPORTED_FEATURE
} EdnParserErrorCode;

@interface MPEdnParser : NSObject
{
  NSString *inputStr;
  NSUInteger startIdx;
  NSUInteger endIdx;
  NSUInteger inputStrLen;
  NSUInteger token;
  id tokenValue;
  NSError *error;
}

@property (readonly) NSError *error;

- (void) reset;

- (id) parseString: (NSString *) str;

@end

@interface NSString (MPEdn)

- (id) ednStringToObject;

@end

@interface NSObject (MPEdn)

- (NSString *) objectToEdnString;

@end
