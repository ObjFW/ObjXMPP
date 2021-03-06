/*
 * Copyright (c) 2011, 2012, 2013, 2016, Jonathan Schleifer <js@nil.im>
 * Copyright (c) 2011, 2012, Florian Zeitz <florob@babelmonkeys.de>
 *
 * https://nil.im/objxmpp/
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

OF_ASSUME_NONNULL_BEGIN

@class XMPPConnection;
@class XMPPAuthenticator;

/*!
 * @brief A base class for XMPP related exceptions
 */
@interface XMPPException: OFException
{
	XMPPConnection *_connection;
}

/*!
 * The connection the exception relates to.
 */
@property OF_NULLABLE_PROPERTY (readonly, nonatomic) XMPPConnection *connection;

/*!
 * @brief Creates a new XMPPException.
 *
 * @param connection The connection that received the data responsible
 *	  for this exception
 * @return A new XMPPException
 */
+ (instancetype)exceptionWithConnection: (nullable XMPPConnection *)connection;

- (instancetype)init OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated XMPPException.
 *
 * @param connection The connection that received the data responsible
 *	  for this exception
 * @return An initialized XMPPException
 */
- (instancetype)initWithConnection: (nullable XMPPConnection *)connection
    OF_DESIGNATED_INITIALIZER;
@end

/*!
 * @brief An exception indicating a stream error was received
 */
@interface XMPPStreamErrorException: XMPPException
{
	OFString *_condition, *_reason;
}

/*!
 * @brief The defined error condition specified by the stream error.
 */
@property (readonly, nonatomic) OFString *condition;

/*!
 * @brief The descriptive free-form text specified by the stream error.
 */
@property (readonly, nonatomic) OFString *reason;

/*!
 * @brief Creates a new XMPPStreamErrorException.
 *
 * @param connection The connection that received the stream error
 * @param condition The defined error condition specified by the stream error
 * @param reason The descriptive free-form text specified by the stream error
 * @return A new XMPPStreamErrorException
 */
+ (instancetype)exceptionWithConnection: (nullable XMPPConnection *)connection
			      condition: (OFString *)condition
				 reason: (OFString *)reason;

- (instancetype)initWithConnection: (nullable XMPPConnection *)connection
    OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated XMPPStreamErrorException.
 *
 * @param connection The connection that received the stream error
 * @param condition The defined error condition specified by the stream error
 * @param reason The descriptive free-form text specified by the stream error
 * @return An initialized XMPPStreamErrorException
 */
- (instancetype)initWithConnection: (nullable XMPPConnection *)connection
			 condition: (OFString *)condition
			    reason: (OFString *)reason
    OF_DESIGNATED_INITIALIZER;
@end

/*!
 * @brief An exception indicating a stringprep profile
 *	  did not apply to a string
 */
@interface XMPPStringPrepFailedException: XMPPException
{
	OFString *_profile, *_string;
}

/*!
 * @brief The name of the stringprep profile that did not apply.
 */
@property (readonly, nonatomic) OFString *profile;

/*!
 * @brief The string that failed the stringprep profile.
 */
@property (readonly, nonatomic) OFString *string;

/*!
 * @brief Creates a new XMPPStringPrepFailedException.
 *
 * @param connection The connection the string relates to
 * @param profile The name of the stringprep profile that did not apply
 * @param string The string that failed the stringprep profile
 * @return A new XMPPStringPrepFailedException
 */
+ (instancetype)exceptionWithConnection: (nullable XMPPConnection *)connection
				profile: (OFString *)profile
				 string: (OFString *)string;

- (instancetype)initWithConnection: (nullable XMPPConnection *)connection
    OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated XMPPStringPrepFailedException.
 *
 * @param connection The connection the string relates to
 * @param profile The name of the stringprep profile that did not apply
 * @param string The string that failed the stringprep profile
 * @return An initialized XMPPStringPrepFailedException
 */
- (instancetype)initWithConnection: (nullable XMPPConnection *)connection
			   profile: (OFString *)profile
			    string: (OFString *)string
    OF_DESIGNATED_INITIALIZER;
@end

/*!
 * @brief An exception indicating IDNA translation of a string failed
 */
@interface XMPPIDNATranslationFailedException: XMPPException
{
	OFString *_operation, *_string;
}

/*!
 * @brief The IDNA translation operation which failed.
 */
@property (readonly, nonatomic) OFString *operation;

/*!
 * @brief The string that could not be translated.
 */
@property (readonly, nonatomic) OFString *string;

/*!
 * @brief Creates a new XMPPIDNATranslationFailedException.
 *
 * @param connection The connection the string relates to
 * @param operation The name of the stringprep profile that did not apply
 * @param string The string that could not be translated
 * @return A new XMPPIDNATranslationFailedException
 */
+ (instancetype)exceptionWithConnection: (nullable XMPPConnection *)connection
			      operation: (OFString *)operation
				 string: (OFString *)string;

- (instancetype)initWithConnection: (nullable XMPPConnection *)connection
    OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated XMPPIDNATranslationFailedException.
 *
 * @param connection The connection the string relates to
 * @param operation The name of the stringprep profile that did not apply
 * @param string The string that could not be translated
 * @return An initialized XMPPIDNATranslationFailedException
 */
- (instancetype)initWithConnection: (nullable XMPPConnection *)connection
			 operation: (OFString *)operation
			    string: (OFString *)string;
@end

/*!
 * @brief An exception indicating authentication failed
 */
@interface XMPPAuthFailedException: XMPPException
{
	OFString *_reason;
}

/*!
 * The reason the authentication failed.
 */
@property (readonly, nonatomic) OFString *reason;

/*!
 * @brief Creates a new XMPPAuthFailedException.
 *
 * @param connection The connection that could not be authenticated
 * @param reason The reason the authentication failed
 * @return A new XMPPAuthFailedException
 */
+ (instancetype)exceptionWithConnection: (nullable XMPPConnection *)connection
				 reason: (OFString *)reason;

- (instancetype)initWithConnection: (nullable XMPPConnection *)connection
    OF_UNAVAILABLE;

/*!
 * @brief Initializes an already allocated XMPPAuthFailedException.
 *
 * @param connection The connection that could not be authenticated
 * @param reason The reason the authentication failed
 * @return An initialized XMPPAuthFailedException
 */
- (instancetype)initWithConnection: (nullable XMPPConnection *)connection
			    reason: (OFString *)reason
    OF_DESIGNATED_INITIALIZER;
@end

OF_ASSUME_NONNULL_END
