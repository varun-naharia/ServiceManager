//
//  ServiceManager.m
//  tech3i
//
//  Created by Varun Naharia on 12/08/14.
//  Copyright (c) 2014 naharia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Reachability.h"
#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
//#import "Global.h"

typedef void (^ AppServiceResult) (id result);
typedef void (^ AppServiceError) (NSError *err);

typedef void (^AppDataConnectionResult) (id result);
typedef void (^AppDataConnectionError) (NSError *error);

@interface ServiceManager : NSObject
{
    AppServiceResult serviceResult;
    AppServiceError serviceError;
    AppDataConnectionError connectionError;
    AppDataConnectionResult connectionResult;
    NSURLConnection *conn;
}

@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic, strong) NSString *serviceURL;
@property (nonatomic, assign) BOOL isLogging;
@property (nonatomic, assign) BOOL isReachable;

-(void)getLoginVerificationForUserName:(NSString *)username Password:(NSString *)password Country:(NSString *)country result:(AppServiceResult)result error:(AppServiceError)error;



//-(void)getHomeDataForEmail:(NSString *)email result:(AppServiceResult)result error:(AppServiceError)error;
//
////-(void)addCardWithVardId:(NSString *)cardId ForUserId:(NSString *)uniqueId result:(AppServiceResult)result error:(AppServiceError)error;
//
//-(void)getAllHolderForUserId:(NSString *)userId result:(AppServiceResult)result error:(AppServiceError)error;
//
//-(void)deleteEnquiryForUserId:(NSString *)userId forCardId:(NSString *)cardId result:(AppServiceResult)result error:(AppServiceError)error;
//
//-(void)RemoveFromMycardForUserId:(NSString *)userId forCardId:(NSString *)cardId result:(AppServiceResult)result error:(AppServiceError)error;
//
//-(void)searchLiveCard:(NSString *)searchText result:(AppServiceResult)result error:(AppServiceError)error;
//
//-(void)addToMycardForUserId:(NSString *)userId forCardId:(NSString *)cardId withNote:(NSString *)note result:(AppServiceResult)result error:(AppServiceError)error;
//
//-(void)getInboxEnqueriesForUserId:(NSString *)userId result:(AppServiceResult)result error:(AppServiceError)error;
//
//-(void)getSentEnqueriesForUserId:(NSString *)userId result:(AppServiceResult)result error:(AppServiceError)error;
//
//-(void)registerUeserForName:(NSString *)name CompanyName:(NSString *)companyName ContactNo:(NSString *)contactNo UserName:(NSString *)userName Password:(NSString *)password PrivateProfile:(NSString *)profileValue BussinessTypeId:(NSString *)typeId result:(AppServiceResult)result error:(AppServiceError)error;
//
//
//-(void)addCardManuallyForUser:(NSString *)userId Cardholdername:(NSString *)name CardHolderEmailAddress:(NSString *)emailAddress CardHolderNumber:(NSString *)contactNo result:(AppServiceResult)result error:(AppServiceError)error;
//
//-(void)sendEnquiryforUser:(NSString *)userId forCard:(NSString *)cardId result:(AppServiceResult)result error:(AppServiceError)error;
//
//-(void)sendFeedBackFromUser:(NSString *)userId Feedback:(NSString *)userFeedback result:(AppServiceResult)result error:(AppServiceError)error;
//
//-(void)updateProfileStatusForUser:(NSString *)userId ProfileStatus:(NSString *)status result:(AppServiceResult)result error:(AppServiceError)error;
//
//-(void)changePasswordForUser:(NSString *)userId Password:(NSString *)newPassword result:(AppServiceResult)result error:(AppServiceError)error;
//
//-(void)deletMyCardForUserID:(NSString *)userId result:(AppServiceResult)result error:(AppServiceError)error;
//

//
//-(void)GetAllTyperesult:(AppServiceResult)result error:(AppServiceError)error;
//
//-(void)GetCitiesByCountryID:(NSString *)countryId result:(AppServiceResult)result error:(AppServiceError)error;
//
//-(void)GetAdvanceSearchForText:(NSString *)searchText BussinesstypeId:(NSString *)bussinesstype City:(NSString *)cityId result:(AppServiceResult)result error:(AppServiceError)error;
//
//-(void)GetMycardsAdvanceSearchForText:(NSString *)searchText BussinesstypeId:(NSString *)bussinesstype City:(NSString *)cityId UserId:(NSString *)userId result:(AppServiceResult)result error:(AppServiceError)error;
//










@end
