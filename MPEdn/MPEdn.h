#import <Foundation/Foundation.h>

/**
 * Codes for parse errors reported in EdnParse.error.
 */
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
  ERROR_INVALID_DISCARD,
  ERROR_INVALID_CHARACTER,
  ERROR_INVALID_TAG,
  ERROR_UNTERMINATED_COLLECTION
} MPEdnParserErrorCode;

/**
 * A parser for values encoded in EDN (extensible data notation). See
 * http://https://github.com/edn-format/edn.
 *
 * If you want to simply parse a string containing EDN-encoded data,
 * you can use the [NSString(MPEdn) ednStringToObject] shortcut.
 * 
 * Example: parse a string containing a single EDN-encoded value:
 * 
 * 	MPEdnParser *parser = [MPEdnParser new];
 *
 *	id value = [parser parseString: @"{:a 1 :b foo}"];
 *	// Or just [@"{:a 1 :b foo}" ednStringToObject]
 *
 *	NSLog (@"Value is a map: %@", value);
 *
 * Example: parse all values in a string that may have zero or more
 * EDN values using parseNextValue :
 *
 *	MPEdnParser *parser = [MPEdnParser new];
 *	parser.inputString = @"1 \"abc\" {:a 1, :foo [1 2 3]}";
 *
 *	while (!parser.complete)
 *	{
 *	  id value = [parser parseNextValue];
 *	   
 *	  NSLog (@"Value %@", value);
 *	}
 *
 * On a parse error, the error property will be set.
 */
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

/**
 * The string to parse.
 * 
 * You typically set this property and then use parseString: or
 * parseNextValue (in a loop).
 */
@property (readwrite) NSString *inputString;

/** 
 * Set when the parser encounters a parse error.
 *
 * Nil when no error. Error codes are enumerated in
 * MPEdnParserErrorCode.
 *
 * @see MPEdnParserErrorCode
 */
@property (readonly) NSError *error;

@property (readonly) BOOL complete;

+ (NSString *) tagForValue: (id) value;

- (void) reset;

/**
 * Parse a string containing a single EDN value.
 *
 * This is essentially a shortcut for setting the inputString property
 * and then calling parseNextValue. It also checks that there is only
 * a single EDN value to be parsed and raises an error if not.
 *
 * This may be called multiple times for the same parser instance to
 * parse muliple EDN input strings.
 * 
 * @param str The string to parse.
 *
 * @return The parsed value, or nil on error (in which case the error
 * property will be set).
 *
 * @see parseNextValue
 * @see [NSString(MPEdn) ednStringToObject]
 */
- (id) parseString: (NSString *) str;

/**
 * Parse and return the next value from the current input string
 * (inputString).
 * 
 * See the doc for the MPEdnParser class documentation for an example
 * of using this method to parse several values from the input.
 *
 * @see parseString
 * @see [NSString(MPEdn) ednStringToObject]
 */
- (id) parseNextValue;

@end

@interface NSString (MPEdn)

/**
 * Shortcut to parse a single string with [MPEdnParser parseString:].
 */
- (id) ednStringToObject;

@end

@interface NSObject (MPEdn)

- (NSString *) objectToEdnString;

@end
