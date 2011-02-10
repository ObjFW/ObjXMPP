#import <ObjFW/ObjFW.h>

@interface XMPPStanza: OFXMLElement
{
	OFString *from;
	OFString *to;
	OFString *type;
	OFString *ID;
}

@property (copy) OFString *from;
@property (copy) OFString *to;
@property (copy) OFString *type;
@property (copy) OFString *ID;

+ stanzaWithName: (OFString*)name;
+ stanzaWithElement: (OFXMLElement*)elem;

- initWithName: (OFString*)name;
- initWithElement: (OFXMLElement*)elem;
@end

@interface XMPPIQ: XMPPStanza
{
}

+ IQWithType: (OFString*)type_
	  ID: (OFString*)ID_;
@end

@interface XMPPMessage: XMPPStanza
{
}

+ message;
+ messageWithID: (OFString*)ID_;
+ messageWithType: (OFString*)type_;
+ messageWithType: (OFString*)type_
	       ID: (OFString*)ID_;

- (void)addBody: (OFString*)body;
@end

@interface XMPPPresence: XMPPStanza
{
}

+ presence;
+ presenceWithID: (OFString*)ID_;
+ presenceWithType: (OFString*)type_;
+ presenceWithType: (OFString*)type_
		ID: (OFString*)ID_;

- (void)addShow: (OFString*)show;
- (void)addStatus: (OFString*)status;
- (void)addPriority: (int8_t)priority;
@end
