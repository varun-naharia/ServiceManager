# To Use 

#import "ServiceManager.h"
self.serviceManager = [[ServiceManager alloc]init];
[self.serviceManager getLoginVerificationForUserName:username Password:password Country:country result:^(id result)
{
    NSLog(@"%@",result);
} error:^(NSError *err)
{
    
}
