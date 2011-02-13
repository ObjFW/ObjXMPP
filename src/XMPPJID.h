#import <ObjFW/ObjFW.h>

/**
 * \brief A class for easy handling of JIDs
 */
@interface XMPPJID: OFObject
{
	/**
	 * The JID's localpart
	 */
	OFString *node;

	/**
	 * The JID's domainpart
	 */
	OFString *domain;

	/**
	 * The JID's resourcepart
	 */
	OFString *resource;
}

@property (copy) OFString *node;
@property (copy) OFString *domain;
@property (copy) OFString *resource;

/**
 * Creates a new XMPPJID
 *
 * \return A new autoreleased XMPPJID
 */
+ JID;

/**
 * Creates a new XMPPJID from a OFString
 *
 * \param str The string to parse into a JID object
 * \return A new autoreleased XMPPJID
 */
+ JIDWithString: (OFString*)str;

/**
 * Initializes an already allocated XMPPJID using a OFString
 *
 * \param str The string to parse into a JID object
 * \return A initialized XMPPJID
 */
- initWithString: (OFString*)str;

/**
 * \return A OFString containing the bare JID
 */
- (OFString*)bareJID;

/**
 * \return A OFString containing the full JID
 */
- (OFString*)fullJID;
@end
