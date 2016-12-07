
//  PersonEntity.h


#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MessageEntity;

@interface PersonEntity : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *sendedMessages;
@property (readwrite, assign) int readcount;
@end

@interface PersonEntity (CoreDataGeneratedAccessors)

- (void)addSendedMessagesObject:(MessageEntity *)value;
- (void)removeSendedMessagesObject:(MessageEntity *)value;
- (void)addSendedMessages:(NSSet *)values;
- (void)removeSendedMessages:(NSSet *)values;

@end
