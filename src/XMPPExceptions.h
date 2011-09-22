/*
 * Copyright (c) 2011, Jonathan Schleifer <js@webkeks.org>
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

#import <ObjFW/ObjFW.h>

@class XMPPConnection;
@class XMPPAuthenticator;

@interface XMPPException: OFException
{
	XMPPConnection *connection;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, nonatomic) XMPPConnection *connection;
#endif

+ exceptionWithClass: (Class)class_
	  connection: (XMPPConnection*)conn;
- initWithClass: (Class)class_
     connection: (XMPPConnection*)conn;
- (XMPPConnection*)connection;
@end

@interface XMPPStreamErrorException: XMPPException
{
	OFString *condition;
	OFString *reason;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, nonatomic) OFString *condition;
@property (readonly, nonatomic) OFString *reason;
#endif

+ exceptionWithClass: (Class)class_
	  connection: (XMPPConnection*)conn
     condition: (OFString*)condition_
	reason: (OFString*)reason_;
- initWithClass: (Class)class_
     connection: (XMPPConnection*)conn
      condition: (OFString*)condition_
	 reason: (OFString*)reason_;
- (OFString*)condition;
- (OFString*)reason;
@end

@interface XMPPStringPrepFailedException: XMPPException
{
	OFString *profile;
	OFString *string;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, nonatomic) OFString *profile, *string;
#endif

+ exceptionWithClass: (Class)class_
	  connection: (XMPPConnection*)conn
	     profile: (OFString*)profile
	      string: (OFString*)string;
- initWithClass: (Class)class_
     connection: (XMPPConnection*)conn
	profile: (OFString*)profile
	 string: (OFString*)string;
- (OFString*)profile;
- (OFString*)string;
@end

@interface XMPPIDNATranslationFailedException: XMPPException
{
	OFString *operation;
	OFString *string;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, nonatomic) OFString *operation, *string;
#endif

+ exceptionWithClass: (Class)class_
	  connection: (XMPPConnection*)conn
	   operation: (OFString*)operation
	      string: (OFString*)string;
- initWithClass: (Class)class_
     connection: (XMPPConnection*)conn
      operation: (OFString*)operation
	 string: (OFString*)string;
- (OFString*)operation;
- (OFString*)string;
@end

@interface XMPPAuthFailedException: XMPPException
{
	OFString *reason;
}

#ifdef OF_HAVE_PROPERTIES
@property (readonly, nonatomic) OFString *reason;
#endif

+ exceptionWithClass: (Class)class_
	  connection: (XMPPConnection*)conn
	      reason: (OFString*)reason_;
- initWithClass: (Class)class_
     connection: (XMPPConnection*)conn
	 reason: (OFString*)reason_;
- (OFString*)reason;
@end
