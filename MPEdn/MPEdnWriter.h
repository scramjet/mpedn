#import <Foundation/Foundation.h>

/**
 * NSNumber is pretty broken wrt characters. For example, `[NSNumber
 * numberWithChar: 'a']` produces an NSNumber that says it wraps a
 * character, but using numberWithChar with `\n` does not.
 *
 * As as workaround for this, you can force a number to be seen as a
 * character using MPEdnTagAsCharacter. See discussion here:
 * http://www.cocoabuilder.com/archive/cocoa/136956-nsnumber-is-completely-broken.html.
 *
 * @see MPEdnIsCharacter()
 */
NSNumber *MPEdnTagAsCharacter (NSNumber *number);

/**
 * Test if MPEdnTagAsCharacter() has been used to tag a given number.
 * 
 * @see MPEdnTagAsCharacter()
 */
BOOL MPEdnIsCharacter (NSNumber *number);

/**
 * Converts Cocoa data objects into EDN-formatted strings. See
 * http://https://github.com/edn-format/edn.
 * 
 * If you want to simple turn an object into an EDN string, use
 * objectToEdnString. Example:
 *
 *	[myObject objectToEdnString];
 */
@interface MPEdnWriter : NSObject
{
  NSMutableString *outputStr;
  BOOL useKeywordsInMaps;
}

/**
 * When set (the default), automatically output string keys in
 * NSDictionary as EDN keywords where possible.
 */
@property (readwrite) BOOL useKeywordsInMaps;

/**
 * Take a Cocoa object, and generate an EDN-formatted string.
 *
 * @see [NSObject(MPEdn) objectToEdnString]
 */
- (NSString *) serialiseToEdn: (id) value;

@end

@interface NSObject (MPEdn)

/**
 * Shortcut to generate an EDN-formatted string for an object.
 *
 *  @see [MPEdnWriter serialiseToEdn]
 */
- (NSString *) objectToEdnString;

@end
