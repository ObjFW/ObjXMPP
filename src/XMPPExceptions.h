/*
 * Copyright (c) 2011, Jonathan Schleifer <js@webkeks.org>
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

#import <ObjFW/ObjFW.h>

@class XMPPConnection;
@class XMPPAuthenticator;

/**
 * \brief A base class for XMPP related exceptions
 */
@interface XMPPException: OFException
{
	XMPPConnection *_connection;
}

#ifdef OF_HAVE_PROPERTIES
/// \brief The connection the exception relates to
@property (readonly, assign) XMPPConnection *connection;
#endif

/**
 * \brief Creates a new XMPPException.
 *
 * \param connection The connection that received the data responsible
 *	  for this exception
 * \return A new XMPPException
 */
+ exceptionWithConnection: (XMPPConnection*)connection;

/**
 * \brief Initializes an already allocated XMPPException.
 *
 * \param connection The connection that received the data responsible
 *	  for this exception
 * \return An initialized XMPPException
 */
- initWithConnection: (XMPPConnection*)connection;

- (XMPPConnection*)connection;
@end

/**
 * \brief An exception indicating a stream error was received
 */
@interface XMPPStreamErrorException: XMPPException
{
	OFString *_condition, *_reason;
}

#ifdef OF_HAVE_PROPERTIES
/// \brief The defined error condition specified by the stream error
@property (readonly, assign) OFString *condition;
/// \brief The descriptive free-form text specified by the stream error
@property (readonly, assign) OFString *reason;
#endif

/**
 * \brief Creates a new XMPPStreamErrorException.
 *
 * \param connection The connection that received the stream error
 * \param condition The defined error condition specified by the stream error
 * \param reason The descriptive free-form text specified by the stream error
 * \return A new XMPPStreamErrorException
 */
+ exceptionWithConnection: (XMPPConnection*)connection
		condition: (OFString*)condition
		   reason: (OFString*)reason;

/**
 * \brief Initializes an already allocated XMPPStreamErrorException.
 *
 * \param connection The connection that received the stream error
 * \param condition The defined error condition specified by the stream error
 * \param reason The descriptive free-form text specified by the stream error
 * \return An initialized XMPPStreamErrorException
 */
- initWithConnection: (XMPPConnection*)connection
	   condition: (OFString*)condition
	      reason: (OFString*)reason;

- (OFString*)condition;
- (OFString*)reason;
@end

/**
 * \brief An exception indicating a stringprep profile
 *	  did not apply to a string
 */
@interface XMPPStringPrepFailedException: XMPPException
{
	OFString *_profile, *_string;
}

#ifdef OF_HAVE_PROPERTIES
/// \brief The name of the stringprep profile that did not apply
@property (readonly, assign) OFString *profile;
/// \brief The string that failed the stringprep profile
@property (readonly, assign) OFString *string;
#endif

/**
 * \brief Creates a new XMPPStringPrepFailedException.
 *
 * \param connection The connection the string relates to
 * \param profile The name of the stringprep profile that did not apply
 * \param string The string that failed the stringprep profile
 * \return A new XMPPStringPrepFailedException
 */
+ exceptionWithConnection: (XMPPConnection*)connection
		  profile: (OFString*)profile
		   string: (OFString*)string;

/**
 * \brief Initializes an already allocated XMPPStringPrepFailedException.
 *
 * \param connection The connection the string relates to
 * \param profile The name of the stringprep profile that did not apply
 * \param string The string that failed the stringprep profile
 * \return An initialized XMPPStringPrepFailedException
 */
- initWithConnection: (XMPPConnection*)connection
	     profile: (OFString*)profile
	      string: (OFString*)string;

- (OFString*)profile;
- (OFString*)string;
@end

/**
 * \brief An exception indicating IDNA translation of a string failed
 */
@interface XMPPIDNATranslationFailedException: XMPPException
{
	OFString *_operation, *_string;
}

#ifdef OF_HAVE_PROPERTIES
/// \brief The IDNA translation operation which failed
@property (readonly, assign) OFString *operation;
/// \brief The string that could not be translated
@property (readonly, assign) OFString *string;
#endif

/**
 * \brief Creates a new XMPPIDNATranslationFailedException.
 *
 * \param connection The connection the string relates to
 * \param operation The name of the stringprep profile that did not apply
 * \param string The string that could not be translated
 * \return A new XMPPIDNATranslationFailedException
 */
+ exceptionWithConnection: (XMPPConnection*)connection
		operation: (OFString*)operation
		   string: (OFString*)string;

/**
 * \brief Initializes an already allocated XMPPIDNATranslationFailedException.
 *
 * \param connection The connection the string relates to
 * \param operation The name of the stringprep profile that did not apply
 * \param string The string that could not be translated
 * \return An initialized XMPPIDNATranslationFailedException
 */
- initWithConnection: (XMPPConnection*)connection
	   operation: (OFString*)operation
	      string: (OFString*)string;

- (OFString*)operation;
- (OFString*)string;
@end

/**
 * \brief An exception indicating authentication failed
 */
@interface XMPPAuthFailedException: XMPPException
{
	OFString *_reason;
}

#ifdef OF_HAVE_PROPERTIES
/// \brief The reason the authentication failed
@property (readonly, assign) OFString *reason;
#endif

/**
 * \brief Creates a new XMPPAuthFailedException.
 *
 * \param connection The connection that could not be authenticated
 * \param reason The reason the authentication failed
 * \return A new XMPPAuthFailedException
 */
+ exceptionWithConnection: (XMPPConnection*)connection
		   reason: (OFString*)reason;

/**
 * \brief Initializes an already allocated XMPPAuthFailedException.
 *
 * \param connection The connection that could not be authenticated
 * \param reason The reason the authentication failed
 * \return An initialized XMPPAuthFailedException
 */
- initWithConnection: (XMPPConnection*)connection
	      reason: (OFString*)reason;

- (OFString*)reason;
@end
