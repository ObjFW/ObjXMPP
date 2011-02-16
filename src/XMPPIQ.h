#import "XMPPStanza.h"

/**
 * \brief A class describing a IQ stanza
 */
@interface XMPPIQ: XMPPStanza
/**
 * Creates a new XMPPIQ with a certain type and id
 *
 * \param type The value for the stanza's type attribute
 * \param ID The value for the stanza's id attribute
 * \return A new autoreleased XMPPIQ
 */
+ IQWithType: (OFString*)type
	  ID: (OFString*)ID;

/**
 * Initializes an already allocated XMPPIQ with a certain type and id
 *
 * \param type The value for the stanza's type attribute
 * \param ID The value for the stanza's id attribute
 * \return A initialized XMPPIQ
 */
- initWithType: (OFString*)type
	    ID: (OFString*)ID;
@end
