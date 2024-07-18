/*
 *  MPEdn: An EDN (extensible data notation) I/O library for OS X and
 *  iOS. See https://github.com/scramjet/mpedn and
 *  https://github.com/edn-format/edn.
 *
 *  Copyright (c) 2013 Matthew Phillips <m@mattp.name>
 *
 *  The use and distribution terms for this software are covered by
 *  the Eclipse Public License 1.0
 *  (http://opensource.org/licenses/eclipse-1.0.php). By using this
 *  software in any fashion, you are agreeing to be bound by the terms
 *  of this license.
 *
 *  You must not remove this notice, or any other, from this software.
 */

#import <Foundation/Foundation.h>

/**
 * Represents an EDN character instance.
 */
@interface MPEdnCharacter : NSObject<NSCopying, NSSecureCoding>

@property (class, readonly) BOOL supportsSecureCoding;

@property (readonly) unichar character;

/**
 * Create a character.
 */
+ (MPEdnCharacter *) character: (unichar) ch;

/**
 * Create a new character.
 */
- (instancetype) initWithCharacter: (unichar) ch;

/**
 * The character as a readable string.
 */
- (NSString *) stringValue;

- (NSComparisonResult) compare: (id) object;

@end
