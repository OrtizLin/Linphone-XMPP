/* UIStateBar.m
 *
 * Copyright (C) 2012  Belledonne Comunications, Grenoble, France
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Library General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#import "UIStateBar.h"
#import "LinphoneManager.h"
#import "PhoneMainView.h"

@implementation UIStateBar

@synthesize registrationStateImage;
@synthesize registrationStateLabel;
@synthesize callQualityImage;
@synthesize callSecurityImage;
@synthesize callSecurityButton;

NSTimer *callQualityTimer;
NSTimer *callSecurityTimer;
int messagesUnreadCount;

#pragma mark - Lifecycle Functions

- (id)init {
    self = [super initWithNibName:@"UIStateBar" bundle:[NSBundle mainBundle]];
    if(self != nil) {
        self->callSecurityImage = nil;
        self->callQualityImage = nil;
        self->securitySheet = nil;
    }
    return self;
}

- (void) dealloc {
    if(securitySheet) {
        [securitySheet release];
    }
    [registrationStateImage release];
    [registrationStateLabel release];
    [callQualityImage release];
    [callSecurityImage release];
    [callSecurityButton release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [callQualityTimer invalidate];
    [callQualityTimer release];
    [_voicemailCount release];
 
   
    [super dealloc];
}


#pragma mark - ViewController Functions

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
  
    // Set callQualityTimer
    callQualityTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                        target:self
                                                      selector:@selector(callQualityUpdate)
                                                      userInfo:nil
                                                       repeats:YES];
    
    // Set callQualityTimer
    callSecurityTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                         target:self
                                                       selector:@selector(callSecurityUpdate)
                                                       userInfo:nil
                                                        repeats:YES];
    
    // Set observer
    [[NSNotificationCenter defaultCenter]	addObserver:self
                                             selector:@selector(registrationUpdate:)
                                                 name:kLinphoneRegistrationUpdate
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter]	addObserver:self
                                             selector:@selector(globalStateUpdate:)
                                                 name:kLinphoneGlobalStateUpdate
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter]	addObserver:self
                                             selector:@selector(notifyReceived:)
                                                 name:kLinphoneNotifyReceived
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter]	addObserver:self
                                             selector:@selector(callUpdate:)
                                                 name:kLinphoneCallUpdate
                                               object:nil];
    
    
    [callQualityImage setHidden: true];
    [callSecurityImage setHidden: true];
    
    // Update to default state
    LinphoneProxyConfig* config = NULL;
    linphone_core_get_default_proxy([LinphoneManager getLc], &config);
    messagesUnreadCount = lp_config_get_int(linphone_core_get_config([LinphoneManager getLc]), "app", "voice_mail_messages_count", 0);
    
    [self proxyConfigUpdate: config];
    [self updateVoicemail];
    
    
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    
    // Remove observer
    [[NSNotificationCenter defaultCenter]	removeObserver:self
                                                    name:kLinphoneRegistrationUpdate
                                                  object:nil];
    [[NSNotificationCenter defaultCenter]	removeObserver:self
                                                    name:kLinphoneGlobalStateUpdate
                                                  object:nil];
    [[NSNotificationCenter defaultCenter]	removeObserver:self
                                                    name:kLinphoneNotifyReceived
                                                  object:nil];
    [[NSNotificationCenter defaultCenter]	removeObserver:self
                                                    name:kLinphoneCallUpdate
                                                  object:nil];
    
    if(callQualityTimer != nil) {
        [callQualityTimer invalidate];
        callQualityTimer = nil;
    }
    if(callSecurityTimer != nil) {
        [callSecurityTimer invalidate];
        callSecurityTimer = nil;
    }
}


#pragma mark - Event Functions

- (void)registrationUpdate: (NSNotification*) notif {
    
    
    
    //NSString *hello =[NSString stringWithFormat:@"my dictionary is %@", [notif userInfo]];
   
    
    LinphoneProxyConfig* config = NULL;
    linphone_core_get_default_proxy([LinphoneManager getLc], &config);
    [self proxyConfigUpdate:config];
}

- (void) globalStateUpdate:(NSNotification*) notif {
 
    [self registrationUpdate:notif];
}

- (void) notifyReceived:(NSNotification*) notif {
    const LinphoneContent * content = [[notif.userInfo objectForKey: @"content"] pointerValue];

    
    if ((content == NULL)
        || (strcmp("application", linphone_content_get_type(content)) != 0)
        || (strcmp("simple-message-summary", linphone_content_get_subtype(content)) != 0)
        || (linphone_content_get_buffer(content) == NULL)) {
        
        return;
    }
    const char* body = linphone_content_get_buffer(content);
    if ((body = strstr(body, "Voice-Message: ")) == NULL) {
        
         [LinphoneLogger log:LinphoneLoggerWarning format:@"Received new NOTIFY from but could not find 'voice-message' in BODY. Ignoring it."];

       
        return;
    }
// UDP problem.
    NSString *input = [[[NSString alloc] initWithUTF8String:linphone_content_get_buffer(content)] autorelease];
    
    NSRange tRange = [input rangeOfString:@"transport"];

    if (tRange.location == NSNotFound){
//  NSLog(@"This is UDP");
        NSString *message = NSLocalizedString(@"Registered", nil);
        UIImage *image = [UIImage imageNamed:@"led_connected.png"];
      [registrationStateLabel setText:message];
      [registrationStateImage setImage:image];
        
        
    }
   
        sscanf(body, "Voice-Message: %d", &messagesUnreadCount);
        
        [LinphoneLogger log:LinphoneLoggerLog format:@"Received new NOTIFY from voice mail: there is/are now %d message(s) unread", messagesUnreadCount];
        
        // save in lpconfig for future
        lp_config_set_int(linphone_core_get_config([LinphoneManager getLc]), "app", "voice_mail_messages_count", messagesUnreadCount);
        
        [self updateVoicemail];
    



    }
//set VoiceMailCount by otis.
- (void) updateVoicemail {
    
    	if (messagesUnreadCount > 0) {
            
            NSString *sipID = [[LinphoneManager instance] lpConfigStringForKey:@"username_preference"];
            if(sipID ==nil){
                self.voicemailCount.hidden = TRUE;
            }
            else{
    		self.voicemailCount.hidden = (linphone_core_get_calls([LinphoneManager getLc]) != NULL);
    		self.voicemailCount.text = [NSString stringWithFormat:NSLocalizedString(@"Voice mail: %d", @"%d"),messagesUnreadCount];
            CGSize screenSize = [UIScreen mainScreen].bounds.size;
            CGSize textSize = [self.voicemailCount.text sizeWithFont:[UIFont fontWithName: @"Helvetica" size:16]];
            CGRect newVoiceMailFrame = CGRectMake(screenSize.width-textSize.width-18,0.0f, 200.0f, 20.0f);
            self.voicemailCount.frame = newVoiceMailFrame;
            }
    	} else {
    		self.voicemailCount.hidden = TRUE;
    
    	}
}

- (void) callUpdate:(NSNotification*) notif {
    //show voice mail only when there is no call
    [self updateVoicemail];
}


#pragma mark -

- (void)proxyConfigUpdate: (LinphoneProxyConfig*) config {
    LinphoneRegistrationState state = LinphoneRegistrationNone;
    NSString* message = nil;
    UIImage* image = nil;
    LinphoneCore* lc = [LinphoneManager getLc];
    LinphoneGlobalState gstate = linphone_core_get_global_state(lc);
    
    if( gstate == LinphoneGlobalConfiguring ){
        message = NSLocalizedString(@"Fetching remote configuration", nil);
    } else if (config == NULL) {
        state = LinphoneRegistrationNone;
        if(linphone_core_is_network_reachable([LinphoneManager getLc]))
            message = NSLocalizedString(@"No SIP account configured", nil);
        else
            message = NSLocalizedString(@"Network down", nil);
    } else {
        state = linphone_proxy_config_get_state(config);
        
        switch (state) {
            case LinphoneRegistrationOk:
                message = NSLocalizedString(@"Registered", nil); break;
            case LinphoneRegistrationNone:
            case LinphoneRegistrationCleared:
                message =  NSLocalizedString(@"Not registered", nil); break;
            case LinphoneRegistrationFailed:
                message =  NSLocalizedString(@"Registration failed", nil); break;
            case LinphoneRegistrationProgress:
                message =  NSLocalizedString(@"", nil); break;
            default: break;
        }
    }
    
    registrationStateLabel.hidden = NO;
    switch(state) {
        case LinphoneRegistrationFailed:
            registrationStateImage.hidden = NO;
            image = [UIImage imageNamed:@"led_error.png"];
            break;
        case LinphoneRegistrationCleared:
        case LinphoneRegistrationNone:
            registrationStateImage.hidden = NO;
            image = [UIImage imageNamed:@"led_disconnected.png"];
            break;
        case LinphoneRegistrationProgress:
            registrationStateImage.hidden = NO;
            image = [UIImage imageNamed:@"led_inprogress.png"];
            break;
        case LinphoneRegistrationOk:
            registrationStateImage.hidden = NO;
            image = [UIImage imageNamed:@"led_connected.png"];
            break;
    }
    [registrationStateLabel setText:message];
    [registrationStateImage setImage:image];
}


#pragma mark -

- (void)callSecurityUpdate {
    BOOL pending = false;
    BOOL security = true;
    
    const MSList *list = linphone_core_get_calls([LinphoneManager getLc]);
    
    if(list == NULL) {
        if(securitySheet) {
            [securitySheet dismissWithClickedButtonIndex:securitySheet.destructiveButtonIndex animated:TRUE];
        }
        [callSecurityImage setHidden:true];
        return;
    }
    while(list != NULL) {
        LinphoneCall *call = (LinphoneCall*) list->data;
        LinphoneMediaEncryption enc = linphone_call_params_get_media_encryption(linphone_call_get_current_params(call));
        if(enc == LinphoneMediaEncryptionNone)
            security = false;
        else if(enc == LinphoneMediaEncryptionZRTP) {
            if(!linphone_call_get_authentication_token_verified(call)) {
                pending = true;
            }
        }
        list = list->next;
    }
    
    if(security) {
        if(pending) {
            [callSecurityImage setImage:[UIImage imageNamed:@"security_pending.png"]];
        } else {
            [callSecurityImage setImage:[UIImage imageNamed:@"security_ok.png"]];
        }
    } else {
        [callSecurityImage setImage:[UIImage imageNamed:@"security_ko.png"]];
    }
    [callSecurityImage setHidden: false];
}

- (void)callQualityUpdate {
    UIImage *image = nil;
    LinphoneCall *call = linphone_core_get_current_call([LinphoneManager getLc]);
    if(call != NULL) {
        //FIXME double check call state before computing, may cause core dump
        float quality = linphone_call_get_average_quality(call);
        if(quality < 1) {
            image = [UIImage imageNamed:@"call_quality_indicator_0.png"];
        } else if (quality < 2) {
            image = [UIImage imageNamed:@"call_quality_indicator_1.png"];
        } else if (quality < 3) {
            image = [UIImage imageNamed:@"call_quality_indicator_2.png"];
        } else {
            image = [UIImage imageNamed:@"call_quality_indicator_3.png"];
        }
    }
    if(image != nil) {
        [callQualityImage setHidden:false];
        [callQualityImage setImage:image];
    } else {
        [callQualityImage setHidden:true];
    }
}


#pragma mark - Action Functions



- (IBAction)dialvoicemail:(id)sender {
   
    NSString *displayName = nil;
    NSString *address = [[LinphoneManager instance] lpConfigStringForKey:@"voicemail_preference"];
   
    ABRecordRef contact = [[[LinphoneManager instance] fastAddressBook] getContact:address];
    if(contact) {
        displayName = [FastAddressBook getContactDisplayName:contact];
    }
    [[LinphoneManager instance] call:address displayName:displayName transfer:NO];
}




- (void)resetField:(NSString *)field forKey:(NSString *)key
{
    
    [[NSUserDefaults standardUserDefaults] setObject:field forKey:key];
    
}
- (void)setField:(NSString *)field forKey:(NSString *)key {
    if (field != nil)
    {
        [[NSUserDefaults standardUserDefaults] setObject:field forKey:key];
        [[NSUserDefaults standardUserDefaults]synchronize];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
    }
}
- (void)addProxyConfig:(NSString*)username password:(NSString*)password domain:(NSString*)domain {
    LinphoneCore* lc = [LinphoneManager getLc];
    LinphoneProxyConfig* proxyCfg = linphone_core_create_proxy_config(lc);
    
    
    char normalizedUserName[256];
    linphone_proxy_config_normalize_number(proxyCfg, [username cStringUsingEncoding:[NSString defaultCStringEncoding]], normalizedUserName, sizeof(normalizedUserName));
    
    const char* identity = linphone_proxy_config_get_identity(proxyCfg);
    if( !identity || !*identity ) identity = "sip:user@example.com";
    
    LinphoneAddress* linphoneAddress = linphone_address_new(identity);
    
    linphone_address_set_username(linphoneAddress, normalizedUserName);
    
   
    if( domain && [domain length] != 0) {
        // when the domain is specified (for external login), take it as the server address
        linphone_proxy_config_set_server_addr(proxyCfg, [domain UTF8String]);
        linphone_address_set_domain(linphoneAddress, [domain UTF8String]);
        
    }
    
    identity = linphone_address_as_string_uri_only(linphoneAddress);
    
    linphone_proxy_config_set_identity(proxyCfg, identity);
    
    
    
    LinphoneAuthInfo* info = linphone_auth_info_new([username UTF8String]
                                                    , NULL, [password UTF8String]
                                                    , NULL
                                                    , NULL
                                                    ,linphone_proxy_config_get_domain(proxyCfg));
    
    [self setDefaultSettings:proxyCfg];
    
    [self clearProxyConfig];
    
    linphone_proxy_config_enable_register(proxyCfg, true);
    linphone_core_add_auth_info(lc, info);
    linphone_core_add_proxy_config(lc, proxyCfg);
    
  
    
    linphone_core_set_default_proxy(lc, proxyCfg);
      LinphoneTransportType type = LinphoneTransportTcp;
      linphone_address_set_transport(linphoneAddress, type);
      NSString* tname = @"tcp_port";
      linphone_core_set_sip_transports(lc,(__bridge const LCSipTransports *)(tname));
}

- (void)clearProxyConfig {
    linphone_core_clear_proxy_config([LinphoneManager getLc]);
    linphone_core_clear_all_auth_info([LinphoneManager getLc]);
}
- (void)setDefaultSettings:(LinphoneProxyConfig*)proxyCfg {
    LinphoneManager* lm = [LinphoneManager instance];
    
    
    
    
    
    BOOL pushnotification = [lm lpConfigBoolForKey:@"pushnotification_preference"];
    if(pushnotification) {
        [lm addPushTokenToProxyConfig:proxyCfg];
        
    }
}


- (IBAction)doSecurityClick:(id)sender {
    if(linphone_core_get_calls_nb([LinphoneManager getLc])) {
        LinphoneCall *call = linphone_core_get_current_call([LinphoneManager getLc]);
        if(call != NULL) {
            LinphoneMediaEncryption enc = linphone_call_params_get_media_encryption(linphone_call_get_current_params(call));
            if(enc == LinphoneMediaEncryptionZRTP) {
                bool valid = linphone_call_get_authentication_token_verified(call);
                NSString *message = nil;
                if(valid) {
                    message = NSLocalizedString(@"Remove trust in the peer?",nil);
                } else {
                    message = [NSString stringWithFormat:NSLocalizedString(@"Confirm the following SAS with the peer:\n%s",nil),
                               linphone_call_get_authentication_token(call)];
                }
                if( securitySheet == nil ){
                    securitySheet = [[DTActionSheet alloc] initWithTitle:message];
                    [securitySheet setDelegate:self];
                    [securitySheet addButtonWithTitle:NSLocalizedString(@"Ok",nil) block:^(){
                        linphone_call_set_authentication_token_verified(call, !valid);
                        [securitySheet release];
                        securitySheet = nil;
                    }];
                    
                    [securitySheet addDestructiveButtonWithTitle:NSLocalizedString(@"Cancel",nil) block:^(){
                        [securitySheet release];
                        securitySheet = nil;
                    }];
                    [securitySheet showInView:[PhoneMainView instance].view];
                }
            }
        }
    }
}

-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    [securitySheet release];
    securitySheet = nil;
}

#pragma mark - TPMultiLayoutViewController Functions

- (NSDictionary*)attributesForView:(UIView*)view {
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    
    [attributes setObject:[NSValue valueWithCGRect:view.frame] forKey:@"frame"];
    [attributes setObject:[NSValue valueWithCGRect:view.bounds] forKey:@"bounds"];
    [attributes setObject:[NSNumber numberWithInteger:view.autoresizingMask] forKey:@"autoresizingMask"];
    
    return attributes;
}

- (void)applyAttributes:(NSDictionary*)attributes toView:(UIView*)view {
    view.frame = [[attributes objectForKey:@"frame"] CGRectValue];
    view.bounds = [[attributes objectForKey:@"bounds"] CGRectValue];
    view.autoresizingMask = [[attributes objectForKey:@"autoresizingMask"] integerValue];
}

@end
