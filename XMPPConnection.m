#import "XMPPConnection.h"

#define NS_BIND @"urn:ietf:params:xml:ns:xmpp-bind"
#define NS_CLIENT @"jabber:client"
#define NS_SASL @"urn:ietf:params:xml:ns:xmpp-sasl"
#define NS_STREAM @"http://etherx.jabber.org/streams"

@implementation XMPPConnection
@synthesize username;
@synthesize password;
@synthesize server;
@synthesize resource;
@synthesize port;
@synthesize useTLS;
@synthesize delegate;

- init
{
	self = [super init];

	sock = [[OFTCPSocket alloc] init];
	parser = [[OFXMLParser alloc] init];
	elementBuilder = [[OFXMLElementBuilder alloc] init];

	port = 5222;
	useTLS = YES;

	mechanisms = [[OFMutableArray alloc] init];

	parser.delegate = self;
	elementBuilder.delegate = self;

	return self;
}

- (void)dealloc
{
	[sock release];
	[parser release];
	[elementBuilder release];

	[super dealloc];
}

- (void)_startStream
{
	[sock writeFormat: @"<?xml version='1.0'?>\n"
			   @"<stream:stream to='%@' xmlns='" NS_CLIENT @"' "
			   @"xmlns:stream='" NS_STREAM @"' "
			   @"version='1.0'>", server];
}

- (void)connect
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];

	[sock connectToService: [OFString stringWithFormat: @"%u", port]
			onNode: server];
	[self _startStream];

	[pool release];
}

- (void)handleConnection
{
	char buf[512];

	for (;;) {
		size_t len = [sock readNBytes: 512
				   intoBuffer: buf];

		if (len < 1)
			[delegate connectionWasClosed: self];

		[of_stdout writeNBytes: len
			    fromBuffer: buf];
		[parser parseBuffer: buf
			   withSize: len];
	}
}

-    (void)parser: (OFXMLParser*)p
  didStartElement: (OFString*)name
       withPrefix: (OFString*)prefix
	namespace: (OFString*)ns
       attributes: (OFArray*)attrs
{
	if (![name isEqual: @"stream"] || ![prefix isEqual: @"stream"] ||
	    ![ns isEqual: NS_STREAM])
		of_log(@"Did not get expected stream start!");

	for (OFXMLAttribute *attr in attrs)
		if ([attr.name isEqual: @"from"] &&
		    ![attr.stringValue isEqual: server])
			of_log(@"Got invalid from in stream start!");

	parser.delegate = elementBuilder;
}

- (void)_addAuthMechanisms: (OFXMLElement*)mechanisms_
{
	for (OFXMLElement *mechanism in mechanisms_.children)
		[mechanisms addObject:
		    [mechanism.children.firstObject stringValue]];
}

- (void)_sendPLAINAuth
{
	OFXMLElement *authTag;
	OFDataArray *message;

	message = [OFDataArray dataArrayWithItemSize: 1];
	/* XXX: authzid would go here */
	//[message addItem: authzid];
	/* separator */
	[message addItem: ""];
	/* authcid */
	[message addNItems: [username cStringLength]
		fromCArray: [username cString]];
	/* separator */
	[message addItem: ""];
	/* passwd */
	[message addNItems: [password cStringLength]
		fromCArray: [password cString]];

	authTag = [OFXMLElement elementWithName: @"auth"
				      namespace: NS_SASL];
	[authTag addAttributeWithName: @"mechanism"
			  stringValue: @"PLAIN"];
	[authTag addChild: [OFXMLElement elementWithCharacters:
	    [message stringByBase64Encoding]]];

	[sock writeString: [authTag stringValue]];
}

- (void)_sendResourceBind
{
	OFXMLElement *iq = [OFXMLElement elementWithName: @"iq"];
	[iq addAttributeWithName: @"type" stringValue: @"set"];
	[iq addChild: [OFXMLElement elementWithName: @"bind"
					  namespace: NS_BIND]];

	[sock writeString: [iq stringValue]];
}

- (void)_handleFeatures: (OFXMLElement*)elem
{
	for (OFXMLElement *child in elem.children) {
		if ([[child name] isEqual: @"mechanisms"] &&
		    [[child namespace] isEqual: NS_SASL])
			[self _addAuthMechanisms: child];
		else if ([[child name] isEqual: @"bind"] &&
		    [[child namespace] isEqual: NS_BIND])
			[self _sendResourceBind];
	}

	if ([mechanisms containsObject: @"PLAIN"])
		[self _sendPLAINAuth];
}

- (void)elementBuilder: (OFXMLElementBuilder*)b
       didBuildElement: (OFXMLElement*)elem
{
	elem.defaultNamespace = NS_CLIENT;
	[elem setPrefix: @"stream"
	   forNamespace: NS_STREAM];

	if ([elem.name isEqual: @"features"] &&
	    [elem.namespace isEqual: NS_STREAM]) {
		[self _handleFeatures: elem];
		return;
	}

	if ([elem.namespace isEqual: NS_SASL]) {
		if ([elem.name isEqual: @"success"]) {
			of_log(@"Auth successful");

			/* Stream restart */
			[mechanisms release];
			mechanisms = [[OFMutableArray alloc] init];
			parser.delegate = self;

			[self _startStream];
			return;
		}

		if ([elem.name isEqual: @"failure"])
			of_log(@"Auth failed!");
			// FIXME: Handle!
	}
}

- (void)elementBuilder: (OFXMLElementBuilder*)b
  didNotExpectCloseTag: (OFString*)name
	    withPrefix: (OFString*)prefix
	     namespace: (OFString*)ns
{
	// TODO
}
@end
