#include <assert.h>

#import <ObjFW/ObjFW.h>

#import "XMPPConnection.h"
#import "XMPPStanza.h"

@interface AppDelegate: OFObject
{
	XMPPConnection *conn;
}
@end

OF_APPLICATION_DELEGATE(AppDelegate)

@implementation AppDelegate
- (void)applicationDidFinishLaunching
{
	OFArray *arguments = [OFApplication arguments];

	XMPPPresence *pres = [XMPPPresence presence];
	[pres addShow: @"chat"];
	[pres addStatus: @"Bored"];
	[pres addPriority: 20];
	pres.to = @"alice@example.com";
	pres.from = @"bob@example.org";
	assert([[pres stringValue] isEqual: @"<presence to='alice@example.com' "
			@"from='bob@example.org'><show>chat</show>"
			@"<status>Bored</status><priority>20</priority>"
			@"</presence>"]);

	XMPPMessage *msg = [XMPPMessage messageWithType: @"chat"];
	[msg addBody: @"Hello everyone"];
	msg.to = @"jdev@conference.jabber.org";
	msg.from = @"alice@example.com";
	assert([[msg stringValue] isEqual: @"<message type='chat' "
			@"to='jdev@conference.jabber.org' "
			@"from='alice@example.com'><body>Hello everyone</body>"
			@"</message>"]);

	XMPPIQ *iq = [XMPPIQ IQWithType: @"set" ID: @"128"];
	iq.to = @"juliet@capulet.lit";
	iq.from = @"romeo@montague.lit";
	assert([[iq stringValue] isEqual: @"<iq type='set' id='128' "
			@"to='juliet@capulet.lit' "
			@"from='romeo@montague.lit'/>"]);

	OFXMLElement *elem = [OFXMLElement elementWithName: @"iq"];
	[elem addAttributeWithName: @"from" stringValue: @"bob@localhost"];
	[elem addAttributeWithName: @"to" stringValue: @"alice@localhost"];
	[elem addAttributeWithName: @"type" stringValue: @"get"];
	[elem addAttributeWithName: @"id" stringValue: @"42"];
	XMPPStanza *stanza = [XMPPStanza stanzaWithElement: elem];
	assert([[elem stringValue] isEqual: [stanza stringValue]]);
	assert(([[OFString stringWithFormat: @"%@, %@, %@, %@", stanza.from,
			stanza.to, stanza.type, stanza.ID]
			isEqual: @"bob@localhost, alice@localhost, get, 42"]));

	conn = [[XMPPConnection alloc] init];

	if (arguments.count != 3) {
		of_log(@"Invalid count of command line arguments!");
		[OFApplication terminateWithStatus: 1];
	}

	[conn setServer: [arguments objectAtIndex: 0]];
	[conn setUsername: [arguments objectAtIndex: 1]];
	[conn setPassword: [arguments objectAtIndex: 2]];
	[conn setResource: @"ObjXMPP"];
	[conn setUseTLS: NO];

	[conn connect];
	[conn handleConnection];
}
@end
