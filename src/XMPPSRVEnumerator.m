/*
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
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <resolv.h>
#include <sys/types.h>
#include <openssl/rand.h>
#include <assert.h>

#import "XMPPSRVEnumerator.h"

@implementation XMPPSRVEntry
- (void)dealloc
{
	[target release];

	[super dealloc];
}

- (OFString*)description
{
	return [OFString stringWithFormat: @"priority: %" PRIu16
				@" weight: %" PRIu16
				@" target: %@:%" PRIu16, priority, weight,
				target, port];
}

- (void)setPriority: (uint16_t)priority_
{
	priority = priority_;
}

- (uint16_t)priority
{
	return priority;
}

- (void)setWeight: (uint16_t)weight_
{
	weight = weight_;
}

- (uint16_t)weight
{
	return weight;
}

- (void)setPort: (uint16_t)port_
{
	port = port_;
}

- (uint16_t)port
{
	return port;
}

- (void)setTarget: (OFString*)target_
{
	OFString *old = target;
	target = [target_ copy];
	[old release];
}

- (OFString*)target
{
	return [[target copy] autorelease];
}
@end

@implementation XMPPSRVEnumerator
+ enumeratorWithDomain: (OFString*)domain_
{
	return [[[self alloc] initWithDomain: domain_] autorelease];
}

- initWithDomain: (OFString*)domain_
{
	self = [super init];
	priorityList = [[OFList alloc] init];
	[self setDomain: domain_];

	return self;
}

- (void)dealloc
{
	[priorityList release];
	[domain release];

	[super dealloc];
}

- (void)setDomain: (OFString*)domain_
{
	OFString *old = domain;
	domain = [domain_ copy];
	[old release];
	[self reset];
}

- (OFString*)domain;
{
	return [[domain copy] autorelease];
}

- (void)XMPP_parseSRVRRWithHandle: (const ns_msg)handle
			       RR: (const ns_rr)rr
			   result: (XMPPSRVEntry*)result
{
	const uint16_t *rdata = (uint16_t*) ns_rr_rdata(rr);
	char target[NS_MAXDNAME];
	[result setPriority: ntohs(rdata[0])];
	[result setWeight: ntohs(rdata[1])];
	[result setPort: ntohs(rdata[2])];
	dn_expand(ns_msg_base(handle), ns_msg_end(handle),
			(uint8_t*) &rdata[3], target, NS_MAXDNAME);
	[result setTarget: [OFString stringWithCString: target]];
}

- (id)nextObject
{
	if ([priorityList firstListObject]) {
		uint16_t weight = 0;
		of_list_object_t *iter;
		XMPPSRVEntry *ret;
		OFList *weightList = [priorityList firstObject];
		uint16_t maximumWeight = [[weightList lastObject] weight];

		if (maximumWeight) {
			RAND_pseudo_bytes((unsigned char *)&weight, 2);
			weight %= maximumWeight;
		}

		iter = [weightList firstListObject];
		while (iter) {
			if (weight <= [iter->object weight]) {
				ret = [iter->object retain];
				[weightList removeListObject: iter];
				if (![weightList firstListObject])
					[priorityList removeListObject:
						[priorityList firstListObject]];
				return [ret autorelease];
			}
			iter = iter->next;
		}
		assert(0);
	}

	return nil;
}

- (int)countByEnumeratingWithState: (of_fast_enumeration_state_t*)state
			   objects: (id*)objects
			     count: (int)count
{
	int len = 0;
	XMPPSRVEntry *entry = [self nextObject];
	state->itemsPtr = objects;
	while ((len < count) && entry) {
		state->mutationsPtr = (unsigned long *)self;
		objects[len++] = entry;
		entry = [self nextObject];
	}
	return len;
}

- (void)reset
{
	int i, rrCount;
	unsigned char *answer;
	OFString *request;
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];

	request = [OFString stringWithFormat: @"_xmpp-client._tcp.%@", domain];
	answer = [self allocMemoryWithSize: NS_MAXMSG];

	res_ninit(&_res);
	if (!(res_nsearch(&_res, [request cString], ns_c_in, ns_t_srv, answer,
				NS_MAXMSG) < 0)) {
		ns_rr rr;
		ns_msg handle;

		ns_initparse(answer, NS_MAXMSG, &handle);
		rrCount = ns_msg_count(handle, ns_s_an);
		for (i = 0; i < rrCount ; i++) {
			XMPPSRVEntry *result = [[XMPPSRVEntry alloc] init];
			ns_parserr(&handle, ns_s_an, i, &rr);
			if ((ns_rr_type(rr) != ns_t_srv)
					|| ns_rr_class(rr) != ns_c_in)
				@throw [OFInvalidServerReplyException
					newWithClass: isa];

			[self XMPP_parseSRVRRWithHandle: handle
						     RR: rr
						 result: result];

			[self XMPP_addSRVEntry: result
			  toSortedPriorityList: priorityList];
		}
	}
	[self freeMemory: answer];
	[pool release];


}

- (void)XMPP_addSRVEntry: (XMPPSRVEntry*)item
    toSortedPriorityList: (OFList*)list
{
	of_list_object_t *priorityIter =
		[list firstListObject];
	while (1) {
		if (priorityIter == NULL ||
				[[priorityIter->object firstObject]
					priority] > [item priority]) {
			OFList *newList = [OFList list];
			[newList appendObject: item];
			if (priorityIter)
				[list insertObject: newList
				  beforeListObject: priorityIter];
			else
				[list appendObject: newList];
			break;
		}
		if ([[priorityIter->object firstObject] priority]
				== [item priority]) {
			if ([item weight] == 0)
				[priorityIter->object prependObject: item];
			else {
				[item setWeight: [item weight] +
				    [[priorityIter->object lastObject] weight]];
				[priorityIter->object appendObject: item];
			}
			break;
		}
		priorityIter = priorityIter->next;
	}
}
@end
