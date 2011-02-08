#import <ObjFW/ObjFW.h>

@class XMPPConnection;
@class XMPPIQ;
@class XMPPMessage;
@class XMPPPresence;

@protocol XMPPConnectionDelegate
- (void)connectionWasClosed: (XMPPConnection*)conn;
- (void)connection: (XMPPConnection*)conn
      didReceiveIQ: (XMPPIQ*)iq;
-   (void)connection: (XMPPConnection*)conn
  didReceivePresence: (XMPPPresence*)pres;
-  (void)connection: (XMPPConnection*)conn
  didReceiveMessage: (XMPPMessage*)msg;
@end

@interface XMPPConnection: OFObject <OFXMLElementBuilderDelegate>
{
	OFTCPSocket *sock;
	OFXMLParser *parser;
	OFXMLElementBuilder *elementBuilder;
	OFString *username;
	OFString *password;
	OFString *server;
	OFString *resource;
	short port;
	BOOL useTLS;
	id <XMPPConnectionDelegate> delegate;
	OFMutableArray *mechanisms;
}

@property (copy) OFString *username;
@property (copy) OFString *password;
@property (copy) OFString *server;
@property (copy) OFString *resource;
@property (assign) short port;
@property (assign) BOOL useTLS;
@property (retain) id <XMPPConnectionDelegate> delegate;

- (void)connect;
- (void)handleConnection;
@end
