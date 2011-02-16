#import <ObjFW/ObjFW.h>

/**
 * \brief A class describing an XMPP Stanza.
 */
@interface XMPPStanza: OFXMLElement
{
	/// The value of the stanza's from attribute
	OFString *from;
	/// The value of the stanza's to attribute
	OFString *to;
	/// The value of the stanza's type attribute
	OFString *type;
	/// The value of the stanza's id attribute
	OFString *ID;
}

@property (copy) OFString *from;
@property (copy) OFString *to;
@property (copy) OFString *type;
@property (copy) OFString *ID;

/**
 * Creates a new autoreleased XMPPStanza with the specified name.
 *
 * \param name The stanza's name (one of iq, message or presence)
 * \return A new autoreleased XMPPStanza
 */
+ stanzaWithName: (OFString*)name;

/**
 * Creates a new autoreleased XMPPStanza with the specified name and type.
 *
 * \param name The stanza's name (one of iq, message or presence)
 * \param type The value for the stanza's type attribute
 * \return A new autoreleased XMPPStanza
 */
+ stanzaWithName: (OFString*)name
	    type: (OFString*)type;

/**
 * Creates a new autoreleased XMPPStanza with the specified name and id.
 *
 * \param name The stanza's name (one of iq, message or presence)
 * \param ID The value for the stanza's id attribute
 * \return A new autoreleased XMPPStanza
 */
+ stanzaWithName: (OFString*)name
	      ID: (OFString*)ID;

/**
 * Creates a new autoreleased XMPPStanza with the specified name, type and id.
 *
 * \param name The stanza's name (one of iq, message or presence)
 * \param type The value for the stanza's type attribute
 * \param ID The value for the stanza's id attribute
 * \return A new autoreleased XMPPStanza
 */
+ stanzaWithName: (OFString*)name
	    type: (OFString*)type
	      ID: (OFString*)ID;

/**
 * Creates a new autoreleased XMPPStanza from an OFXMLElement.
 *
 * \param elem The element to base the XMPPStanza on
 * \return A new autoreleased XMPPStanza
 */
+ stanzaWithElement: (OFXMLElement*)elem;

/**
 * Initializes an already allocated XMPPStanza with the specified name.
 *
 * \param name The stanza's name (one of iq, message or presence)
 * \return A initialized XMPPStanza
 */
- initWithName: (OFString*)name;

/**
 * Initializes an already allocated XMPPStanza with the specified name and type.
 *
 * \param name The stanza's name (one of iq, message or presence)
 * \param type The value for the stanza's type attribute
 * \return A initialized XMPPStanza
 */
- initWithName: (OFString*)name
	  type: (OFString*)type;

/**
 * Initializes an already allocated XMPPStanza with the specified name and id.
 *
 * \param name The stanza's name (one of iq, message or presence)
 * \param ID The value for the stanza's id attribute
 * \return A initialized XMPPStanza
 */
- initWithName: (OFString*)name
	    ID: (OFString*)ID;

/**
 * Initializes an already allocated XMPPStanza with the specified name, type
 * and id.
 *
 * \param name The stanza's name (one of iq, message or presence)
 * \param type The value for the stanza's type attribute
 * \param ID The value for the stanza's id attribute
 * \return A initialized XMPPStanza
 */
- initWithName: (OFString*)name
	  type: (OFString*)type
	    ID: (OFString*)ID;

/**
 * Initializes an already allocated XMPPStanza based on a OFXMLElement
 *
 * \param elem The element to base the XMPPStanza on
 * \return A initialized XMPPStanza
 */
- initWithElement: (OFXMLElement*)elem;
@end
