#import "XMPPDiscoNode.h"

OF_ASSUME_NONNULL_BEGIN

@class XMPPConnection;
@class XMPPIQ;

@interface XMPPDiscoNode ()
- (bool)xmpp_handleItemsIQ: (XMPPIQ *)IQ
		connection: (XMPPConnection *)connection;
- (bool)xmpp_handleInfoIQ: (XMPPIQ *)IQ
	       connection: (XMPPConnection *)connection;
@end

OF_ASSUME_NONNULL_END
