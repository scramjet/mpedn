#import <Foundation/Foundation.h>

typedef enum
{
  ERROR_OK,
  ERROR_INVALID_TOKEN,
  ERROR_INVALID_NUMBER,
  ERROR_NO_EXPRESSION,
  ERROR_UNSUPPORTED_FEATURE,
  ERROR_MULTIPLE_VALUES,
  ERROR_INVALID_ESCAPE,
  ERROR_UNTERMINATED_STRING,
  ERROR_INVALID_KEYWORD,
  UNTERMINATED_COLLECTION
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

@property (readwrite) NSString *inputString;
@property (readonly) NSError *error;
@property (readonly) BOOL complete;

- (void) reset;

- (id) parseString: (NSString *) str;

- (id) parseNextValue;

@end

@interface NSString (MPEdn)

- (id) ednStringToObject;

@end

@interface NSObject (MPEdn)

- (NSString *) objectToEdnString;

@end
