#import "XMPPContact.h"

OF_ASSUME_NONNULL_BEGIN

@interface XMPPContact ()
- (void)xmpp_setRosterItem: (XMPPRosterItem *)rosterItem;
- (void)xmpp_setPresence: (XMPPPresence *)presence
		resource: (OFString *)resource;
- (void)xmpp_removePresenceForResource: (OFString *)resource;
- (void)xmpp_setLockedOnJID: (nullable XMPPJID *)JID;
@end

OF_ASSUME_NONNULL_END
