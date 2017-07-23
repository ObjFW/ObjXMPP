/*
 * Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016
 *     Jonathan Schleifer <js@heap.zone>
 * Copyright (c) 2011, 2012, 2013, 2014, Florian Zeitz <florob@babelmonkeys.de>
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

#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#include <inttypes.h>
#include <stdlib.h>

#include <assert.h>

#include <arpa/inet.h>
#include <netdb.h>
#include <sys/types.h>
#include <openssl/rand.h>

#import "XMPPSRVLookup.h"

#import <ObjFW/OFLocalization.h>

OF_ASSUME_NONNULL_BEGIN

@interface XMPPSRVLookup ()
- (void)XMPP_lookup;
- (void)XMPP_addEntry: (XMPPSRVEntry *)item;
@end

OF_ASSUME_NONNULL_END

@implementation XMPPSRVEntry
@synthesize priority = _priority, weight = _weight;
@synthesize accumulatedWeight = _accumulatedWeight, port = _port;
@synthesize target = _target;

+ (instancetype)entryWithPriority: (uint16_t)priority
			   weight: (uint16_t)weight
			     port: (uint16_t)port
			   target: (OFString *)target
{
	return [[[self alloc] initWithPriority: priority
					weight: weight
					  port: port
					target: target] autorelease];
}

+ (instancetype)entryWithResourceRecord: (ns_rr)resourceRecord
				 handle: (ns_msg)handle
{
	return [[[self alloc] initWithResourceRecord: resourceRecord
					      handle: handle] autorelease];
}

- init
{
	OF_INVALID_INIT_METHOD
}

- initWithPriority: (uint16_t)priority
	    weight: (uint16_t)weight
	      port: (uint16_t)port
	    target: (OFString *)target
{
	self = [super init];

	@try {
		_priority = priority;
		_weight = weight;
		_port = port;
		_target = [target copy];
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

		rdata = (const uint16_t *)(void *)ns_rr_rdata(resourceRecord);
		_priority = ntohs(rdata[0]);
		_weight = ntohs(rdata[1]);
		_port = ntohs(rdata[2]);

		if (dn_expand(ns_msg_base(handle), ns_msg_end(handle),
		    (uint8_t *)&rdata[3], buffer, NS_MAXDNAME) < 1)
			@throw [OFInitializationFailedException
			    exceptionWithClass: [self class]];

		_target = [[OFString alloc]
		    initWithCString: buffer
			   encoding: [OFLocalization encoding]];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_target release];

	[super dealloc];
}

- (OFString *)description
{
	return [OFString stringWithFormat:
	    @"<%@ priority: %" PRIu16 @", weight: %" PRIu16 @", target: %@:%"
	    PRIu16 @">", [self class], _priority, _weight, _target, _port];
}
@end

@implementation XMPPSRVLookup
@synthesize domain = _domain;

+ (instancetype)lookupWithDomain: (OFString *)domain
{
	return [[[self alloc] initWithDomain: domain] autorelease];
}

- init
{
	OF_INVALID_INIT_METHOD
}

- initWithDomain: (OFString *)domain
{
	self = [super init];

	@try {
		_list = [[OFList alloc] init];
		_domain = [domain copy];

		[self XMPP_lookup];
	} @catch (id e) {
		[self release];
		@throw e;
	}

	return self;
}

- (void)dealloc
{
	[_list release];
	[_domain release];

	[super dealloc];
}

- (void)XMPP_lookup
{
	void *pool = objc_autoreleasePoolPush();
	unsigned char *answer = NULL;
	size_t pageSize = [OFSystemInfo pageSize];
	OFString *request;

	request = [OFString stringWithFormat: @"_xmpp-client._tcp.%@", _domain];

	@try {
		int answerLen, resourceRecordCount, i;
		ns_rr resourceRecord;
		ns_msg handle;

		if (res_ninit(&_resState))
			@throw [OFAddressTranslationFailedException
			    exceptionWithHost: _domain];

		answer = [self allocMemoryWithSize: pageSize];
		answerLen = res_nsearch(&_resState, [request
		    cStringWithEncoding: [OFLocalization encoding]],
		    ns_c_in, ns_t_srv, answer, (int)pageSize);

		if ((answerLen == -1) && ((h_errno == HOST_NOT_FOUND) ||
		    (h_errno == NO_DATA)))
			return;

		if (answerLen < 1 || answerLen > pageSize)
			@throw [OFAddressTranslationFailedException
			    exceptionWithHost: _domain];

		if (ns_initparse(answer, answerLen, &handle))
			@throw [OFAddressTranslationFailedException
			    exceptionWithHost: _domain];

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
		res_ndestroy(&_resState);
#endif
	}

	objc_autoreleasePoolPop(pool);
}

- (void)XMPP_addEntry: (XMPPSRVEntry *)entry
{
	void *pool = objc_autoreleasePoolPush();
	OFList *subList;
	of_list_object_t *iter;

	/* Look if there already is a list with the priority */
	for (iter = [_list firstListObject]; iter != NULL; iter = iter->next) {
		XMPPSRVEntry *first = [iter->object firstObject];

		if ([first priority] == [entry priority]) {
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
		if ([first priority] > [entry priority])
			break;
	}

	subList = [OFList list];
	[subList appendObject: entry];

	if (iter != NULL)
		[_list insertObject: subList
		   beforeListObject: iter];
	else
		[_list appendObject: subList];

	objc_autoreleasePoolPop(pool);
}

- (OFEnumerator *)objectEnumerator
{
	return [[[XMPPSRVEnumerator alloc] initWithList: _list] autorelease];
}
@end

@implementation XMPPSRVEnumerator
- init
{
	OF_INVALID_INIT_METHOD
}

- initWithList: (OFList *)list
{
	self = [super init];

	@try {
		_list = [list copy];
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

	if (_done)
		return nil;

	if (_listIter == NULL)
		_listIter = [_list firstListObject];

	if (_listIter == NULL)
		return nil;

	if (_subListCopy == nil)
		_subListCopy = [_listIter->object copy];

	for (iter = [_subListCopy firstListObject]; iter != NULL;
	     iter = iter->next) {
		totalWeight += [iter->object weight];
		[iter->object setAccumulatedWeight: totalWeight];
	}

	if ([_subListCopy count] > 0)  {
		uint32_t randomWeight;

		RAND_pseudo_bytes((uint8_t *)&randomWeight, sizeof(uint32_t));
		randomWeight %= (totalWeight + 1);

		for (iter = [_subListCopy firstListObject]; iter != NULL;
		     iter = iter->next) {
			if ([iter->object accumulatedWeight] >= randomWeight) {
				ret = [[iter->object retain] autorelease];

				[_subListCopy removeListObject: iter];

				break;
			}
		}
	}

	if ([_subListCopy count] == 0) {
		[_subListCopy release];
		_subListCopy = nil;

		_listIter = _listIter->next;

		if (_listIter == NULL)
			_done = true;
	}

	return ret;
}

- (void)reset
{
	_listIter = NULL;
	[_subListCopy release];
	_subListCopy = nil;
	_done = false;
}
@end
