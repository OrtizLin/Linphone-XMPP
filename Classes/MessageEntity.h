
//  MessageEntity.h


#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PersonEntity;

@interface MessageEntity : NSManagedObject
@property (nonatomic, retain) NSString * image;
@property (nonatomic, retain) NSString * content;
@property (nonatomic, retain) NSString * receipt;
@property (nonatomic, retain) NSString * roomname;
@property (nonatomic, retain) NSNumber * flag_sended;
@property (nonatomic, retain) NSDate * sendDate;
@property (nonatomic, retain) NSNumber * flag_readed;
@property (nonatomic, retain) PersonEntity *receiver;
@property (nonatomic, retain) PersonEntity *sender;

@end
