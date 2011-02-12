#import <ObjFW/ObjFW.h>

/**
 * \brief A class describing a XMPP Stanza
 */
@interface XMPPStanza: OFXMLElement
{
	/**
	 * The value of the stanza's from attribute
	 */
	OFString *from;

	/**
	 * The value of the stanza's to attribute
	 */
	OFString *to;

	/**
	 * The value of the stanza's type attribute
	 */
	OFString *type;

	/**
	 * The value of the stanza's id attribute
	 */
	OFString *ID;
}

@property (copy) OFString *from;
@property (copy) OFString *to;
@property (copy) OFString *type;
@property (copy) OFString *ID;

/**
 * Creates a new XMPPStanza with a certain name
 *
 * \param name The stanza's name (one of iq, message or presence)
 * \return A new autoreleased XMPPStanza
 */
+ stanzaWithName: (OFString*)name;

/**
 * Creates a new XMPPStanza with a certain name and type
 *
 * \param name The stanza's name (one of iq, message or presence)
 * \param type The value for the stanza's type attribute
 * \return A new autoreleased XMPPStanza
 */
+ stanzaWithName: (OFString*)name
	    type: (OFString*)type;

/**
 * Creates a new XMPPStanza with a certain name and id
 *
 * \param name The stanza's name (one of iq, message or presence)
 * \param ID The value for the stanza's id attribute
 * \return A new autoreleased XMPPStanza
 */
+ stanzaWithName: (OFString*)name
	      ID: (OFString*)ID;

/**
 * Creates a new XMPPStanza with a certain name, type and id
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
 * Creates a new XMPPStanza from a OFXMLElement
 *
 * \param elem The element to base the XMPPStanza on
 * \return A new autoreleased XMPPStanza
 */
+ stanzaWithElement: (OFXMLElement*)elem;

/**
 * Initializes an already allocated XMPPStanza with a certain name
 *
 * \param name The stanza's name (one of iq, message or presence)
 * \return A initialized XMPPStanza
 */
- initWithName: (OFString*)name;

/**
 * Initializes an already allocated XMPPStanza with a certain name and type
 *
 * \param name The stanza's name (one of iq, message or presence)
 * \param type The value for the stanza's type attribute
 * \return A initialized XMPPStanza
 */
- initWithName: (OFString*)name
	    type: (OFString*)type;

/**
 * Initializes an already allocated XMPPStanza with a certain name and id
 *
 * \param name The stanza's name (one of iq, message or presence)
 * \param ID The value for the stanza's id attribute
 * \return A initialized XMPPStanza
 */
- initWithName: (OFString*)name
	      ID: (OFString*)ID;

/**
 * Initializes an already allocated XMPPStanza with a certain name, type and id
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

/**
 * \brief A class describing a IQ stanza
 */
@interface XMPPIQ: XMPPStanza
{
}

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

/**
 * \brief A class describing a message stanza
 */
@interface XMPPMessage: XMPPStanza
{
}

/**
 * Creates a new XMPPMessage
 *
 * \return A new autoreleased XMPPMessage
 */
+ message;

/**
 * Creates a new XMPPMessage with a certain id
 *
 * \param ID The value for the stanza's id attribute
 * \return A new autoreleased XMPPMessage
 */
+ messageWithID: (OFString*)ID;

/**
 * Creates a new XMPPMessage with a certain type
 *
 * \param type The value for the stanza's type attribute
 * \return A new autoreleased XMPPMessage
 */
+ messageWithType: (OFString*)type;

/**
 * Creates a new XMPPMessage with a certain type and id
 *
 * \param type The value for the stanza's type attribute
 * \param ID The value for the stanza's id attribute
 * \return A new autoreleased XMPPMessage
 */
+ messageWithType: (OFString*)type
	       ID: (OFString*)ID;

/**
 * Initializes an already allocated XMPPMessage
 *
 * \return A initialized XMPPMessage
 */
- init;

/**
 * Initializes an already allocated XMPPMessage with a certain id
 *
 * \param ID The value for the stanza's id attribute
 * \return A initialized XMPPMessage
 */
- initWithID: (OFString*)ID;

/**
 * Initializes an already allocated XMPPMessage with a certain type
 *
 * \param type The value for the stanza's type attribute
 * \return A initialized XMPPMessage
 */
- initWithType: (OFString*)type;

/**
 * Initializes an already allocated XMPPMessage with a certain type and id
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

/**
 * \brief A class describing a presence stanza
 */
@interface XMPPPresence: XMPPStanza
{
}

/**
 * Creates a new XMPPPresence
 *
 * \return A new autoreleased XMPPPresence
 */
+ presence;

/**
 * Creates a new XMPPPresence with a certain id
 *
 * \param ID The value for the stanza's id attribute
 * \return A new autoreleased XMPPPresence
 */
+ presenceWithID: (OFString*)ID;

/**
 * Creates a new XMPPPresence with a certain type
 *
 * \param type The value for the stanza's type attribute
 * \return A new autoreleased XMPPPresence
 */
+ presenceWithType: (OFString*)type;

/**
 * Creates a new XMPPPresence with a certain type and id
 *
 * \param type The value for the stanza's type attribute
 * \param ID The value for the stanza's id attribute
 * \return A new autoreleased XMPPPresence
 */
+ presenceWithType: (OFString*)type
		ID: (OFString*)ID;

/**
 * Initializes an already allocated XMPPPresence
 *
 * \return A initialized XMPPPresence
 */
- init;

/**
 * Initializes an already allocated XMPPPresence with a certain id
 *
 * \param ID The value for the stanza's id attribute
 * \return A initialized XMPPPresence
 */
- initWithID: (OFString*)ID;

/**
 * Initializes an already allocated XMPPPresence with a certain type
 *
 * \param type The value for the stanza's type attribute
 * \return A initialized XMPPPresence
 */
- initWithType: (OFString*)type;

/**
 * Initializes an already allocated XMPPPresence with a certain type and id
 *
 * \param type The value for the stanza's type attribute
 * \param ID The value for the stanza's id attribute
 * \return A initialized XMPPPresence
 */
- initWithType: (OFString*)type
	    ID: (OFString*)ID;

/**
 * Adds a show element to the presence stanza
 *
 * \param show The text content of the show element
 */
- (void)addShow: (OFString*)show;

/**
 * Adds a status element to the presence stanza
 *
 * \param status The text content of the status element
 */
- (void)addStatus: (OFString*)status;

/**
 * Adds a priority element to the presence stanza
 *
 * \param priority The text content of the priority element
 */
- (void)addPriority: (int8_t)priority;
@end
