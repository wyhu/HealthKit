//
//  ViewController.m
//  HealthKitDemo
//
//  Created by huweiya on 16/4/14.
//  Copyright © 2016年 5i5j. All rights reserved.
//

#import "ViewController.h"
#import <HealthKit/HealthKit.h>
#import "TableViewController.h"

@interface ViewController ()
{
    NSMutableArray *arr;
    
    
    __weak IBOutlet UILabel *sex;
    
    __weak IBOutlet UILabel *heigth;
    
    __weak IBOutlet UILabel *mass;
    
    
    
    __weak IBOutlet UILabel *other;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //这里是 关于 一个 HealthKit的demo
    
    
    //判断当前设备是否 支持健康
   BOOL isHealthDataAvailable =  [HKHealthStore isHealthDataAvailable];

    
    
    HKHealthStore *healthStore = [[HKHealthStore alloc] init];
    
    //写入
    // Share body mass, height and body mass index
    NSSet *shareObjectTypes = [NSSet setWithObjects:
                               [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass],//体重
                               [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight],//身高
                               [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMassIndex],//体重身高指数
                               nil];
    //读取
    // Read date of birth, biological sex and step count
    NSSet *readObjectTypes = [NSSet setWithObjects:
                              [HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierDateOfBirth],//出生日期
                              [HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierBiologicalSex],//性别
                              [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount],//步数
                              nil];
    
    // Request access
    //1、第一个参数传入一个NSSet类型数据，用于告知用户，我的app可能会在你的健康数据库中修改这些选项数据(显然目前我们不需要，传nil)
//    2、第二个参数也是传入NSSet类型数据，告知用户，我的app可能会从你的数据库中读取以下几项数据
    
//    第三个是授权许可回调，这里的BOOL值success不能用于区分用户是否允许应用向数据库存取数据，这一点评论区有人提到，我也对此进行了测试，发现确实即使用户不允许，该值也为YES
    [healthStore requestAuthorizationToShareTypes:shareObjectTypes
                                  readTypes:readObjectTypes
                                 completion:^(BOOL success, NSError *error) {
                                     
                                     if(success == YES)
                                     {
                                         // ...
                                     }
                                     else
                                     {
                                         // Determine if it was an error or if the
                                         // user just canceld the authorization request
                                     }
                                     
                                 }];
    
    
    
    /*
     1、第一段通过传入一个枚举值HKQuantityTypeIdentifierStepCount来创建一个样品类的实例，用于告知，我接下来要获取的数据是步数>2、第二段代码通过创建一个NSPredicate类的实例，用于获取在某个时间段的数据，这里startDate和endDate传入nil，表示获取全部数据，第三个参数传入一个Option，里面有三个值，这个参数我试验了下不同的值代入，发现返回的结果都是一样的，要是有谁知道这个值是做什么用的麻烦告知我一声~
     3、第三段代码创建了一个NSSortDescriptor类实例，用于对查询的结果排序
     4、第四段代码通过调用HKSampleQuery类的实例方法获取所需数据
     5、最后一行代码用于执行数据查询操作
    */
    
    
    //获取步数
    HKSampleType *sampleType = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:nil endDate:nil options:HKQueryOptionStrictStartDate];
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierStartDate ascending:YES];
    
    HKSampleQuery *sampleQuery = [[HKSampleQuery alloc] initWithSampleType:sampleType predicate:predicate limit:HKObjectQueryNoLimit sortDescriptors:@[sortDescriptor] resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error) {
        if(!error && results) {
            for(HKQuantitySample *samples in results) {
                NSLog(@"%@ 至 %@ : %@", samples.startDate, samples.endDate, samples.quantity);
            }
        } else {
            //error
        }
    }];
//    [healthStore executeQuery:sampleQuery];
    
    
    /*
     有时候需求并不需要了解这么详尽的数据，只希望获取每小时、每天或者每月的步数，那么我们就需要用到另一个新类HKStatisticsCollectionQuery进行数据的分段采集
     */
    
    
    
    
    
    
    HKQuantityType *quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    
    
    
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.day = 1;//天
    
    

    arr = [NSMutableArray array];
    
    
    HKStatisticsCollectionQuery *collectionQuery = [[HKStatisticsCollectionQuery alloc] initWithQuantityType:quantityType quantitySamplePredicate:nil options: HKStatisticsOptionCumulativeSum | HKStatisticsOptionSeparateBySource anchorDate:[NSDate dateWithTimeIntervalSince1970:0] intervalComponents:dateComponents];
    
    
    collectionQuery.initialResultsHandler = ^(HKStatisticsCollectionQuery *query, HKStatisticsCollection * __nullable result, NSError * __nullable error) {
        
        for (HKStatistics *statistic in result.statistics) {
//            NSLog(@"开始日期：：：%@", statistic.startDate);
            
            
            for (HKSource *source in statistic.sources) {
                
                if ([source.name isEqualToString:[UIDevice currentDevice].name]) {
                    
                    NSInteger buShu = (NSInteger)[[statistic sumQuantityForSource:source] doubleValueForUnit:[HKUnit countUnit]];
    
                    
                    NSLog(@"日期：%@=======步数是:%ld",statistic.startDate, buShu);

                    
                    
                    
                    NSString *str = [NSString stringWithFormat:@"%@---%@步",[self stringFromDate:statistic.startDate],[NSString stringWithFormat:@"%ld",buShu]];
                    
            
                    
                    [arr addObject:str];

                    
//                    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//                        // 显示时间2s
//
//                        dispatch_async(dispatch_get_main_queue(), ^{
//                            // 让弹框消失
//                        });
//                        
//                        
//                    });
                
                    

                    
                }

            }
        }
        
        
        
        
        
    };
    
    [healthStore executeQuery:collectionQuery];
    
    
    
    //获取性别
    NSError *error;
    
    HKBiologicalSexObject *bioSex = [healthStore biologicalSexWithError:&error];
    

    
    switch (bioSex.biologicalSex) {
        case HKBiologicalSexNotSet: {
            NSLog(@"没有设置");
            
            sex.text = @"没有设置";
            break;
        }
        case HKBiologicalSexFemale: {
            NSLog(@"女");
            sex.text = @"女";

            break;
        }
        case HKBiologicalSexMale: {
            NSLog(@"男");
            sex.text = @"男";

            break;
        }
        case HKBiologicalSexOther: {
            NSLog(@"其他");
            sex.text = @"其他";

            break;
        }
    }

    
    
    
    
}


/**
 *  按钮点击事件
 *
 *  @param sender sender
 */
- (IBAction)itemAction:(UIBarButtonItem *)sender {
    
    TableViewController *table = [[TableViewController alloc] init];
    
    
    
    table.arr = arr;
    
    [self.navigationController pushViewController:table animated:YES];
    
    
}


//NSDate转NSString

-(NSString*)stringFromDate:(NSDate*)date

{
    
    //获取系统当前时间
    
    //用于格式化NSDate对象
    
    NSDateFormatter*dateFormatter=[[NSDateFormatter alloc]init];
    
    //设置格式：zzz表示时区
    
    [dateFormatter setDateFormat:@"yyyy年MM月dd日"];
    
    //NSDate转NSString
    
    NSString *currentDateString=[dateFormatter stringFromDate:date];
    
    //输出currentDateString

    return currentDateString;
    
}










- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
