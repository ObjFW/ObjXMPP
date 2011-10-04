/*
 * Copyright (c) 2010, 2011, Jonathan Schleifer <js@webkeks.org>
 * Copyright (c) 2011, Florian Zeitz <florob@babelmonkeys.de>
 *
 * https://webkeks.org/hg/objxmpp/
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice is present in all copies.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#define XMPP_CONNECTION_M

#include <assert.h>

#include <stringprep.h>
#include <idna.h>

#import <ObjOpenSSL/SSLSocket.h>

#import "XMPPConnection.h"
#import "XMPPSRVLookup.h"
#import "XMPPSCRAMAuth.h"
#import "XMPPPLAINAuth.h"
#import "XMPPStanza.h"
#import "XMPPJID.h"
#import "XMPPIQ.h"
#import "XMPPMessage.h"
#import "XMPPPresence.h"
#import "XMPPRoster.h"
#import "XMPPRosterItem.h"
#import "XMPPExceptions.h"
#import "namespaces.h"

@implementation XMPPConnection
+ connection
{
	return [[[self alloc] init] autorelease];
}

- init
{
	self = [super init];

	@try {
		sock = [[OFTCPSocket alloc] init];
		port = 5222;
		encrypted = NO;
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[sock release];
	[parser release];
	[elementBuilder release];
	[username release];
	[password release];
	[server release];
	[domain release];
	[resource release];
	[JID release];
	[delegate release];
	[authModule release];
	[bindID release];
	[sessionID release];
	[roster release];

	[super dealloc];
}

- (void)setUsername: (OFString*)username_
{
	OFString *old = username;
	char *node;
	Stringprep_rc rc;

	if ((rc = stringprep_profile([username_ UTF8String], &node,
	    "SASLprep", 0)) != STRINGPREP_OK)
		@throw [XMPPStringPrepFailedException
		    exceptionWithClass: isa
			    connection: self
			       profile: @"SASLprep"
				string: username_];

	@try {
		username = [[OFString alloc] initWithUTF8String: node];
	} @finally {
		free(node);
	}

	[old release];
}

- (OFString*)username
{
	return [[username copy] autorelease];
}

- (void)setResource: (OFString*)resource_
{
	OFString *old = resource;
	char *res;
	Stringprep_rc rc;

	if ((rc = stringprep_profile([resource_ UTF8String], &res,
	    "Resourceprep", 0)) != STRINGPREP_OK)
		@throw [XMPPStringPrepFailedException
		    exceptionWithClass: isa
			    connection: self
			       profile: @"Resourceprep"
				string: resource_];

	@try {
		resource = [[OFString alloc] initWithUTF8String: res];
	} @finally {
		free(res);
	}

	[old release];
}

- (OFString*)resource
{
	return [[resource copy] autorelease];
}

- (void)setServer: (OFString*)server_
{
	OFString *old = server;
	char *srv;
	Idna_rc rc;

	if ((rc = idna_to_ascii_8z([server_ UTF8String],
	    &srv, IDNA_USE_STD3_ASCII_RULES)) != IDNA_SUCCESS)
		@throw [XMPPIDNATranslationFailedException
		    exceptionWithClass: isa
			    connection: self
			     operation: @"ToASCII"
				string: server_];

	@try {
		server = [[OFString alloc] initWithUTF8String: srv];
	} @finally {
		free(srv);
	}

	[old release];
}

- (OFString*)server
{
	return [[server copy] autorelease];
}

- (void)setDomain: (OFString*)domain_
{
	OFString *old = domain;
	char *srv;
	Stringprep_rc rc;

	if ((rc = stringprep_profile([domain_ UTF8String], &srv,
	    "Nameprep", 0)) != STRINGPREP_OK)
		@throw [XMPPStringPrepFailedException
		    exceptionWithClass: isa
			    connection: self
			       profile: @"Nameprep"
				string: domain_];

	@try {
		domain = [[OFString alloc] initWithUTF8String: srv];
	} @finally {
		free(srv);
	}

	[old release];
}

- (OFString*)domain
{
	return [[domain copy] autorelease];
}

- (void)setPassword: (OFString*)password_
{
	OFString *old = password;
	char *pass;
	Stringprep_rc rc;

	if ((rc = stringprep_profile([password_ UTF8String], &pass,
	    "SASLprep", 0)) != STRINGPREP_OK)
		@throw [XMPPStringPrepFailedException
		    exceptionWithClass: isa
			    connection: self
			       profile: @"SASLprep"
				string: password_];

	@try {
		password = [[OFString alloc] initWithUTF8String: pass];
	} @finally {
		free(pass);
	}

	[old release];
}

- (OFString*)password
{
	return [[password copy] autorelease];
}

- (void)connect
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	XMPPSRVEntry *candidate = nil;
	XMPPSRVLookup *SRVLookup = nil;
	OFEnumerator *enumerator;
	OFString *domainToASCII;
	char *cDomainToASCII;
	Idna_rc rc;

	if (server)
		[sock connectToHost: server
			       port: port];
	else {
		if ((rc = idna_to_ascii_8z([domain UTF8String], &cDomainToASCII,
		    IDNA_USE_STD3_ASCII_RULES)) != IDNA_SUCCESS)
			@throw [XMPPIDNATranslationFailedException
				exceptionWithClass: isa
					connection: self
					 operation: @"ToASCII"
					    string: domain];

		@try {
			domainToASCII = [OFString
			    stringWithUTF8String: cDomainToASCII];
		} @finally {
			free(cDomainToASCII);
		}

		@try {
			SRVLookup = [XMPPSRVLookup
			    lookupWithDomain: domainToASCII];
		} @catch (id e) {
		}

		enumerator = [SRVLookup objectEnumerator];

		/* Iterate over SRV records, if any */
		if ((candidate = [enumerator nextObject]) != nil) {
			do {
				@try {
					[sock connectToHost: [candidate target]
						       port: [candidate port]];
					break;
				} @catch (OFAddressTranslationFailedException
				    *e) {
				} @catch (OFConnectionFailedException *e) {
				}
			} while ((candidate = [enumerator nextObject]) != nil);
		} else
			/* No SRV records -> fall back to A / AAAA record */
			[sock connectToHost: domainToASCII
				       port: port];
	}

	[self XMPP_startStream];

	[pool release];
}

- (void)handleConnection
{
	char buffer[512];

	for (;;) {
		size_t length = [sock readNBytes: 512
				      intoBuffer: buffer];

		if (length < 1 && [delegate respondsToSelector:
		    @selector(connectionWasClosed:)])
			[delegate connectionWasClosed: self];

		[parser parseBuffer: buffer
			 withLength: length];
	}
}

- (void)parseBuffer: (const char*)buffer
	 withLength: (size_t)length
{
	if (length < 1 && [delegate respondsToSelector:
	    @selector(connectionWasClosed:)])
		[delegate connectionWasClosed: self];

	[parser parseBuffer: buffer
		 withLength: length];

	[oldParser release];
	[oldElementBuilder release];

	oldParser = nil;
	oldElementBuilder = nil;
}

- (OFTCPSocket*)socket
{
	return [[sock retain] autorelease];
}

- (BOOL)encryptionRequired
{
	return encryptionRequired;
}

- (void)setEncryptionRequired: (BOOL)required
{
	encryptionRequired = required;
}

- (BOOL)encrypted
{
	return encrypted;
}

- (void)sendStanza: (OFXMLElement*)element
{
	of_log(@"Out: %@", element);
	[sock writeString: [element XMLString]];
}

- (OFString*)generateStanzaID
{
	return [OFString stringWithFormat: @"objxmpp_%u", lastID++];
}

-    (void)parser: (OFXMLParser*)p
  didStartElement: (OFString*)name
       withPrefix: (OFString*)prefix
	namespace: (OFString*)ns
       attributes: (OFArray*)attributes
{
	OFEnumerator *enumerator;
	OFXMLAttribute *attribute;

	if (![name isEqual: @"stream"] || ![prefix isEqual: @"stream"] ||
	    ![ns isEqual: XMPP_NS_STREAM]) {
		of_log(@"Did not get expected stream start!");
		assert(0);
	}

	enumerator = [attributes objectEnumerator];
	while ((attribute = [enumerator nextObject]) != nil) {
		if ([[attribute name] isEqual: @"from"] &&
		    ![[attribute stringValue] isEqual: domain]) {
			of_log(@"Got invalid from in stream start!");
			assert(0);
		}
	}

	[parser setDelegate: elementBuilder];
}

-    (void)parser: (OFXMLParser*)p
    didEndElement: (OFString*)name
       withPrefix: (OFString*)prefix
	namespace: (OFString*)ns
       attributes: (OFArray*)attrs
{
	if (![name isEqual: @"stream"] || ![prefix isEqual: @"stream"] ||
	    ![ns isEqual: XMPP_NS_STREAM]) {
		of_log(@"Did not get expected stream end!");
		assert(0);
	}
}

- (void)elementBuilder: (OFXMLElementBuilder*)builder
       didBuildElement: (OFXMLElement*)element
{
	/* Ignore whitespace elements */
	if ([element name] == nil)
		return;

	[element setDefaultNamespace: XMPP_NS_CLIENT];
	[element setPrefix: @"stream"
	      forNamespace: XMPP_NS_STREAM];

	of_log(@"In:  %@", element);

	if ([[element namespace] isEqual: XMPP_NS_CLIENT])
		[self XMPP_handleStanza: element];

	if ([[element namespace] isEqual: XMPP_NS_STREAM])
		[self XMPP_handleStream: element];

	if ([[element namespace] isEqual: XMPP_NS_STARTTLS])
		[self XMPP_handleTLS: element];

	if ([[element namespace] isEqual: XMPP_NS_SASL])
		[self XMPP_handleSASL: element];
}

- (void)XMPP_startStream
{
	/* Make sure we don't get any old events */
	[parser setDelegate: nil];
	[elementBuilder setDelegate: nil];

	/*
	 * We can't release them now, as we are currently inside them. Release
	 * them the next time the parser returns.
	 */
	oldParser = parser;
	oldElementBuilder = elementBuilder;

	[roster release];

	parser = [[OFXMLParser alloc] init];
	[parser setDelegate: self];

	elementBuilder = [[OFXMLElementBuilder alloc] init];
	[elementBuilder setDelegate: self];

	roster = [[XMPPRoster alloc] initWithConnection: self];

	[sock writeFormat: @"<?xml version='1.0'?>\n"
			   @"<stream:stream to='%@' "
			   @"xmlns='" XMPP_NS_CLIENT @"' "
			   @"xmlns:stream='" XMPP_NS_STREAM @"' "
			   @"version='1.0'>", domain];
}

- (void)XMPP_handleStanza: (OFXMLElement*)element
{
	if ([[element name] isEqual: @"iq"]) {
		[self XMPP_handleIQ: [XMPPIQ stanzaWithElement: element]];
		return;
	}

	if ([[element name] isEqual: @"message"]) {
		[self XMPP_handleMessage:
		    [XMPPMessage stanzaWithElement: element]];
		return;
	}

	if ([[element name] isEqual: @"presence"]) {
		[self XMPP_handlePresence:
		    [XMPPPresence stanzaWithElement: element]];
		return;
	}

	assert(0);
}


- (void)XMPP_handleStream: (OFXMLElement*)element
{
	if ([[element name] isEqual: @"features"]) {
		[self XMPP_handleFeatures: element];
		return;
	}

	if ([[element name] isEqual: @"error"]) {
		OFString *condition, *reason;
		[parser setDelegate: self];
		[sock writeString: @"</stream:stream>"];
		[sock close];

		if ([element elementForName: @"bad-format"
				  namespace: XMPP_NS_XMPP_STREAM])
			condition = @"bad-format";
		else if ([element elementForName: @"bad-namespace-prefix"
				       namespace: XMPP_NS_XMPP_STREAM])
			condition = @"bad-namespace-prefix";
		else if ([element elementForName: @"conflict"
				       namespace: XMPP_NS_XMPP_STREAM])
			condition = @"conflict";
		else if ([element elementForName: @"connection-timeout"
				       namespace: XMPP_NS_XMPP_STREAM])
			condition = @"connection-timeout";
		else if ([element elementForName: @"host-gone"
				       namespace: XMPP_NS_XMPP_STREAM])
			condition = @"host-gone";
		else if ([element elementForName: @"host-unknown"
				       namespace: XMPP_NS_XMPP_STREAM])
			condition = @"host-unknown";
		else if ([element elementForName: @"improper-addressing"
				       namespace: XMPP_NS_XMPP_STREAM])
			condition = @"improper-addressing";
		else if ([element elementForName: @"internal-server-error"
				       namespace: XMPP_NS_XMPP_STREAM])
			condition = @"internal-server-error";
		else if ([element elementForName: @"invalid-from"
				       namespace: XMPP_NS_XMPP_STREAM])
			condition = @"invalid-from";
		else if ([element elementForName: @"invalid-namespace"
				       namespace: XMPP_NS_XMPP_STREAM])
			condition = @"invalid-namespace";
		else if ([element elementForName: @"invalid-xml"
				       namespace: XMPP_NS_XMPP_STREAM])
			condition = @"invalid-xml";
		else if ([element elementForName: @"not-authorized"
				       namespace: XMPP_NS_XMPP_STREAM])
			condition = @"not-authorized";
		else if ([element elementForName: @"not-well-formed"
				       namespace: XMPP_NS_XMPP_STREAM])
			condition = @"not-well-formed";
		else if ([element elementForName: @"policy-violation"
				       namespace: XMPP_NS_XMPP_STREAM])
			condition = @"policy-violation";
		else if ([element elementForName: @"remote-connection-failed"
				       namespace: XMPP_NS_XMPP_STREAM])
			condition = @"remote-connection-failed";
		else if ([element elementForName: @"reset"
				       namespace: XMPP_NS_XMPP_STREAM])
			condition = @"reset";
		else if ([element elementForName: @"resource-constraint"
				       namespace: XMPP_NS_XMPP_STREAM])
			condition = @"resource-constraint";
		else if ([element elementForName: @"restricted-xml"
				       namespace: XMPP_NS_XMPP_STREAM])
			condition = @"restricted-xml";
		else if ([element elementForName: @"see-other-host"
				       namespace: XMPP_NS_XMPP_STREAM])
			condition = @"see-other-host";
		else if ([element elementForName: @"system-shutdown"
				       namespace: XMPP_NS_XMPP_STREAM])
			condition = @"system-shutdown";
		else if ([element elementForName: @"undefined-condition"
				       namespace: XMPP_NS_XMPP_STREAM])
			condition = @"undefined-condition";
		else if ([element elementForName: @"unsupported-encoding"
				       namespace: XMPP_NS_XMPP_STREAM])
			condition = @"unsupported-encoding";
		else if ([element elementForName: @"unsupported-feature"
				       namespace: XMPP_NS_XMPP_STREAM])
			condition = @"unsupported-feature";
		else if ([element elementForName: @"unsupported-stanza-type"
				       namespace: XMPP_NS_XMPP_STREAM])
			condition = @"unsupported-stanza-type";
		else if ([element elementForName: @"unsupported-version"
				       namespace: XMPP_NS_XMPP_STREAM])
			condition = @"unsupported-version";
		else
			condition = @"undefined";

		reason = [[element
		    elementForName: @"text"
			 namespace: XMPP_NS_XMPP_STREAM] stringValue];

		@throw [XMPPStreamErrorException exceptionWithClass: isa
							 connection: self
							  condition: condition
							     reason: reason];
		return;
	}

	assert(0);
}

- (void)XMPP_handleTLS: (OFXMLElement*)element
{
	if ([[element name] isEqual: @"proceed"]) {
		/* FIXME: Catch errors here */
		SSLSocket *newSock;

		if ([delegate respondsToSelector:
		    @selector(connectionWillUpgradeToTLS:)])
			[delegate connectionWillUpgradeToTLS: self];

		newSock = [[SSLSocket alloc] initWithSocket: sock];
		[sock release];
		sock = newSock;

		encrypted = YES;

		if ([delegate respondsToSelector:
		    @selector(connectionDidUpgradeToTLS:)])
			[delegate connectionDidUpgradeToTLS: self];

		/* Stream restart */
		[self XMPP_startStream];

		return;
	}

	if ([[element name] isEqual: @"failure"])
		/* TODO: Find/create an exception to throw here */
		@throw [OFException exceptionWithClass: isa];

	assert(0);
}

- (void)XMPP_handleSASL: (OFXMLElement*)element
{
	if ([[element name] isEqual: @"challenge"]) {
		OFXMLElement *responseTag;
		OFDataArray *challenge = [OFDataArray
		    dataArrayWithBase64EncodedString: [element stringValue]];
		OFDataArray *response = [authModule
		    continueWithData: challenge];

		responseTag = [OFXMLElement elementWithName: @"response"
						  namespace: XMPP_NS_SASL];
		if (response) {
			if ([response count] == 0)
				[responseTag setStringValue: @"="];
			else
				[responseTag setStringValue:
				    [response stringByBase64Encoding]];
		}

		[self sendStanza: responseTag];
		return;
	}

	if ([[element name] isEqual: @"success"]) {
		[authModule continueWithData: [OFDataArray
		    dataArrayWithBase64EncodedString: [element stringValue]]];

		if ([delegate respondsToSelector:
		    @selector(connectionWasAuthenticated:)])
			[delegate connectionWasAuthenticated: self];

		/* Stream restart */
		[self XMPP_startStream];

		return;
	}

	if ([[element name] isEqual: @"failure"]) {
		of_log(@"Auth failed!");
		// FIXME: Do more parsing/handling
		@throw [XMPPAuthFailedException
		    exceptionWithClass: isa
			    connection: self
				reason: [element XMLString]];
	}

	assert(0);
}

- (void)XMPP_handleIQ: (XMPPIQ*)iq
{
	BOOL handled = NO;

	if ([[iq ID] isEqual: bindID]) {
		[self XMPP_handleResourceBind: iq];
		return;
	}

	if ([[iq ID] isEqual: sessionID]) {
		[self XMPP_handleSession: iq];
		return;
	}

	if ([iq elementForName: @"query"
		     namespace: XMPP_NS_ROSTER])
		if ([roster handleIQ: iq])
			return;

	if ([delegate respondsToSelector: @selector(connection:didReceiveIQ:)])
		handled = [delegate connection: self
				  didReceiveIQ: iq];

	if (!handled && ![[iq type] isEqual: @"error"] &&
	    ![[iq type] isEqual: @"result"]) {
		[self sendStanza: [iq errorIQWithType: @"cancel"
					    condition: @"service-unavailable"]];
	}
}

- (void)XMPP_handleMessage: (XMPPMessage*)message
{
	if ([delegate respondsToSelector:
	     @selector(connection:didReceiveMessage:)])
		[delegate connection: self
		   didReceiveMessage: message];
}

- (void)XMPP_handlePresence: (XMPPPresence*)presence
{
	if ([delegate respondsToSelector:
	     @selector(connection:didReceivePresence:)])
		[delegate connection: self
		  didReceivePresence: presence];
}

- (void)XMPP_handleFeatures: (OFXMLElement*)element
{
	OFXMLElement *starttls = [element elementForName: @"starttls"
					       namespace: XMPP_NS_STARTTLS];
	OFXMLElement *bind = [element elementForName: @"bind"
					   namespace: XMPP_NS_BIND];
	OFXMLElement *session = [element elementForName: @"session"
					      namespace: XMPP_NS_SESSION];
	OFXMLElement *mechs = [element elementForName: @"mechanisms"
					    namespace: XMPP_NS_SASL];
	OFMutableSet *mechanisms = [OFMutableSet set];

	if (starttls != nil) {
		[self sendStanza:
		    [OFXMLElement elementWithName: @"starttls"
					namespace: XMPP_NS_STARTTLS]];
		return;
	}

	if (encryptionRequired && !encrypted)
		/* TODO: Find/create an exception to throw here */
		@throw [OFException exceptionWithClass: isa];

	if (mechs != nil) {
		OFEnumerator *enumerator;
		OFXMLElement *mech;

		enumerator = [[mechs children] objectEnumerator];
		while ((mech = [enumerator nextObject]) != nil)
			[mechanisms addObject: [mech stringValue]];

		if ([mechanisms containsObject: @"SCRAM-SHA-1-PLUS"]) {
			authModule = [[XMPPSCRAMAuth alloc]
			    initWithAuthcid: username
				   password: password
				 connection: self
				       hash: [OFSHA1Hash class]
			      plusAvailable: YES];
			[self XMPP_sendAuth: @"SCRAM-SHA-1-PLUS"];
			return;
		}

		if ([mechanisms containsObject: @"SCRAM-SHA-1"]) {
			authModule = [[XMPPSCRAMAuth alloc]
			    initWithAuthcid: username
				   password: password
				 connection: self
				       hash: [OFSHA1Hash class]
			      plusAvailable: NO];
			[self XMPP_sendAuth: @"SCRAM-SHA-1"];
			return;
		}

		if ([mechanisms containsObject: @"PLAIN"] && encrypted) {
			authModule = [[XMPPPLAINAuth alloc]
			    initWithAuthcid: username
				   password: password];
			[self XMPP_sendAuth: @"PLAIN"];
			return;
		}

		assert(0);
	}

	if (session != nil)
		needsSession = YES;

	if (bind != nil) {
		[self XMPP_sendResourceBind];
		return;
	}

	assert(0);
}

- (void)XMPP_sendAuth: (OFString*)authName
{
	OFXMLElement *authTag;
	OFDataArray *initialMessage = [authModule initialMessage];

	authTag = [OFXMLElement elementWithName: @"auth"
				      namespace: XMPP_NS_SASL];
	[authTag addAttributeWithName: @"mechanism"
			  stringValue: authName];
	if (initialMessage) {
		if ([initialMessage count] == 0)
			[authTag setStringValue: @"="];
		else
			[authTag setStringValue:
			    [initialMessage stringByBase64Encoding]];
	}

	[self sendStanza: authTag];
}

- (void)XMPP_sendResourceBind
{
	XMPPIQ *iq;
	OFXMLElement *bind;

	bindID = [[self generateStanzaID] retain];
	iq = [XMPPIQ IQWithType: @"set"
			     ID: bindID];

	bind = [OFXMLElement elementWithName: @"bind"
				   namespace: XMPP_NS_BIND];

	if (resource != nil)
		[bind addChild: [OFXMLElement elementWithName: @"resource"
						    namespace: XMPP_NS_BIND
						  stringValue: resource]];

	[iq addChild: bind];

	[self sendStanza: iq];
}

- (void)XMPP_handleResourceBind: (XMPPIQ*)iq
{
	OFXMLElement *bindElement;
	OFXMLElement *jidElement;

	assert([[iq type] isEqual: @"result"]);

	bindElement = [iq elementForName: @"bind"
			       namespace: XMPP_NS_BIND];

	assert(bindElement != nil);

	jidElement = [bindElement elementForName: @"jid"
				       namespace: XMPP_NS_BIND];
	JID = [[XMPPJID alloc] initWithString: [jidElement stringValue]];

	[bindID release];
	bindID = nil;

	if (needsSession) {
		[self XMPP_sendSession];
		return;
	}

	if ([delegate respondsToSelector: @selector(connection:wasBoundToJID:)])
		[delegate connection: self
		       wasBoundToJID: JID];
}

- (void)XMPP_sendSession
{
	XMPPIQ *iq;

	sessionID = [[self generateStanzaID] retain];
	iq = [XMPPIQ IQWithType: @"set"
			     ID: sessionID];
	[iq addChild: [OFXMLElement elementWithName: @"session"
					  namespace: XMPP_NS_SESSION]];
	[self sendStanza: iq];
}

- (void)XMPP_handleSession: (XMPPIQ*)iq
{
	if (![[iq type] isEqual: @"result"])
		assert(0);

	if ([delegate respondsToSelector: @selector(connection:wasBoundToJID:)])
		[delegate connection: self
		       wasBoundToJID: JID];

	[sessionID release];
	sessionID = nil;
}

- (XMPPJID*)JID
{
	return [[JID copy] autorelease];
}

- (void)setPort: (uint16_t)port_
{
	port = port_;
}

- (uint16_t)port
{
	return port;
}

- (void)setDelegate: (id <XMPPConnectionDelegate>)delegate_
{
	id old = delegate;
	delegate = [(id)delegate_ retain];
	[old release];
}

- (id <XMPPConnectionDelegate>)delegate
{
	return [[delegate retain] autorelease];
}

- (XMPPRoster*)roster
{
	return [[roster retain] autorelease];
}
@end

@implementation OFObject (XMPPConnectionDelegate)
- (void)connectionWasAuthenticated: (XMPPConnection*)connection
{
}

- (void)connection: (XMPPConnection*)connection
     wasBoundToJID: (XMPPJID*)JID
{
}

- (void)connectionDidReceiveRoster: (XMPPConnection*)connection
{
}

- (BOOL)connection: (XMPPConnection*)connection
      didReceiveIQ: (XMPPIQ*)iq
{
	return NO;
}

-   (void)connection: (XMPPConnection*)connection
  didReceivePresence: (XMPPPresence*)presence
{
}

-  (void)connection: (XMPPConnection*)connection
  didReceiveMessage: (XMPPMessage*)message
{
}

-     (void)connection: (XMPPConnection*)connection
  didReceiveRosterItem: (XMPPRosterItem*)rosterItem
{
}

- (void)connectionWasClosed: (XMPPConnection*)connection
{
}

- (void)connectionWillUpgradeToTLS: (XMPPConnection*)connection
{
}

- (void)connectionDidUpgradeToTLS: (XMPPConnection*)connection
{
}
@end
