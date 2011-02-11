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
+ stanzaWithName: (OFString*)name
	    type: (OFString*)type_;
+ stanzaWithName: (OFString*)name
	      ID: (OFString*)ID_;
+ stanzaWithName: (OFString*)name
	    type: (OFString*)type_
	      ID: (OFString*)ID_;
+ stanzaWithElement: (OFXMLElement*)elem;

- initWithName: (OFString*)name;
- initWithName: (OFString*)name
	    type: (OFString*)type_;
- initWithName: (OFString*)name
	      ID: (OFString*)ID_;
- initWithName: (OFString*)name
	    type: (OFString*)type_
	      ID: (OFString*)ID_;
- initWithElement: (OFXMLElement*)elem;
@end

@interface XMPPIQ: XMPPStanza
{
}

+ IQWithType: (OFString*)type_
	  ID: (OFString*)ID_;

- initWithType: (OFString*)type_
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

- init;
- initWithID: (OFString*)ID_;
- initWithType: (OFString*)type_;
- initWithType: (OFString*)type_
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

- init;
- initWithID: (OFString*)ID_;
- initWithType: (OFString*)type_;
- initWithType: (OFString*)type_
	    ID: (OFString*)ID_;

- (void)addShow: (OFString*)show;
- (void)addStatus: (OFString*)status;
- (void)addPriority: (int8_t)priority;
@end
