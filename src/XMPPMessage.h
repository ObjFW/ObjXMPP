#import "XMPPStanza.h"

/**
 * \brief A class describing a message stanza.
 */
@interface XMPPMessage: XMPPStanza
/**
 * Creates a new autoreleased XMPPMessage.
 *
 * \return A new autoreleased XMPPMessage
 */
+ message;

/**
 * Creates a new autoreleased XMPPMessage with the specified id.
 *
 * \param ID The value for the stanza's id attribute
 * \return A new autoreleased XMPPMessage
 */
+ messageWithID: (OFString*)ID;

/**
 * Creates a new autoreleased XMPPMessage with the specified type.
 *
 * \param type The value for the stanza's type attribute
 * \return A new autoreleased XMPPMessage
 */
+ messageWithType: (OFString*)type;

/**
 * Creates a new autoreleased XMPPMessage with the specified type and id.
 *
 * \param type The value for the stanza's type attribute
 * \param ID The value for the stanza's id attribute
 * \return A new autoreleased XMPPMessage
 */
+ messageWithType: (OFString*)type
	       ID: (OFString*)ID;

/**
 * Initializes an already allocated XMPPMessage.
 *
 * \return A initialized XMPPMessage
 */
- init;

/**
 * Initializes an already allocated XMPPMessage with the specified id.
 *
 * \param ID The value for the stanza's id attribute
 * \return A initialized XMPPMessage
 */
- initWithID: (OFString*)ID;

/**
 * Initializes an already allocated XMPPMessage with the specified type.
 *
 * \param type The value for the stanza's type attribute
 * \return A initialized XMPPMessage
 */
- initWithType: (OFString*)type;

/**
 * Initializes an already allocated XMPPMessage with the specified type and id.
 *
 * \param type The value for the stanza's type attribute
 * \param ID The value for the stanza's id attribute
 * \return A initialized XMPPMessage
 */
- initWithType: (OFString*)type
	    ID: (OFString*)ID;

/**
 * Adds a body element to the XMPPMessage
 *
 * \param body The text content of the body element
 */
- (void)addBody: (OFString*)body;
@end
