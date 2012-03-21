/*
 * Copyright (c) 2011, Jonathan Schleifer <js@webkeks.org>
 * Copyright (c) 2011, Florian Zeitz <florob@babelmonkeys.de>
 *
 * https://webkeks.org/git/?p=objxmpp.git
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

#include <assert.h>

#include <arpa/inet.h>
#include <netdb.h>
#include <sys/types.h>
#include <openssl/rand.h>

#import "XMPPSRVLookup.h"

@implementation XMPPSRVEntry
+ entryWithPriority: (uint16_t)priority
	     weight: (uint16_t)weight
	       port: (uint16_t)port
	     target: (OFString*)target
{
	return [[[self alloc] initWithPriority: priority
					weight: weight
					  port: port
					target: target] autorelease];
}

+ entryWithResourceRecord: (ns_rr)resourceRecord
		   handle: (ns_msg)handle
{
	return [[[self alloc] initWithResourceRecord: resourceRecord
					      handle: handle] autorelease];
}

- init
{
	Class c = isa;
	[self release];
	@throw [OFNotImplementedException exceptionWithClass: c
						    selector: _cmd];
}

- initWithPriority: (uint16_t)priority_
	    weight: (uint16_t)weight_
	      port: (uint16_t)port_
	    target: (OFString*)target_
{
	self = [super init];

	@try {
		priority = priority_;
		weight = weight_;
		port = port_;
		target = [target_ copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- initWithResourceRecord: (ns_rr)resourceRecord
		  handle: (ns_msg)handle
{
	self = [super init];

	@try {
		const uint16_t *rdata;
		char buffer[NS_MAXDNAME];

		rdata = (const uint16_t*)(void*)ns_rr_rdata(resourceRecord);
		priority = ntohs(rdata[0]);
		weight = ntohs(rdata[1]);
		port = ntohs(rdata[2]);

		if (dn_expand(ns_msg_base(handle), ns_msg_end(handle),
		    (uint8_t*)&rdata[3], buffer, NS_MAXDNAME) < 1)
			@throw [OFInitializationFailedException
			    exceptionWithClass: isa];

		target = [[OFString alloc]
		    initWithCString: buffer
			   encoding: OF_STRING_ENCODING_NATIVE];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[target release];

	[super dealloc];
}

- (OFString*)description
{
	return [OFString stringWithFormat: @"<%@ priority: %" PRIu16
					   @", weight: %" PRIu16
					   @", target: %@:%" PRIu16 @">",
					   isa, priority, weight, target, port];
}

- (uint16_t)priority
{
	return priority;
}

- (uint16_t)weight
{
	return weight;
}

- (void)setAccumulatedWeight: (uint32_t)accumulatedWeight_
{
	accumulatedWeight = accumulatedWeight_;
}

- (uint32_t)accumulatedWeight
{
	return accumulatedWeight;
}

- (uint16_t)port
{
	return port;
}

- (OFString*)target
{
	OF_GETTER(target, YES)
}
@end

@implementation XMPPSRVLookup
+ lookupWithDomain: (OFString*)domain
{
	return [[[self alloc] initWithDomain: domain] autorelease];
}

- initWithDomain: (OFString*)domain_
{
	self = [super init];

	@try {
		list = [[OFList alloc] init];
		domain = [domain_ copy];

		[self XMPP_lookup];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[list release];
	[domain release];

	[super dealloc];
}

- (OFString*)domain;
{
	OF_GETTER(domain, YES)
}

- (void)XMPP_lookup
{
	OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
	unsigned char *answer = NULL;
	OFString *request;

	request = [OFString stringWithFormat: @"_xmpp-client._tcp.%@", domain];

	@try {
		int answerLen, resourceRecordCount, i;
		ns_rr resourceRecord;
		ns_msg handle;

		if (res_ninit(&resState))
			@throw [OFAddressTranslationFailedException
			    exceptionWithClass: isa
					socket: nil
					  host: domain];

		answer = [self allocMemoryWithSize: of_pagesize];
		answerLen = res_nsearch(&resState, [request cStringWithEncoding:
		    OF_STRING_ENCODING_NATIVE], ns_c_in, ns_t_srv, answer,
		    (int)of_pagesize);

		if ((answerLen == -1) && ((h_errno == HOST_NOT_FOUND) ||
		    (h_errno == NO_DATA)))
			return;

		if (answerLen < 1 || answerLen > of_pagesize) {
			@throw [OFAddressTranslationFailedException
			    exceptionWithClass: isa
					socket: nil
					  host: domain];
		}

		if (ns_initparse(answer, answerLen, &handle))
			@throw [OFAddressTranslationFailedException
			    exceptionWithClass: isa
					socket: nil
					  host: domain];

		resourceRecordCount = ns_msg_count(handle, ns_s_an);
		for (i = 0; i < resourceRecordCount; i++) {
			if (ns_parserr(&handle, ns_s_an, i, &resourceRecord))
				continue;

			if (ns_rr_type(resourceRecord) != ns_t_srv ||
			    ns_rr_class(resourceRecord) != ns_c_in)
				continue;

			[self XMPP_addEntry: [XMPPSRVEntry
			    entryWithResourceRecord: resourceRecord
					     handle: handle]];
		}
	} @finally {
		[self freeMemory: answer];
#ifdef HAVE_RES_NDESTROY
		res_ndestroy(&resState);
#endif
	}

	[pool release];
}

- (void)XMPP_addEntry: (XMPPSRVEntry*)entry
{
	OFAutoreleasePool *pool;
	OFList *subList;
	of_list_object_t *iter;

	/* Look if there already is a list with the priority */
	for (iter = [list firstListObject]; iter != NULL; iter = iter->next) {
		if ([[iter->object firstObject] priority] == [entry priority]) {
			/*
			 * RFC 2782 says those with weight 0 should be at the
			 * beginning of the list.
			 */
			if ([entry weight] > 0)
				[iter->object appendObject: entry];
			else
				[iter->object prependObject: entry];

			return;
		}

		/* We can't have one if the priority is already bigger */
		if ([[iter->object firstObject] priority] > [entry priority])
			break;
	}

	pool = [[OFAutoreleasePool alloc] init];

	subList = [OFList list];
	[subList appendObject: entry];

	if (iter != NULL)
		[list insertObject: subList
		  beforeListObject: iter];
	else
		[list appendObject: subList];

	[pool release];
}

- (OFEnumerator*)objectEnumerator
{
	return [[[XMPPSRVEnumerator alloc] initWithList: list] autorelease];
}
@end

@implementation XMPPSRVEnumerator
- initWithList: (OFList*)list_
{
	self = [super init];

	@try {
		list = [list_ copy];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (id)nextObject
{
	XMPPSRVEntry *ret = nil;
	of_list_object_t *iter;
	uint32_t totalWeight = 0;

	if (done)
		return nil;

	if (listIter == NULL)
		listIter = [list firstListObject];

	if (listIter == NULL)
		return nil;

	if (subListCopy == nil)
		subListCopy = [listIter->object copy];

	for (iter = [subListCopy firstListObject]; iter != NULL;
	     iter = iter->next) {
		totalWeight += [iter->object weight];
		[iter->object setAccumulatedWeight: totalWeight];
	}

	if ([subListCopy count] > 0)  {
		uint32_t randomWeight;

		RAND_pseudo_bytes((uint8_t*)&randomWeight, sizeof(uint32_t));
		randomWeight %= (totalWeight + 1);

		for (iter = [subListCopy firstListObject]; iter != NULL;
		     iter = iter->next) {
			if ([iter->object accumulatedWeight] >= randomWeight) {
				ret = [[iter->object retain] autorelease];

				[subListCopy removeListObject: iter];

				break;
			}
		}
	}

	if ([subListCopy count] == 0) {
		[subListCopy release];
		subListCopy = nil;

		listIter = listIter->next;

		if (listIter == NULL)
			done = YES;
	}

	return ret;
}

- (void)reset
{
	listIter = NULL;
	[subListCopy release];
	subListCopy = nil;
	done = NO;
}
@end
