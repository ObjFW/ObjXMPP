#import "XMPPContact.h"

OF_ASSUME_NONNULL_BEGIN

@interface XMPPContact ()
- (void)XMPP_setRosterItem: (XMPPRosterItem *)rosterItem;
- (void)XMPP_setPresence: (XMPPPresence *)presence
		resource: (OFString *)resource;
- (void)XMPP_removePresenceForResource: (OFString *)resource;
- (void)XMPP_setLockedOnJID: (nullable XMPPJID *)JID;
@end

OF_ASSUME_NONNULL_END
