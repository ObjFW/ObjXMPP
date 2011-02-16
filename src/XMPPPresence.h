#import "XMPPStanza.h"

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
