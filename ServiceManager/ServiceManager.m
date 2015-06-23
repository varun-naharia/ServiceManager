//
//  ServiceManager.m
//  tech3i
//
//  Created by Varun Naharia on 12/08/14.
//  Copyright (c) 2014 naharia. All rights reserved.
//


# define kDev_AppService @"http://www.domain.com/restcontroller"
//# define kDev_AppService @"http://www.domain.com/restcontroller"

#import "ServiceManager.h"


@implementation ServiceManager

@synthesize responseData,serviceURL,isLogging,isReachable;

-(id)init
{
    
    if (self = [super init]) {
        
        isLogging = YES;
        isReachable = YES;
        [self reachabilityCheck];
        
    }
    return self;
}

-(NSMutableData *)responseData
{
    return responseData;
}

-(AppServiceResult)serviceResult
{
    return serviceResult;
}

-(AppServiceError)serviceError
{
    return serviceError;
}

-(void)reachabilityCheck
{
   @try {
       Reachability *__autoreleasing reach = [Reachability reachabilityForInternetConnection];
       if (reach.currentReachabilityStatus) {
           self.isReachable = YES;
       }
       else
       {
           self.isReachable =  NO;
       }
   }
   @catch (NSException *exception) {
       //// [Global writeToLogFile:[exception description]];
   }
   @finally {
       
   }
}

-(UIView *)viewForIndicator
{
    //UIWindow *__autoreleasing win = [UIApplication sharedApplication].keyWindow;
     //UIView *__autoreleasing view = [win.subviews lastObject];
     //return view;
    
    UIWindow *__autoreleasing win = nil;//[UIApplication sharedApplication].keyWindow;
    NSArray* arrWindows = [UIApplication sharedApplication].windows;
    for (UIWindow* w in arrWindows) {
        if ([w isKindOfClass:[UIWindow class]]) {
            win = w;
            break;
        }
    }
    UIView *__autoreleasing view = nil;
    for(int i=(int)[win.subviews count]-1;i>=0;i--){
        view=[win.subviews objectAtIndex:i];
        if(![view isKindOfClass:[UIAlertView class]]){
            break;
        }
    }
    return view;
    
}

-(void)cancelRequest
{
    [conn cancel];
    [responseData setLength:0];
    connectionResult = nil;
    connectionError = nil;
    serviceResult = nil;
    serviceError = nil;
    
    ///////////add MBprogress HUd and UNcomment This line//////////////
    
    [MBProgressHUD hideAllHUDsForView:[self viewForIndicator] animated:YES];
    
    [MBProgressHUD hideHUDForView:[self viewForIndicator] animated:YES];
}

-(void)setServiceResult:(AppServiceResult)result andServiceError:(AppServiceError)error
{
    serviceResult = result;
    serviceError = error;
}

-(NSMutableURLRequest *)requestWithURLString :(NSString *)urlString forMethod:(NSString *)httpMethod
{
    @try {
        
        NSString* urlTextEscaped = [[NSString stringWithFormat:@"%@%@",kDev_AppService,urlString] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

        
        NSMutableURLRequest *__autoreleasing _request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlTextEscaped]];
        [_request setHTTPMethod:httpMethod];
        if (isLogging)
            NSLog(@"Request Generated is %@........",_request);
        return _request;
    }
    @catch (NSException *exception) {
        //[Global writeToLogFile:[exception description]];
    }
    @finally {
        
    }
    
}

-(NSError *)noInternetError
{
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"No Connection Error"
                                                         forKey:NSLocalizedDescriptionKey];
    NSError *noConnectionError = [NSError errorWithDomain:NSCocoaErrorDomain
                                                     code:kCFURLErrorNotConnectedToInternet
                                                 userInfo:userInfo];
    
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Alert" message:@"No Internet Connection" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
    
    [alert show];
    
    return noConnectionError;
}


////////////////////////////////////////////////////////////////////////////////////
////////////////////////CONNECTION//////////////////////////////////////////////////

-(void)startConnectionWithRequest:(NSMutableURLRequest *)request Result:(AppDataConnectionResult)result error:(AppDataConnectionError)error;
{
    if (request)
    {
        connectionResult = result;
        connectionError = error;
        [request setCachePolicy:NSURLRequestUseProtocolCachePolicy];
        [request setTimeoutInterval:60.0];
        conn = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
        [conn scheduleInRunLoop:[NSRunLoop mainRunLoop]
                        forMode:NSDefaultRunLoopMode];
        [conn start];
        if (isLogging)
            NSLog(@"time out interval: %f", request.timeoutInterval);
    }
    
    else {
        NSError *__autoreleasing err = [NSError errorWithDomain:@"Faulty Request" code:10001 userInfo:nil];
        connectionError(err);
    }
}

// C-O-N-N-E-C-T-I-O-N--------D-E-L-E-G-A-T-E-------------////////////

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse *__autoreleasing res = (NSHTTPURLResponse*)response;
    if (res.statusCode == 200 || res.statusCode == 201) {
        if (!responseData) {
            self.responseData = [NSMutableData data];
        }
        else
            [responseData setLength:0];
    }
    
    else
    {
        NSString *__autoreleasing str = [NSHTTPURLResponse localizedStringForStatusCode:res.statusCode];
        NSError *__autoreleasing err = [NSError errorWithDomain:str code:res.statusCode userInfo:res.allHeaderFields];
        
        
        connectionError (err);
        [connection cancel];
        responseData = nil;
    }
}

// -------------------------------------------------------------------------------
//	connection:didReceiveData:data
// -------------------------------------------------------------------------------
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    
    [responseData appendData:data];  // append incoming data
}

// -------------------------------------------------------------------------------
//	connection:didFailWithError:error
// -------------------------------------------------------------------------------
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    if ([error code] == kCFURLErrorNotConnectedToInternet)
	{
        // if we can identify the error, we can present a more precise message to the user.
        NSDictionary *__autoreleasing userInfo = [NSDictionary dictionaryWithObject:@"No Connection Error"
                                                                             forKey:NSLocalizedDescriptionKey];
        NSError *__autoreleasing noConnectionError = [NSError errorWithDomain:NSCocoaErrorDomain
                                                                         code:kCFURLErrorNotConnectedToInternet
                                                                     userInfo:userInfo];
        connectionError (noConnectionError);
        
    }
	else
	{
        // otherwise handle the error generically
        if (connectionError)
            connectionError (error);
    }
    [connection cancel];
    conn = nil;   // release our connection
    
}

// -------------------------------------------------------------------------------
//	connectionDidFinishLoading:connection
// -------------------------------------------------------------------------------
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    conn = nil;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    if (responseData) {//if received any response then it must be processed else display an error
        if (connectionResult)
            connectionResult (responseData);
    }else {
        NSDictionary *__autoreleasing userInfo = [NSDictionary dictionaryWithObject:@"No response received."
                                                                             forKey:NSLocalizedDescriptionKey];
        NSError *__autoreleasing noConnectionError = [NSError errorWithDomain:NSCocoaErrorDomain
                                                                         code:kCFURLErrorResourceUnavailable
                                                                     userInfo:userInfo];
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Please check you internet connection." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alertView show];

        
        
        connectionError (noConnectionError);
    }
}


#pragma login api

-(void)getLoginVerificationForUserName:(NSString *)username Password:(NSString *)password Country:(NSString *)country result:(AppServiceResult)result error:(AppServiceError)error

{
    [self reachabilityCheck];
    
    @try {
        if (self.isReachable)
        {
            [self setServiceResult:result andServiceError:error];
            ServiceManager *__weak weakService = self;
            
            [MBProgressHUD showHUDAddedTo:[self viewForIndicator] animated:YES];
            //On 15/11/14, at 3:38 pm, Divya Tech3i wrote:
            
            
            NSString *urlString = [NSString stringWithFormat:@"%@/login/format/json",kDev_AppService];
            NSURL *url = [NSURL URLWithString:urlString];
            
            
            //            NSString *myRequestString = [NSString stringWithFormat:@"title=%@&description=%@&city=%@",eventTitle.text,eventDescription.text,eventCity.text];
            //
            //            // Create Data from request
            //            NSData *myRequestData = [NSData dataWithBytes: [myRequestString UTF8String] length: [myRequestString length]];
            /*
             f_name,user_name,password,user_type,email,mobile,country,business
             */
            
            NSString *myRequestString = [NSString stringWithFormat:@"username=%@&password=%@&country=%@",username,password,country];
            
            // Create Data from request
            NSData *myRequestData = [NSData dataWithBytes: [myRequestString UTF8String] length: [myRequestString length]];
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
            NSLog(@"resquested url is : %@",url);
            NSLog(@"myRequestString is : %@",myRequestString);
            [request setURL:url];
            [request setHTTPMethod:@"POST"];
            [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
            [request setHTTPBody: myRequestData];
            //            [request setHTTPBody:[[NSString stringWithFormat:@"email = %@",email] dataUsingEncoding:NSUTF8StringEncoding]];
            
            
            
            [self startConnectionWithRequest:request
             
                                      Result:^(id result){
                                          
                                          [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                                          if (isLogging)
                                          {
                                              NSString *__autoreleasing str = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
                                              NSLog(@"Result is %@",str);
                                          }
                                          NSError *__autoreleasing e = nil;
                                          NSDictionary* __autoreleasing json = [NSJSONSerialization
                                                                                JSONObjectWithData:[weakService responseData]
                                                                                
                                                                                options:kNilOptions
                                                                                error:&e];
                                          if (!e) {
                                              @autoreleasepool {
                                                  @try {
                                                      NSArray* arr = (NSArray *)json;
                                                      
                                                      [weakService serviceResult] (arr);
                                                  }
                                                  @catch (NSException *e)
                                                  {
                                                      
                                                  }
                                              }
                                          }
                                          
                                      }
                                       error:^(NSError *error)
             {
                 if (isLogging)
                     NSLog(@"Error is %@",error);
                 [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                 [weakService serviceError] (error);
             }];
        }
        else
        {
            [self setServiceResult:result andServiceError:error];
            serviceError([self noInternetError]);
        }
    }
    @catch (NSException *exception) {
        ///  [Global writeToLogFile:[exception description]];
    }
    @finally {
        
    }

}
-(void)GetUserType:(AppServiceResult)result error:(AppServiceError)error
{
    [self reachabilityCheck];
    
    @try {
        if (self.isReachable)
        {
            [self setServiceResult:result andServiceError:error];
            ServiceManager *__weak weakService = self;
            
             [MBProgressHUD showHUDAddedTo:[self viewForIndicator] animated:YES];
            
            
            [self startConnectionWithRequest:[self requestWithURLString:[NSString stringWithFormat:@"/usertype/format/json"] forMethod:@"GET"]
             
                                      Result:^(id result){
                                          
                                            [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                                          if (isLogging)
                                          {
                                              NSString *__autoreleasing str = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
                                              NSLog(@"Result is %@",str);
                                          }
                                          NSError *__autoreleasing e = nil;
                                          NSDictionary* __autoreleasing json = [NSJSONSerialization
                                                                                JSONObjectWithData:[weakService responseData]
                                                                                
                                                                                options:kNilOptions
                                                                                error:&e];
                                          if (!e) {
                                              @autoreleasepool {
                                                  @try {
                                                      NSArray* arr = (NSArray *)json;
                                                      
                                                      [weakService serviceResult] (arr);
                                                  }
                                                  @catch (NSException *e)
                                                  {
                                                      
                                                  }
                                              }
                                          }
                                          
                                      }
                                       error:^(NSError *error)
             {
                 if (isLogging)
                     NSLog(@"Error is %@",error);
                 [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                 [weakService serviceError] (error);
             }];
        }
        else
        {
            [self setServiceResult:result andServiceError:error];
            serviceError([self noInternetError]);
        }
    }
    @catch (NSException *exception) {
        ///  [Global writeToLogFile:[exception description]];
    }
    @finally {
        
    }
}


/*

 
 
  reciever sender amount message select
 = raott/doller
 
-(void)getHomeDataForEmail:(NSString *)email result:(AppServiceResult)result error:(AppServiceError)error
{
    [self reachabilityCheck];
    
    @try {
        if (self.isReachable)
        {
            [self setServiceResult:result andServiceError:error];
            ServiceManager *__weak weakService = self;
            
            [MBProgressHUD showHUDAddedTo:[self viewForIndicator] animated:YES];
            
            
            [self startConnectionWithRequest:[self requestWithURLString:[NSString stringWithFormat:@"/GetProfileHome?Username=%@",email] forMethod:@"GET"]
             
                                      Result:^(id result){
                                          
                                          [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                                          if (isLogging)
                                          {
                                              NSString *__autoreleasing str = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
                                              NSLog(@"Result is %@",str);
                                          }
                                          NSError *__autoreleasing e = nil;
                                          NSDictionary* __autoreleasing json = [NSJSONSerialization
                                                                                JSONObjectWithData:[weakService responseData]
                                                                                
                                                                                options:kNilOptions
                                                                                error:&e];
                                          if (!e) {
                                              @autoreleasepool {
                                                  @try {
                                                      NSArray* arr = (NSArray *)json;
                                                      
                                                      [weakService serviceResult] (arr);
                                                  }
                                                  @catch (NSException *e)
                                                  {
                                                      
                                                  }
                                              }
                                          }
                                          
                                      }
                                       error:^(NSError *error)
             {
                 if (isLogging)
                     NSLog(@"Error is %@",error);
                 [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                 [weakService serviceError] (error);
             }];
        }
        else
        {
            [self setServiceResult:result andServiceError:error];
            serviceError([self noInternetError]);
        }
    }
    @catch (NSException *exception) {
        ///  [Global writeToLogFile:[exception description]];
    }
    @finally {
        
    }

}




-(void)getAllHolderForUserId:(NSString *)userId result:(AppServiceResult)result error:(AppServiceError)error
{
    [self reachabilityCheck];
    
    @try {
        if (self.isReachable)
        {
            [self setServiceResult:result andServiceError:error];
            ServiceManager *__weak weakService = self;
            
            [MBProgressHUD showHUDAddedTo:[self viewForIndicator] animated:YES];
            
            
            [self startConnectionWithRequest:[self requestWithURLString:[NSString stringWithFormat:@"/GetMycards?UserID=%@",userId] forMethod:@"GET"]
             
                                      Result:^(id result){
                                          
                                          [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                                          if (isLogging)
                                          {
                                              NSString *__autoreleasing str = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
                                              NSLog(@"Result is %@",str);
                                          }
                                          NSError *__autoreleasing e = nil;
                                          NSDictionary* __autoreleasing json = [NSJSONSerialization
                                                                                JSONObjectWithData:[weakService responseData]
                                                                                
                                                                                options:kNilOptions
                                                                                error:&e];
                                          if (!e) {
                                              @autoreleasepool {
                                                  @try {
                                                      NSArray* arr = (NSArray *)json;
                                                      
                                                      [weakService serviceResult] (arr);
                                                  }
                                                  @catch (NSException *e)
                                                  {
                                                      
                                                  }
                                              }
                                          }
                                          
                                      }
                                       error:^(NSError *error)
             {
                 if (isLogging)
                     NSLog(@"Error is %@",error);
                 [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                 [weakService serviceError] (error);
             }];
        }
        else
        {
            [self setServiceResult:result andServiceError:error];
            serviceError([self noInternetError]);
        }
    }
    @catch (NSException *exception) {
        ///  [Global writeToLogFile:[exception description]];
    }
    @finally {
        
    }
}

-(void)deleteEnquiryForUserId:(NSString *)userId forCardId:(NSString *)cardId result:(AppServiceResult)result error:(AppServiceError)error
{
    [self reachabilityCheck];
    
    @try {
        if (self.isReachable)
        {
            [self setServiceResult:result andServiceError:error];
            ServiceManager *__weak weakService = self;
            
            [MBProgressHUD showHUDAddedTo:[self viewForIndicator] animated:YES];
            
            
            [self startConnectionWithRequest:[self requestWithURLString:[NSString stringWithFormat:@"/DeleteEnquiry?UserID=%@&CardId=%@",userId,cardId] forMethod:@"GET"]
             
                                      Result:^(id result){
                                          
                                          [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                                          if (isLogging)
                                          {
                                              NSString *__autoreleasing str = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
                                              NSLog(@"Result is %@",str);
                                          }
                                          NSError *__autoreleasing e = nil;
                                          NSDictionary* __autoreleasing json = [NSJSONSerialization
                                                                                JSONObjectWithData:[weakService responseData]
                                                                                
                                                                                options:kNilOptions
                                                                                error:&e];
                                          if (!e) {
                                              @autoreleasepool {
                                                  @try {
                                                      NSArray* arr = (NSArray *)json;
                                                      
                                                      [weakService serviceResult] (arr);
                                                  }
                                                  @catch (NSException *e)
                                                  {
                                                      
                                                  }
                                              }
                                          }
                                          
                                      }
                                       error:^(NSError *error)
             {
                 if (isLogging)
                     NSLog(@"Error is %@",error);
                 [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                 [weakService serviceError] (error);
             }];
        }
        else
        {
            [self setServiceResult:result andServiceError:error];
            serviceError([self noInternetError]);
        }
    }
    @catch (NSException *exception) {
        ///  [Global writeToLogFile:[exception description]];
    }
    @finally {
        
    }
}


-(void)RemoveFromMycardForUserId:(NSString *)userId forCardId:(NSString *)cardId result:(AppServiceResult)result error:(AppServiceError)error
{
    [self reachabilityCheck];
    
    @try {
        if (self.isReachable)
        {
            [self setServiceResult:result andServiceError:error];
            ServiceManager *__weak weakService = self;
            
            [MBProgressHUD showHUDAddedTo:[self viewForIndicator] animated:YES];
            
            
            [self startConnectionWithRequest:[self requestWithURLString:[NSString stringWithFormat:@"/RemoveFromMycard?UserID=%@&CardId=%@",userId,cardId] forMethod:@"GET"]
             
                                      Result:^(id result){
                                          
                                          [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                                          if (isLogging)
                                          {
                                              NSString *__autoreleasing str = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
                                              NSLog(@"Result is %@",str);
                                          }
                                          NSError *__autoreleasing e = nil;
                                          NSDictionary* __autoreleasing json = [NSJSONSerialization
                                                                                JSONObjectWithData:[weakService responseData]
                                                                                
                                                                                options:kNilOptions
                                                                                error:&e];
                                          if (!e) {
                                              @autoreleasepool {
                                                  @try {
                                                      NSArray* arr = (NSArray *)json;
                                                      
                                                      [weakService serviceResult] (arr);
                                                  }
                                                  @catch (NSException *e)
                                                  {
                                                      
                                                  }
                                              }
                                          }
                                          
                                      }
                                       error:^(NSError *error)
             {
                 if (isLogging)
                     NSLog(@"Error is %@",error);
                 [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                 [weakService serviceError] (error);
             }];
        }
        else
        {
            [self setServiceResult:result andServiceError:error];
            serviceError([self noInternetError]);
        }
    }
    @catch (NSException *exception) {
        ///  [Global writeToLogFile:[exception description]];
    }
    @finally {
        
    }
}


-(void)searchLiveCard:(NSString *)searchText result:(AppServiceResult)result error:(AppServiceError)error
{
    [self reachabilityCheck];
    
    @try {
        if (self.isReachable)
        {
            [self setServiceResult:result andServiceError:error];
            ServiceManager *__weak weakService = self;
            
            [MBProgressHUD showHUDAddedTo:[self viewForIndicator] animated:YES];
            
            
            [self startConnectionWithRequest:[self requestWithURLString:[NSString stringWithFormat:@"/SearchCardLive?Text=%@",searchText] forMethod:@"GET"]
             
                                      Result:^(id result){
                                          
                                          [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                                          if (isLogging)
                                          {
                                              NSString *__autoreleasing str = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
                                              NSLog(@"Result is %@",str);
                                          }
                                          NSError *__autoreleasing e = nil;
                                          NSDictionary* __autoreleasing json = [NSJSONSerialization
                                                                                JSONObjectWithData:[weakService responseData]
                                                                                
                                                                                options:kNilOptions
                                                                                error:&e];
                                          if (!e) {
                                              @autoreleasepool {
                                                  @try {
                                                      NSArray* arr = (NSArray *)json;
                                                      
                                                      [weakService serviceResult] (arr);
                                                  }
                                                  @catch (NSException *e)
                                                  {
                                                      
                                                  }
                                              }
                                          }
                                          
                                      }
                                       error:^(NSError *error)
             {
                 if (isLogging)
                     NSLog(@"Error is %@",error);
                 [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                 [weakService serviceError] (error);
             }];
        }
        else
        {
            [self setServiceResult:result andServiceError:error];
            serviceError([self noInternetError]);
        }
    }
    @catch (NSException *exception) {
        ///  [Global writeToLogFile:[exception description]];
    }
    @finally {
        
    }

}

-(void)addToMycardForUserId:(NSString *)userId forCardId:(NSString *)cardId withNote:(NSString *)note result:(AppServiceResult)result error:(AppServiceError)error
{
    [self reachabilityCheck];
    
    @try {
        if (self.isReachable)
        {
            [self setServiceResult:result andServiceError:error];
            ServiceManager *__weak weakService = self;
            
            [MBProgressHUD showHUDAddedTo:[self viewForIndicator] animated:YES];
            
            
            [self startConnectionWithRequest:[self requestWithURLString:[NSString stringWithFormat:@"/AddToMycard?UserID=%@&CardId=%@&Note=%@",userId,cardId,note] forMethod:@"GET"]
             
                                      Result:^(id result){
                                          
                                          [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                                          if (isLogging)
                                          {
                                              NSString *__autoreleasing str = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
                                              NSLog(@"Result is %@",str);
                                          }
                                          NSError *__autoreleasing e = nil;
                                          NSDictionary* __autoreleasing json = [NSJSONSerialization
                                                                                JSONObjectWithData:[weakService responseData]
                                                                                
                                                                                options:kNilOptions
                                                                                error:&e];
                                          if (!e) {
                                              @autoreleasepool {
                                                  @try {
                                                      NSArray* arr = (NSArray *)json;
                                                      
                                                      [weakService serviceResult] (arr);
                                                  }
                                                  @catch (NSException *e)
                                                  {
                                                      
                                                  }
                                              }
                                          }
                                          
                                      }
                                       error:^(NSError *error)
             {
                 if (isLogging)
                     NSLog(@"Error is %@",error);
                 [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                 [weakService serviceError] (error);
             }];
        }
        else
        {
            [self setServiceResult:result andServiceError:error];
            serviceError([self noInternetError]);
        }
    }
    @catch (NSException *exception) {
        ///  [Global writeToLogFile:[exception description]];
    }
    @finally {
        
    }

}

-(void)getInboxEnqueriesForUserId:(NSString *)userId result:(AppServiceResult)result error:(AppServiceError)error
{
    [self reachabilityCheck];
    
    @try {
        if (self.isReachable)
        {
            [self setServiceResult:result andServiceError:error];
            ServiceManager *__weak weakService = self;
            
            [MBProgressHUD showHUDAddedTo:[self viewForIndicator] animated:YES];
            
            
            [self startConnectionWithRequest:[self requestWithURLString:[NSString stringWithFormat:@"/GetInboxEnqueries?UserID=%@",userId] forMethod:@"GET"]
             
                                      Result:^(id result){
                                          
                                          [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                                          if (isLogging)
                                          {
                                              NSString *__autoreleasing str = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
                                              NSLog(@"Result is %@",str);
                                          }
                                          NSError *__autoreleasing e = nil;
                                          NSDictionary* __autoreleasing json = [NSJSONSerialization
                                                                                JSONObjectWithData:[weakService responseData]
                                                                                
                                                                                options:kNilOptions
                                                                                error:&e];
                                          if (!e) {
                                              @autoreleasepool {
                                                  @try {
                                                      NSArray* arr = (NSArray *)json;
                                                      
                                                      [weakService serviceResult] (arr);
                                                  }
                                                  @catch (NSException *e)
                                                  {
                                                      
                                                  }
                                              }
                                          }
                                          
                                      }
                                       error:^(NSError *error)
             {
                 if (isLogging)
                     NSLog(@"Error is %@",error);
                 [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                 [weakService serviceError] (error);
             }];
        }
        else
        {
            [self setServiceResult:result andServiceError:error];
            serviceError([self noInternetError]);
        }
    }
    @catch (NSException *exception) {
        ///  [Global writeToLogFile:[exception description]];
    }
    @finally {
        
    }

}


-(void)getSentEnqueriesForUserId:(NSString *)userId result:(AppServiceResult)result error:(AppServiceError)error
{
    [self reachabilityCheck];
    
    @try {
        if (self.isReachable)
        {
            [self setServiceResult:result andServiceError:error];
            ServiceManager *__weak weakService = self;
            
            [MBProgressHUD showHUDAddedTo:[self viewForIndicator] animated:YES];
            
            
            [self startConnectionWithRequest:[self requestWithURLString:[NSString stringWithFormat:@"/GetSentEnqueries?UserID=%@",userId] forMethod:@"GET"]
             
                                      Result:^(id result){
                                          
                                          [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                                          if (isLogging)
                                          {
                                              NSString *__autoreleasing str = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
                                              NSLog(@"Result is %@",str);
                                          }
                                          NSError *__autoreleasing e = nil;
                                          NSDictionary* __autoreleasing json = [NSJSONSerialization
                                                                                JSONObjectWithData:[weakService responseData]
                                                                                
                                                                                options:kNilOptions
                                                                                error:&e];
                                          if (!e) {
                                              @autoreleasepool {
                                                  @try {
                                                      NSArray* arr = (NSArray *)json;
                                                      
                                                      [weakService serviceResult] (arr);
                                                  }
                                                  @catch (NSException *e)
                                                  {
                                                      
                                                  }
                                              }
                                          }
                                          
                                      }
                                       error:^(NSError *error)
             {
                 if (isLogging)
                     NSLog(@"Error is %@",error);
                 [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                 [weakService serviceError] (error);
             }];
        }
        else
        {
            [self setServiceResult:result andServiceError:error];
            serviceError([self noInternetError]);
        }
    }
    @catch (NSException *exception) {
        ///  [Global writeToLogFile:[exception description]];
    }
    @finally {
        
    }

}


-(void)registerUeserForName:(NSString *)name CompanyName:(NSString *)companyName ContactNo:(NSString *)contactNo UserName:(NSString *)userName Password:(NSString *)password PrivateProfile:(NSString *)profileValue BussinessTypeId:(NSString *)typeId result:(AppServiceResult)result error:(AppServiceError)error
{
    [self reachabilityCheck];
    
    @try {
        if (self.isReachable)
        {
            [self setServiceResult:result andServiceError:error];
            ServiceManager *__weak weakService = self;
            
            [MBProgressHUD showHUDAddedTo:[self viewForIndicator] animated:YES];
            
            
            [self startConnectionWithRequest:[self requestWithURLString:[NSString stringWithFormat:@"/RegisterUser?Name=%@&CompanyName=%@&ContactNo=%@&UserName=%@&Password=%@&Profile=%@,BusinessTypeId=%@",name,companyName,contactNo,userName,password,profileValue,typeId] forMethod:@"GET"]
             
                                      Result:^(id result){
                                          
                                          [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                                          if (isLogging)
                                          {
                                              NSString *__autoreleasing str = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
                                              NSLog(@"Result is %@",str);
                                          }
                                          NSError *__autoreleasing e = nil;
                                          NSDictionary* __autoreleasing json = [NSJSONSerialization
                                                                                JSONObjectWithData:[weakService responseData]
                                                                                
                                                                                options:kNilOptions
                                                                                error:&e];
                                          if (!e) {
                                              @autoreleasepool {
                                                  @try {
                                                      NSArray* arr = (NSArray *)json;
                                                      
                                                      [weakService serviceResult] (arr);
                                                  }
                                                  @catch (NSException *e)
                                                  {
                                                      
                                                  }
                                              }
                                          }
                                          
                                      }
                                       error:^(NSError *error)
             {
                 if (isLogging)
                     NSLog(@"Error is %@",error);
                 [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                 [weakService serviceError] (error);
             }];
        }
        else
        {
            [self setServiceResult:result andServiceError:error];
            serviceError([self noInternetError]);
        }
    }
    @catch (NSException *exception) {
        ///  [Global writeToLogFile:[exception description]];
    }
    @finally {
        
    }

}



-(void)addCardManuallyForUser:(NSString *)userId Cardholdername:(NSString *)name CardHolderEmailAddress:(NSString *)emailAddress CardHolderNumber:(NSString *)contactNo result:(AppServiceResult)result error:(AppServiceError)error
{
    [self reachabilityCheck];
    
    @try {
        if (self.isReachable)
        {
            [self setServiceResult:result andServiceError:error];
            ServiceManager *__weak weakService = self;
            
            [MBProgressHUD showHUDAddedTo:[self viewForIndicator] animated:YES];
            
            
            [self startConnectionWithRequest:[self requestWithURLString:[NSString stringWithFormat:@"/AddCardManually?UserID=%@&Name=%@&EmailAddress=%@&Phone=%@",userId,name,emailAddress,contactNo] forMethod:@"GET"]
             
                                      Result:^(id result){
                                          
                                          [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                                          if (isLogging)
                                          {
                                              NSString *__autoreleasing str = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
                                              NSLog(@"Result is %@",str);
                                          }
                                          NSError *__autoreleasing e = nil;
                                          NSDictionary* __autoreleasing json = [NSJSONSerialization
                                                                                JSONObjectWithData:[weakService responseData]
                                                                                
                                                                                options:kNilOptions
                                                                                error:&e];
                                          if (!e) {
                                              @autoreleasepool {
                                                  @try {
                                                      NSArray* arr = (NSArray *)json;
                                                      
                                                      [weakService serviceResult] (arr);
                                                  }
                                                  @catch (NSException *e)
                                                  {
                                                      
                                                  }
                                              }
                                          }
                                          
                                      }
                                       error:^(NSError *error)
             {
                 if (isLogging)
                     NSLog(@"Error is %@",error);
                 [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                 [weakService serviceError] (error);
             }];
        }
        else
        {
            [self setServiceResult:result andServiceError:error];
            serviceError([self noInternetError]);
        }
    }
    @catch (NSException *exception) {
        ///  [Global writeToLogFile:[exception description]];
    }
    @finally {
        
    }

}

-(void)sendEnquiryforUser:(NSString *)userId forCard:(NSString *)cardId result:(AppServiceResult)result error:(AppServiceError)error
{
    [self reachabilityCheck];
    
    @try {
        if (self.isReachable)
        {
            [self setServiceResult:result andServiceError:error];
            ServiceManager *__weak weakService = self;
            
            [MBProgressHUD showHUDAddedTo:[self viewForIndicator] animated:YES];
            
            
            [self startConnectionWithRequest:[self requestWithURLString:[NSString stringWithFormat:@"/SendEnquery?UserID=%@&PingID=%@",userId,cardId] forMethod:@"GET"]
             
                                      Result:^(id result){
                                          
                                          [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                                          if (isLogging)
                                          {
                                              NSString *__autoreleasing str = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
                                              NSLog(@"Result is %@",str);
                                          }
                                          NSError *__autoreleasing e = nil;
                                          NSDictionary* __autoreleasing json = [NSJSONSerialization
                                                                                JSONObjectWithData:[weakService responseData]
                                                                                
                                                                                options:kNilOptions
                                                                                error:&e];
                                          if (!e) {
                                              @autoreleasepool {
                                                  @try {
                                                      NSArray* arr = (NSArray *)json;
                                                      
                                                      [weakService serviceResult] (arr);
                                                  }
                                                  @catch (NSException *e)
                                                  {
                                                      
                                                  }
                                              }
                                          }
                                          
                                      }
                                       error:^(NSError *error)
             {
                 if (isLogging)
                     NSLog(@"Error is %@",error);
                 [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                 [weakService serviceError] (error);
             }];
        }
        else
        {
            [self setServiceResult:result andServiceError:error];
            serviceError([self noInternetError]);
        }
    }
    @catch (NSException *exception) {
        ///  [Global writeToLogFile:[exception description]];
    }
    @finally {
        
    }

}

-(void)sendFeedBackFromUser:(NSString *)userId Feedback:(NSString *)userFeedback result:(AppServiceResult)result error:(AppServiceError)error
{
    [self reachabilityCheck];
    
    @try {
        if (self.isReachable)
        {
            [self setServiceResult:result andServiceError:error];
            ServiceManager *__weak weakService = self;
            
            [MBProgressHUD showHUDAddedTo:[self viewForIndicator] animated:YES];
            
            
            [self startConnectionWithRequest:[self requestWithURLString:[NSString stringWithFormat:@"/SendFeedback?UserID=%@&FeedbackText=%@",userId,userFeedback] forMethod:@"GET"]
             
                                      Result:^(id result){
                                          
                                          [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                                          if (isLogging)
                                          {
                                              NSString *__autoreleasing str = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
                                              NSLog(@"Result is %@",str);
                                          }
                                          NSError *__autoreleasing e = nil;
                                          NSDictionary* __autoreleasing json = [NSJSONSerialization
                                                                                JSONObjectWithData:[weakService responseData]
                                                                                
                                                                                options:kNilOptions
                                                                                error:&e];
                                          if (!e) {
                                              @autoreleasepool {
                                                  @try {
                                                      NSArray* arr = (NSArray *)json;
                                                      
                                                      [weakService serviceResult] (arr);
                                                  }
                                                  @catch (NSException *e)
                                                  {
                                                      
                                                  }
                                              }
                                          }
                                          
                                      }
                                       error:^(NSError *error)
             {
                 if (isLogging)
                     NSLog(@"Error is %@",error);
                 [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                 [weakService serviceError] (error);
             }];
        }
        else
        {
            [self setServiceResult:result andServiceError:error];
            serviceError([self noInternetError]);
        }
    }
    @catch (NSException *exception) {
        ///  [Global writeToLogFile:[exception description]];
    }
    @finally {
        
    }
}

-(void)updateProfileStatusForUser:(NSString *)userId ProfileStatus:(NSString *)status result:(AppServiceResult)result error:(AppServiceError)error
{
    [self reachabilityCheck];
    
    @try {
        if (self.isReachable)
        {
            [self setServiceResult:result andServiceError:error];
            ServiceManager *__weak weakService = self;
            
            [MBProgressHUD showHUDAddedTo:[self viewForIndicator] animated:YES];
            
            
            [self startConnectionWithRequest:[self requestWithURLString:[NSString stringWithFormat:@"/UpdateProfileStatus?UserID=%@&Profile=%@",userId,status] forMethod:@"GET"]
             
                                      Result:^(id result){
                                          
                                          [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                                          if (isLogging)
                                          {
                                              NSString *__autoreleasing str = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
                                              NSLog(@"Result is %@",str);
                                          }
                                          NSError *__autoreleasing e = nil;
                                          NSDictionary* __autoreleasing json = [NSJSONSerialization
                                                                                JSONObjectWithData:[weakService responseData]
                                                                                
                                                                                options:kNilOptions
                                                                                error:&e];
                                          if (!e) {
                                              @autoreleasepool {
                                                  @try {
                                                      NSArray* arr = (NSArray *)json;
                                                      
                                                      [weakService serviceResult] (arr);
                                                  }
                                                  @catch (NSException *e)
                                                  {
                                                      
                                                  }
                                              }
                                          }
                                          
                                      }
                                       error:^(NSError *error)
             {
                 if (isLogging)
                     NSLog(@"Error is %@",error);
                 [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                 [weakService serviceError] (error);
             }];
        }
        else
        {
            [self setServiceResult:result andServiceError:error];
            serviceError([self noInternetError]);
        }
    }
    @catch (NSException *exception) {
        ///  [Global writeToLogFile:[exception description]];
    }
    @finally {
        
    }

}


-(void)changePasswordForUser:(NSString *)userId Password:(NSString *)newPassword result:(AppServiceResult)result error:(AppServiceError)error
{
    [self reachabilityCheck];
    
    @try {
        if (self.isReachable)
        {
            [self setServiceResult:result andServiceError:error];
            ServiceManager *__weak weakService = self;
            
            [MBProgressHUD showHUDAddedTo:[self viewForIndicator] animated:YES];
            
            
            [self startConnectionWithRequest:[self requestWithURLString:[NSString stringWithFormat:@"/ChangePassword?UserID=%@&Password=%@",userId,newPassword] forMethod:@"GET"]
             
                                      Result:^(id result){
                                          
                                          [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                                          if (isLogging)
                                          {
                                              NSString *__autoreleasing str = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
                                              NSLog(@"Result is %@",str);
                                          }
                                          NSError *__autoreleasing e = nil;
                                          NSDictionary* __autoreleasing json = [NSJSONSerialization
                                                                                JSONObjectWithData:[weakService responseData]
                                                                                
                                                                                options:kNilOptions
                                                                                error:&e];
                                          if (!e) {
                                              @autoreleasepool {
                                                  @try {
                                                      NSArray* arr = (NSArray *)json;
                                                      
                                                      [weakService serviceResult] (arr);
                                                  }
                                                  @catch (NSException *e)
                                                  {
                                                      
                                                  }
                                              }
                                          }
                                          
                                      }
                                       error:^(NSError *error)
             {
                 if (isLogging)
                     NSLog(@"Error is %@",error);
                 [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                 [weakService serviceError] (error);
             }];
        }
        else
        {
            [self setServiceResult:result andServiceError:error];
            serviceError([self noInternetError]);
        }
    }
    @catch (NSException *exception) {
        ///  [Global writeToLogFile:[exception description]];
    }
    @finally {
        
    }

}


-(void)deletMyCardForUserID:(NSString *)userId result:(AppServiceResult)result error:(AppServiceError)error
{
    [self reachabilityCheck];
    
    @try {
        if (self.isReachable)
        {
            [self setServiceResult:result andServiceError:error];
            ServiceManager *__weak weakService = self;
            
            [MBProgressHUD showHUDAddedTo:[self viewForIndicator] animated:YES];
            
            
            [self startConnectionWithRequest:[self requestWithURLString:[NSString stringWithFormat:@"/DeleteMyCard?UserID=%@",userId] forMethod:@"GET"]
             
                                      Result:^(id result){
                                          
                                          [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                                          if (isLogging)
                                          {
                                              NSString *__autoreleasing str = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
                                              NSLog(@"Result is %@",str);
                                          }
                                          NSError *__autoreleasing e = nil;
                                          NSDictionary* __autoreleasing json = [NSJSONSerialization
                                                                                JSONObjectWithData:[weakService responseData]
                                                                                
                                                                                options:kNilOptions
                                                                                error:&e];
                                          if (!e) {
                                              @autoreleasepool {
                                                  @try {
                                                      NSArray* arr = (NSArray *)json;
                                                      
                                                      [weakService serviceResult] (arr);
                                                  }
                                                  @catch (NSException *e)
                                                  {
                                                      
                                                  }
                                              }
                                          }
                                          
                                      }
                                       error:^(NSError *error)
             {
                 if (isLogging)
                     NSLog(@"Error is %@",error);
                 [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                 [weakService serviceError] (error);
             }];
        }
        else
        {
            [self setServiceResult:result andServiceError:error];
            serviceError([self noInternetError]);
        }
    }
    @catch (NSException *exception) {
        ///  [Global writeToLogFile:[exception description]];
    }
    @finally {
        
    }

}



-(void)GetAllTyperesult:(AppServiceResult)result error:(AppServiceError)error
{
    [self reachabilityCheck];
    
    @try {
        if (self.isReachable)
        {
            [self setServiceResult:result andServiceError:error];
            ServiceManager *__weak weakService = self;
            
            [MBProgressHUD showHUDAddedTo:[self viewForIndicator] animated:YES];
            
            
            [self startConnectionWithRequest:[self requestWithURLString:[NSString stringWithFormat:@"/GetAllType?"] forMethod:@"GET"]
             
                                      Result:^(id result){
                                          
                                          [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                                          if (isLogging)
                                          {
                                              NSString *__autoreleasing str = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
                                              NSLog(@"Result is %@",str);
                                          }
                                          NSError *__autoreleasing e = nil;
                                          NSDictionary* __autoreleasing json = [NSJSONSerialization
                                                                                JSONObjectWithData:[weakService responseData]
                                                                                
                                                                                options:kNilOptions
                                                                                error:&e];
                                          if (!e) {
                                              @autoreleasepool {
                                                  @try {
                                                      NSArray* arr = (NSArray *)json;
                                                      
                                                      [weakService serviceResult] (arr);
                                                  }
                                                  @catch (NSException *e)
                                                  {
                                                      
                                                  }
                                              }
                                          }
                                          
                                      }
                                       error:^(NSError *error)
             {
                 if (isLogging)
                     NSLog(@"Error is %@",error);
                 [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                 [weakService serviceError] (error);
             }];
        }
        else
        {
            [self setServiceResult:result andServiceError:error];
            serviceError([self noInternetError]);
        }
    }
    @catch (NSException *exception) {
        ///  [Global writeToLogFile:[exception description]];
    }
    @finally {
        
    }
 
}

-(void)GetCitiesByCountryID:(NSString *)countryId result:(AppServiceResult)result error:(AppServiceError)error
{
    [self reachabilityCheck];
    
    @try {
        if (self.isReachable)
        {
            [self setServiceResult:result andServiceError:error];
            ServiceManager *__weak weakService = self;
            
            [MBProgressHUD showHUDAddedTo:[self viewForIndicator] animated:YES];
            
            
            [self startConnectionWithRequest:[self requestWithURLString:[NSString stringWithFormat:@"/GetCitiesByCountryID?Country_id=%@",countryId] forMethod:@"GET"]
             
                                      Result:^(id result){
                                          
                                          [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                                          if (isLogging)
                                          {
                                              NSString *__autoreleasing str = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
                                              NSLog(@"Result is %@",str);
                                          }
                                          NSError *__autoreleasing e = nil;
                                          NSDictionary* __autoreleasing json = [NSJSONSerialization
                                                                                JSONObjectWithData:[weakService responseData]
                                                                                
                                                                                options:kNilOptions
                                                                                error:&e];
                                          if (!e) {
                                              @autoreleasepool {
                                                  @try {
                                                      NSArray* arr = (NSArray *)json;
                                                      
                                                      [weakService serviceResult] (arr);
                                                  }
                                                  @catch (NSException *e)
                                                  {
                                                      
                                                  }
                                              }
                                          }
                                          
                                      }
                                       error:^(NSError *error)
             {
                 if (isLogging)
                     NSLog(@"Error is %@",error);
                 [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                 [weakService serviceError] (error);
             }];
        }
        else
        {
            [self setServiceResult:result andServiceError:error];
            serviceError([self noInternetError]);
        }
    }
    @catch (NSException *exception) {
        ///  [Global writeToLogFile:[exception description]];
    }
    @finally {
        
    }

}


-(void)GetAdvanceSearchForText:(NSString *)searchText BussinesstypeId:(NSString *)bussinesstype City:(NSString *)cityId result:(AppServiceResult)result error:(AppServiceError)error
{
    [self reachabilityCheck];
    
    @try {
        if (self.isReachable)
        {
            [self setServiceResult:result andServiceError:error];
            ServiceManager *__weak weakService = self;
            
            [MBProgressHUD showHUDAddedTo:[self viewForIndicator] animated:YES];
            
            
            [self startConnectionWithRequest:[self requestWithURLString:[NSString stringWithFormat:@"/GetAdvanceSearch?Type=%@&City=%@&Text=%@",bussinesstype,cityId,searchText] forMethod:@"GET"]
             
                                      Result:^(id result){
                                          
                                          [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                                          if (isLogging)
                                          {
                                              NSString *__autoreleasing str = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
                                              NSLog(@"Result is %@",str);
                                          }
                                          NSError *__autoreleasing e = nil;
                                          NSDictionary* __autoreleasing json = [NSJSONSerialization
                                                                                JSONObjectWithData:[weakService responseData]
                                                                                
                                                                                options:kNilOptions
                                                                                error:&e];
                                          if (!e) {
                                              @autoreleasepool {
                                                  @try {
                                                      NSArray* arr = (NSArray *)json;
                                                      
                                                      [weakService serviceResult] (arr);
                                                  }
                                                  @catch (NSException *e)
                                                  {
                                                      
                                                  }
                                              }
                                          }
                                          
                                      }
                                       error:^(NSError *error)
             {
                 if (isLogging)
                     NSLog(@"Error is %@",error);
                 [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                 [weakService serviceError] (error);
             }];
        }
        else
        {
            [self setServiceResult:result andServiceError:error];
            serviceError([self noInternetError]);
        }
    }
    @catch (NSException *exception) {
        ///  [Global writeToLogFile:[exception description]];
    }
    @finally {
        
    }

}


-(void)GetMycardsAdvanceSearchForText:(NSString *)searchText BussinesstypeId:(NSString *)bussinesstype City:(NSString *)cityId UserId:(NSString *)userId result:(AppServiceResult)result error:(AppServiceError)error
{
    [self reachabilityCheck];
    
    @try {
        if (self.isReachable)
        {
            [self setServiceResult:result andServiceError:error];
            ServiceManager *__weak weakService = self;
            
            [MBProgressHUD showHUDAddedTo:[self viewForIndicator] animated:YES];
            
            
            [self startConnectionWithRequest:[self requestWithURLString:[NSString stringWithFormat:@"/GetMycardsAdvanceSearch?Type=%@&City=%@&Text=%@&UserID=%@",bussinesstype,cityId,searchText,userId] forMethod:@"GET"]
             
                                      Result:^(id result){
                                          
                                          [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                                          if (isLogging)
                                          {
                                              NSString *__autoreleasing str = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
                                              NSLog(@"Result is %@",str);
                                          }
                                          NSError *__autoreleasing e = nil;
                                          NSDictionary* __autoreleasing json = [NSJSONSerialization
                                                                                JSONObjectWithData:[weakService responseData]
                                                                                
                                                                                options:kNilOptions
                                                                                error:&e];
                                          if (!e) {
                                              @autoreleasepool {
                                                  @try {
                                                      NSArray* arr = (NSArray *)json;
                                                      
                                                      [weakService serviceResult] (arr);
                                                  }
                                                  @catch (NSException *e)
                                                  {
                                                      
                                                  }
                                              }
                                          }
                                          
                                      }
                                       error:^(NSError *error)
             {
                 if (isLogging)
                     NSLog(@"Error is %@",error);
                 [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                 [weakService serviceError] (error);
             }];
        }
        else
        {
            [self setServiceResult:result andServiceError:error];
            serviceError([self noInternetError]);
        }
    }
    @catch (NSException *exception) {
        ///  [Global writeToLogFile:[exception description]];
    }
    @finally {
        
    }

}



-(void)getTheCategoryresult:(AppServiceResult)result error:(AppServiceError)error
{
    @try {
        if (self.isReachable)
        {
            [self setServiceResult:result andServiceError:error];
            ServiceManager *__weak weakService = self;
            
            [MBProgressHUD showHUDAddedTo:[self viewForIndicator] animated:YES];
            
        http://192.168.1.5:1421/CPAPI.svc/Login?TokenNo=taflJ0GMbvgVe3m2b7ryDQ&Email=p@p.com&Password=password
            
            
            
            [self startConnectionWithRequest:[self requestWithURLString:[NSString stringWithFormat:@"/business_types?api_key=b4b76559232537e34ccd597ab07eec1a"] forMethod:@"GET"]
             
                                      Result:^(id result){
                                          
                                          [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                                          if (isLogging)
                                          {
                                              NSString *__autoreleasing str = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
                                              NSLog(@"Result is %@",str);
                                          }
                                          NSError *__autoreleasing e = nil;
                                          NSDictionary* __autoreleasing json = [NSJSONSerialization
                                                                                JSONObjectWithData:[weakService responseData]
                                                                                
                                                                                options:kNilOptions
                                                                                error:&e];
                                          if (!e) {
                                              @autoreleasepool {
                                                  @try {
                                                      NSArray* arr = (NSArray *)json;
                                                      
                                                      [weakService serviceResult] (arr);
                                                  }
                                                  @catch (NSException *e)
                                                  {
                                                      
                                                  }
                                              }
                                          }
                                          
                                      }
                                       error:^(NSError *error)
             {
                 if (isLogging)
                     NSLog(@"Error is %@",error);
                 [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                 [weakService serviceError] (error);
             }];
        }
        else
        {
            [self setServiceResult:result andServiceError:error];
            serviceError([self noInternetError]);
        }
    }
    @catch (NSException *exception) {
        ///  [Global writeToLogFile:[exception description]];
    }
    @finally {
        
    }

}

-(void)getResultOnBasisOdCategorySelectedId :(NSString *)idOfCategory forUserId:(NSString *)userId result:(AppServiceResult)result error:(AppServiceError)error
{
    @try {
        if (self.isReachable)
        {
            [self setServiceResult:result andServiceError:error];
            ServiceManager *__weak weakService = self;
            
            [MBProgressHUD showHUDAddedTo:[self viewForIndicator] animated:YES];
            
        http://192.168.1.5:1421/CPAPI.svc/Login?TokenNo=taflJ0GMbvgVe3m2b7ryDQ&Email=p@p.com&Password=password
            
            
            
            [self startConnectionWithRequest:[self requestWithURLString:[NSString stringWithFormat:@"/business?api_key=b4b76559232537e34ccd597ab07eec1a&type=%@&user_id=%@",idOfCategory,userId] forMethod:@"GET"]
             
                                      Result:^(id result){
                                          
                                          [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                                          if (isLogging)
                                          {
                                              NSString *__autoreleasing str = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
                                              NSLog(@"Result is %@",str);
                                          }
                                          NSError *__autoreleasing e = nil;
                                          NSDictionary* __autoreleasing json = [NSJSONSerialization
                                                                                JSONObjectWithData:[weakService responseData]
                                                                                
                                                                                options:kNilOptions
                                                                                error:&e];
                                          if (!e) {
                                              @autoreleasepool {
                                                  @try {
                                                      NSArray* arr = (NSArray *)json;
                                                      
                                                      [weakService serviceResult] (arr);
                                                  }
                                                  @catch (NSException *e)
                                                  {
                                                      
                                                  }
                                              }
                                          }
                                          
                                      }
                                       error:^(NSError *error)
             {
                 if (isLogging)
                     NSLog(@"Error is %@",error);
                 [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                 [weakService serviceError] (error);
             }];
        }
        else
        {
            [self setServiceResult:result andServiceError:error];
            serviceError([self noInternetError]);
        }
    }
    @catch (NSException *exception) {
        ///  [Global writeToLogFile:[exception description]];
    }
    @finally {
        
    }
    

}


//http://wonderwidgetsusa.com/v1/api/coupon?%20business=1&api_key=b4b76559232537e34ccd597ab07eec1a

-(void)offerForSelectedBusinessId:(NSString *)businessId result:(AppServiceResult)result error:(AppServiceError)error
{
    @try {
        if (self.isReachable)
        {
            [self setServiceResult:result andServiceError:error];
            ServiceManager *__weak weakService = self;
            
            [MBProgressHUD showHUDAddedTo:[self viewForIndicator] animated:YES];
            
        http://192.168.1.5:1421/CPAPI.svc/Login?TokenNo=taflJ0GMbvgVe3m2b7ryDQ&Email=p@p.com&Password=password
            
            
            
            [self startConnectionWithRequest:[self requestWithURLString:[NSString stringWithFormat:@"/coupon?business=%@&api_key=b4b76559232537e34ccd597ab07eec1a",businessId] forMethod:@"GET"]
             
                                      Result:^(id result){
                                          
                                          [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                                          if (isLogging)
                                          {
                                              NSString *__autoreleasing str = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
                                              NSLog(@"Result is %@",str);
                                          }
                                          NSError *__autoreleasing e = nil;
                                          NSDictionary* __autoreleasing json = [NSJSONSerialization
                                                                                JSONObjectWithData:[weakService responseData]
                                                                                
                                                                                options:kNilOptions
                                                                                error:&e];
                                          if (!e) {
                                              @autoreleasepool {
                                                  @try {
                                                      NSArray* arr = (NSArray *)json;
                                                      
                                                      [weakService serviceResult] (arr);
                                                  }
                                                  @catch (NSException *e)
                                                  {
                                                      
                                                  }
                                              }
                                          }
                                          
                                      }
                                       error:^(NSError *error)
             {
                 if (isLogging)
                     NSLog(@"Error is %@",error);
                 [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                 [weakService serviceError] (error);
             }];
        }
        else
        {
            [self setServiceResult:result andServiceError:error];
            serviceError([self noInternetError]);
        }
    }
    @catch (NSException *exception) {
        ///  [Global writeToLogFile:[exception description]];
    }
    @finally {
        
    }
    

}

-(void)addToFavouriteforBussiness :(NSString *)bussinessId userId:(NSString *)userId result:(AppServiceResult)result error:(AppServiceError)error;
{
    @try {
        if (self.isReachable)
        {
            [self setServiceResult:result andServiceError:error];
            ServiceManager *__weak weakService = self;
            
            [MBProgressHUD showHUDAddedTo:[self viewForIndicator] animated:YES];
            
        http://192.168.1.5:1421/CPAPI.svc/Login?TokenNo=taflJ0GMbvgVe3m2b7ryDQ&Email=p@p.com&Password=password
            
            
            
            [self startConnectionWithRequest:[self requestWithURLString:[NSString stringWithFormat:@"/addfav?business=%@&user=%@&api_key=b4b76559232537e34ccd597ab07eec1a",bussinessId,userId] forMethod:@"GET"]
             
                                      Result:^(id result){
                                          
                                          [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                                          if (isLogging)
                                          {
                                              NSString *__autoreleasing str = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
                                              NSLog(@"Result is %@",str);
                                          }
                                          NSError *__autoreleasing e = nil;
                                          NSDictionary* __autoreleasing json = [NSJSONSerialization
                                                                                JSONObjectWithData:[weakService responseData]
                                                                                
                                                                                options:kNilOptions
                                                                                error:&e];
                                          if (!e) {
                                              @autoreleasepool {
                                                  @try {
                                                      NSArray* arr = (NSArray *)json;
                                                      
                                                      [weakService serviceResult] (arr);
                                                  }
                                                  @catch (NSException *e)
                                                  {
                                                      
                                                  }
                                              }
                                          }
                                          
                                      }
                                       error:^(NSError *error)
             {
                 if (isLogging)
                     NSLog(@"Error is %@",error);
                 [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                 [weakService serviceError] (error);
             }];
        }
        else
        {
            [self setServiceResult:result andServiceError:error];
            serviceError([self noInternetError]);
        }
    }
    @catch (NSException *exception) {
        ///  [Global writeToLogFile:[exception description]];
    }
    @finally {
        
    }
}

-(void)deleteFavouriteforBussiness:(NSString *)bussinessId userId:(NSString *)userId result:(AppServiceResult)result error:(AppServiceError)error
{
    @try {
        if (self.isReachable)
        {
            [self setServiceResult:result andServiceError:error];
            ServiceManager *__weak weakService = self;
            
            [MBProgressHUD showHUDAddedTo:[self viewForIndicator] animated:YES];
            
        http://192.168.1.5:1421/CPAPI.svc/Login?TokenNo=taflJ0GMbvgVe3m2b7ryDQ&Email=p@p.com&Password=password
            
            
            
            [self startConnectionWithRequest:[self requestWithURLString:[NSString stringWithFormat:@"/deletefav?business=%@&user=%@&api_key=b4b76559232537e34ccd597ab07eec1a",bussinessId,userId] forMethod:@"GET"]
             
                                      Result:^(id result){
                                          
                                          [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                                          if (isLogging)
                                          {
                                              NSString *__autoreleasing str = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
                                              NSLog(@"Result is %@",str);
                                          }
                                          NSError *__autoreleasing e = nil;
                                          NSDictionary* __autoreleasing json = [NSJSONSerialization
                                                                                JSONObjectWithData:[weakService responseData]
                                                                                
                                                                                options:kNilOptions
                                                                                error:&e];
                                          if (!e) {
                                              @autoreleasepool {
                                                  @try {
                                                      NSArray* arr = (NSArray *)json;
                                                      
                                                      [weakService serviceResult] (arr);
                                                  }
                                                  @catch (NSException *e)
                                                  {
                                                      
                                                  }
                                              }
                                          }
                                          
                                      }
                                       error:^(NSError *error)
             {
                 if (isLogging)
                     NSLog(@"Error is %@",error);
                 [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                 [weakService serviceError] (error);
             }];
        }
        else
        {
            [self setServiceResult:result andServiceError:error];
            serviceError([self noInternetError]);
        }
    }
    @catch (NSException *exception) {
        ///  [Global writeToLogFile:[exception description]];
    }
    @finally {
        
    }

}

-(void)reedemCouponforBussiness:(NSString *)bussinessId userId:(NSString *)userId result:(AppServiceResult)result error:(AppServiceError)error
{
    @try {
        if (self.isReachable)
        {
            [self setServiceResult:result andServiceError:error];
            ServiceManager *__weak weakService = self;
            
            [MBProgressHUD showHUDAddedTo:[self viewForIndicator] animated:YES];
            
        http://192.168.1.5:1421/CPAPI.svc/Login?TokenNo=taflJ0GMbvgVe3m2b7ryDQ&Email=p@p.com&Password=password
            
            
            
            [self startConnectionWithRequest:[self requestWithURLString:[NSString stringWithFormat:@"/redeem_coupon?business=%@&user=%@&api_key=b4b76559232537e34ccd597ab07eec1a",bussinessId,userId] forMethod:@"GET"]
             
                                      Result:^(id result){
                                          
                                          [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                                          if (isLogging)
                                          {
                                              NSString *__autoreleasing str = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
                                              NSLog(@"Result is %@",str);
                                          }
                                          NSError *__autoreleasing e = nil;
                                          NSDictionary* __autoreleasing json = [NSJSONSerialization
                                                                                JSONObjectWithData:[weakService responseData]
                                                                                
                                                                                options:kNilOptions
                                                                                error:&e];
                                          if (!e) {
                                              @autoreleasepool {
                                                  @try {
                                                      NSArray* arr = (NSArray *)json;
                                                      
                                                      [weakService serviceResult] (arr);
                                                  }
                                                  @catch (NSException *e)
                                                  {
                                                      
                                                  }
                                              }
                                          }
                                          
                                      }
                                       error:^(NSError *error)
             {
                 if (isLogging)
                     NSLog(@"Error is %@",error);
                 [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                 [weakService serviceError] (error);
             }];
        }
        else
        {
            [self setServiceResult:result andServiceError:error];
            serviceError([self noInternetError]);
        }
    }
    @catch (NSException *exception) {
        ///  [Global writeToLogFile:[exception description]];
    }
    @finally {
        
    }

}

-(void)searchOnBasisOfZipCode :(NSString *)zipcode ForUser:(NSString *)userId result:(AppServiceResult)result error:(AppServiceError)error
{
    @try {
        if (self.isReachable)
        {
            [self setServiceResult:result andServiceError:error];
            ServiceManager *__weak weakService = self;
            
            [MBProgressHUD showHUDAddedTo:[self viewForIndicator] animated:YES];
            
        http://192.168.1.5:1421/CPAPI.svc/Login?TokenNo=taflJ0GMbvgVe3m2b7ryDQ&Email=p@p.com&Password=password
            
            
            
            [self startConnectionWithRequest:[self requestWithURLString:[NSString stringWithFormat:@"/business?zipcode=%@&api_key=b4b76559232537e34ccd597ab07eec1a&user_id=%@",zipcode,userId] forMethod:@"GET"]
             
                                      Result:^(id result){
                                          
                                          [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                                          if (isLogging)
                                          {
                                              NSString *__autoreleasing str = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
                                              NSLog(@"Result is %@",str);
                                          }
                                          NSError *__autoreleasing e = nil;
                                          NSDictionary* __autoreleasing json = [NSJSONSerialization
                                                                                JSONObjectWithData:[weakService responseData]
                                                                                
                                                                                options:kNilOptions
                                                                                error:&e];
                                          if (!e) {
                                              @autoreleasepool {
                                                  @try {
                                                      NSArray* arr = (NSArray *)json;
                                                      
                                                      [weakService serviceResult] (arr);
                                                  }
                                                  @catch (NSException *e)
                                                  {
                                                      
                                                  }
                                              }
                                          }
                                          
                                      }
                                       error:^(NSError *error)
             {
                 if (isLogging)
                     NSLog(@"Error is %@",error);
                 [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                 [weakService serviceError] (error);
             }];
        }
        else
        {
            [self setServiceResult:result andServiceError:error];
            serviceError([self noInternetError]);
        }
    }
    @catch (NSException *exception) {
        ///  [Global writeToLogFile:[exception description]];
    }
    @finally {
        
    }

}

-(void)closeByUserLocationLongitude:(float)longitude Latitude:(float)latitude ForUser:(NSString *)userId result:(AppServiceResult)result error:(AppServiceError)error
{
    @try {
        if (self.isReachable)
        {
            [self setServiceResult:result andServiceError:error];
            ServiceManager *__weak weakService = self;
            
            [MBProgressHUD showHUDAddedTo:[self viewForIndicator] animated:YES];
            
        http://192.168.1.5:1421/CPAPI.svc/Login?TokenNo=taflJ0GMbvgVe3m2b7ryDQ&Email=p@p.com&Password=password
            
            
            
            [self startConnectionWithRequest:[self requestWithURLString:[NSString stringWithFormat:@"/business?api_key=b4b76559232537e34ccd597ab07eec1a&user_id=%@&Lat=%f&Lon=%f&Radius=5",userId,latitude,longitude] forMethod:@"GET"]
             
                                      Result:^(id result){
                                          
                                          [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                                          if (isLogging)
                                          {
                                              NSString *__autoreleasing str = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
                                              NSLog(@"Result is %@",str);
                                          }
                                          NSError *__autoreleasing e = nil;
                                          NSDictionary* __autoreleasing json = [NSJSONSerialization
                                                                                JSONObjectWithData:[weakService responseData]
                                                                                
                                                                                options:kNilOptions
                                                                                error:&e];
                                          if (!e) {
                                              @autoreleasepool {
                                                  @try {
                                                      NSArray* arr = (NSArray *)json;
                                                      
                                                      [weakService serviceResult] (arr);
                                                  }
                                                  @catch (NSException *e)
                                                  {
                                                      
                                                  }
                                              }
                                          }
                                          
                                      }
                                       error:^(NSError *error)
             {
                 if (isLogging)
                     NSLog(@"Error is %@",error);
                 [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                 [weakService serviceError] (error);
             }];
        }
        else
        {
            [self setServiceResult:result andServiceError:error];
            serviceError([self noInternetError]);
        }
    }
    @catch (NSException *exception) {
        ///  [Global writeToLogFile:[exception description]];
    }
    @finally {
        
    }
    
}

-(void)offerPageDataForUser:(NSString *)userId result:(AppServiceResult)result error:(AppServiceError)error
{
    @try {
        if (self.isReachable)
        {
            [self setServiceResult:result andServiceError:error];
            ServiceManager *__weak weakService = self;
            
            [MBProgressHUD showHUDAddedTo:[self viewForIndicator] animated:YES];
            
        http://192.168.1.5:1421/CPAPI.svc/Login?TokenNo=taflJ0GMbvgVe3m2b7ryDQ&Email=p@p.com&Password=password
            
            
            
            [self startConnectionWithRequest:[self requestWithURLString:[NSString stringWithFormat:@"/business?api_key=b4b76559232537e34ccd597ab07eec1a&user_id=%@",userId] forMethod:@"GET"]
             
                                      Result:^(id result){
                                          
                                          [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                                          if (isLogging)
                                          {
                                              NSString *__autoreleasing str = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
                                              NSLog(@"Result is %@",str);
                                          }
                                          NSError *__autoreleasing e = nil;
                                          NSDictionary* __autoreleasing json = [NSJSONSerialization
                                                                                JSONObjectWithData:[weakService responseData]
                                                                                
                                                                                options:kNilOptions
                                                                                error:&e];
                                          if (!e) {
                                              @autoreleasepool {
                                                  @try {
                                                      NSArray* arr = (NSArray *)json;
                                                      
                                                      [weakService serviceResult] (arr);
                                                  }
                                                  @catch (NSException *e)
                                                  {
                                                      
                                                  }
                                              }
                                          }
                                          
                                      }
                                       error:^(NSError *error)
             {
                 if (isLogging)
                     NSLog(@"Error is %@",error);
                 [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                 [weakService serviceError] (error);
             }];
        }
        else
        {
            [self setServiceResult:result andServiceError:error];
            serviceError([self noInternetError]);
        }
    }
    @catch (NSException *exception) {
        ///  [Global writeToLogFile:[exception description]];
    }
    @finally {
        
    }

}

-(void)getMoreBusinessDataForUser:(NSString *)userId Page:(NSInteger)fromPage Type:(NSString *)businessType Zipcode:(NSString *)zipCode result:(AppServiceResult)result error:(AppServiceError)error
{
    @try {
        if (self.isReachable)
        {
            [self setServiceResult:result andServiceError:error];
            ServiceManager *__weak weakService = self;
            
            [MBProgressHUD showHUDAddedTo:[self viewForIndicator] animated:YES];
            
        http://192.168.1.5:1421/CPAPI.svc/Login?TokenNo=taflJ0GMbvgVe3m2b7ryDQ&Email=p@p.com&Password=password
            
            
            
            [self startConnectionWithRequest:[self requestWithURLString:[NSString stringWithFormat:@"/business?api_key=b4b76559232537e34ccd597ab07eec1a&page=%d&limit=20&user_id=%@&type=%@&zipcode=%@",fromPage,userId,businessType,zipCode] forMethod:@"GET"]
             
                                      Result:^(id result){
                                          
                                          [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                                          if (isLogging)
                                          {
                                              NSString *__autoreleasing str = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
                                              NSLog(@"Result is %@",str);
                                          }
                                          NSError *__autoreleasing e = nil;
                                          NSDictionary* __autoreleasing json = [NSJSONSerialization
                                                                                JSONObjectWithData:[weakService responseData]
                                                                                
                                                                                options:kNilOptions
                                                                                error:&e];
                                          if (!e) {
                                              @autoreleasepool {
                                                  @try {
                                                      NSArray* arr = (NSArray *)json;
                                                      
                                                      [weakService serviceResult] (arr);
                                                  }
                                                  @catch (NSException *e)
                                                  {
                                                      
                                                  }
                                              }
                                          }
                                          
                                      }
                                       error:^(NSError *error)
             {
                 if (isLogging)
                     NSLog(@"Error is %@",error);
                 [MBProgressHUD hideAllHUDsForView:[weakService viewForIndicator] animated:YES];
                 [weakService serviceError] (error);
             }];
        }
        else
        {
            [self setServiceResult:result andServiceError:error];
            serviceError([self noInternetError]);
        }
    }
    @catch (NSException *exception) {
        ///  [Global writeToLogFile:[exception description]];
    }
    @finally {
        
    }

}
 
 */



@end
