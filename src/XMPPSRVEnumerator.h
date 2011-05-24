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

#include <arpa/nameser.h>
#import <ObjFW/ObjFW.h>

@interface XMPPSRVEntry: OFObject
{
	uint16_t priority;
	uint16_t weight;
	uint16_t port;
	OFString *target;
}
#ifdef OF_HAVE_PROPERTIES
@property uint16_t priority;
@property uint16_t weight;
@property uint16_t port;
@property (copy) OFString *target;
#endif

- (void) setPriority: (uint16_t)priority_;
- (uint16_t) priority;
- (void) setWeight: (uint16_t)weight_;
- (uint16_t) weight;
- (void) setPort: (uint16_t)port_;
- (uint16_t) port;
- (void) setTarget: (OFString*)target_;
- (OFString*) target;
@end

@interface XMPPSRVEnumerator: OFEnumerator <OFFastEnumeration>
{
	OFString *domain;
	OFList *priorityList;
}
#ifdef OF_HAVE_PROPERTIES
@property (copy) OFString *domain;
#endif

+ enumeratorWithDomain: (OFString*)domain;

- initWithDomain: (OFString*)domain;
- (void) setDomain: (OFString*)domain;
- (OFString*) domain;
- (void)XMPP_parseSRVRRWithHandle: (const ns_msg)handle
			       RR: (const ns_rr)rr
			   result: (XMPPSRVEntry*)result;
- (void)XMPP_addSRVEntry: (XMPPSRVEntry*)item
    toSortedPriorityList: (OFList*)list;
@end
