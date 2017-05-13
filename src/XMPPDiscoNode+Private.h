#import "XMPPDiscoNode.h"

OF_ASSUME_NONNULL_BEGIN

@class XMPPConnection;
@class XMPPIQ;

@interface XMPPDiscoNode ()
- (bool)XMPP_handleItemsIQ: (XMPPIQ *)IQ
		connection: (XMPPConnection *)connection;
- (bool)XMPP_handleInfoIQ: (XMPPIQ *)IQ
	       connection: (XMPPConnection *)connection;
@end

OF_ASSUME_NONNULL_END
