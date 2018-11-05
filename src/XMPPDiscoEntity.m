/*
 * Copyright (c) 2013, Florian Zeitz <florob@babelmonkeys.de>
 * Copyright (c) 2013, 2016, Jonathan Schleifer <js@heap.zone>
 *
 * https://heap.zone/objxmpp/
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

#import "XMPPDiscoEntity.h"
#import "XMPPDiscoNode.h"
#import "XMPPDiscoNode+Private.h"
#import "XMPPDiscoIdentity.h"
#import "XMPPIQ.h"
#import "namespaces.h"

@implementation XMPPDiscoEntity
@synthesize discoNodes = _discoNodes, capsNode = _capsNode;

+ (instancetype)discoEntityWithConnection: (XMPPConnection *)connection
{
	return [[[self alloc] initWithConnection: connection] autorelease];
}

+ (instancetype)discoEntityWithConnection: (XMPPConnection *)connection
				 capsNode: (OFString *)capsNode
{
	return [[[self alloc] initWithConnection: connection
					capsNode: capsNode] autorelease];
}

- (instancetype)initWithConnection: (XMPPConnection *)connection
{
	return [self initWithConnection: connection
			       capsNode: nil];
}

- (instancetype)initWithJID: (XMPPJID *)JID
		       node: (nullable OFString *)node
		       name: (nullable OFString *)name
{
	OF_INVALID_INIT_METHOD
}

- (instancetype)initWithConnection: (XMPPConnection *)connection
			  capsNode: (OFString *)capsNode
{
	self = [super initWithJID: [connection JID]
			     node: nil
			     name: nil];

	@try {
		_discoNodes = [[OFMutableDictionary alloc] init];
		_connection = connection;
		_capsNode = [capsNode copy];

		[_connection addDelegate: self];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_connection removeDelegate: self];
	[_discoNodes release];

	[super dealloc];
}

- (void)addDiscoNode: (XMPPDiscoNode *)node
{
	[_discoNodes setObject: node
			forKey: [node node]];
}

- (OFString *)capsHash
{
	OFMutableString *caps = [OFMutableString string];
	OFSHA1Hash *hash = [OFSHA1Hash cryptoHash];
	OFData *digest;

	for (XMPPDiscoIdentity *identity in _identities)
		[caps appendFormat: @"%@/%@//%@<", [identity category],
		    [identity type], [identity name]];

	for (OFString *feature in _features)
		[caps appendFormat: @"%@<", feature];

	[hash updateWithBuffer: [caps UTF8String]
			length: [caps UTF8StringLength]];

	digest = [OFData dataWithItems: [hash digest]
				 count: [[hash class] digestSize]];

	return [digest stringByBase64Encoding];
}

- (void)connection: (XMPPConnection *)connection
     wasBoundToJID: (XMPPJID *)JID
{
	_JID = [JID copy];
}

- (bool)connection: (XMPPConnection *)connection
      didReceiveIQ: (XMPPIQ *)IQ
{
	if (![[IQ to] isEqual: _JID])
		return false;

	OFXMLElement *query = [IQ elementForName: @"query"
				       namespace: XMPP_NS_DISCO_ITEMS];

	if (query != nil) {
		OFString *node =
		    [[query attributeForName: @"node"] stringValue];
		if (node == nil)
			return [self xmpp_handleItemsIQ: IQ
					     connection: connection];

		XMPPDiscoNode *responder = [_discoNodes objectForKey: node];
		if (responder != nil)
			return [responder xmpp_handleItemsIQ: IQ
						  connection: connection];

		return false;
	}

	query = [IQ elementForName: @"query"
			 namespace: XMPP_NS_DISCO_INFO];

	if (query != nil) {
		OFString *node =
		    [[query attributeForName: @"node"] stringValue];

		if (node == nil)
			return [self xmpp_handleInfoIQ: IQ
					    connection: connection];

		OFString *capsNode = [_capsNode stringByAppendingFormat: @"#%@",
					 [self capsHash]];
		if ([capsNode isEqual: node])
			return [self xmpp_handleInfoIQ: IQ
					    connection: connection];

		XMPPDiscoNode *responder = [_discoNodes objectForKey: node];
		if (responder != nil)
			return [responder xmpp_handleInfoIQ: IQ
						 connection: connection];

		return false;
	}

	return false;
}
@end
