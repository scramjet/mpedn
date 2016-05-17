@interface NSString (MPEdnParser)

/**
 * Shortcut to parse a single string with [MPEdnParser parseString:].
 */
- (id) ednStringToObject;

/**
 * Shortcut to parse a single string with [MPEdnParser parseString:]
 * with the `keywordsAsStrings` property set to true.
 */
- (id) ednStringToObjectNoKeywords;

@end
