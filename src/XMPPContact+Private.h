#import "XMPPContact.h"

OF_ASSUME_NONNULL_BEGIN

@interface XMPPContact ()
@property (readwrite, nonatomic, setter=xmpp_setRosterItem:)
    XMPPRosterItem *rosterItem;
@property OF_NULLABLE_PROPERTY (retain, nonatomic) XMPPJID *xmpp_lockedOnJID;

- (void)xmpp_setPresence: (XMPPPresence *)presence
		resource: (OFString *)resource;
- (void)xmpp_removePresenceForResource: (OFString *)resource;
@end

OF_ASSUME_NONNULL_END
