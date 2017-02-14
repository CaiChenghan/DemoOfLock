//
//  ViewController.m
//  DemoOfLock
//
//  Created by 蔡成汉 on 2017/2/13.
//  Copyright © 2017年 上海泰侠网络科技有限公司. All rights reserved.
//

#import "ViewController.h"
#import <libkern/OSAtomic.h>
#import <pthread.h>

@interface ViewController ()<UITableViewDataSource,UITableViewDelegate>

/**
 tableView
 */
@property (nonatomic , strong) UITableView *tableView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _tableView = [[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    [self.view addSubview:_tableView];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 9;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    cell.textLabel.text = [NSString stringWithFormat:@"%ld",(long)indexPath.row];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self creatTask:indexPath.row];
}

-(void)creatTask:(NSInteger)type{
    //自定义并行队列
    dispatch_queue_t queue = dispatch_queue_create("com.jiadai.demoOfLock", DISPATCH_QUEUE_CONCURRENT);
    if (type == 0) {
        //NSLock
        NSLock *lock = [[NSLock alloc]init];
        __block int a = 0;
        dispatch_async(queue, ^{
            NSLog(@"线程1开始任务");
            [lock lock];
            for (int i = 0; i<5; i++) {
                sleep(1);
                a = a +1;
                NSLog(@"线程1执行任务a = %d",a);
                if (i==4) {
                    sleep(1);
                }
            }
            [lock unlock];
            NSLog(@"线程1解锁成功");
        });
        
        dispatch_async(queue, ^{
            NSLog(@"线程2开始任务");
            [lock lock];
            for (int i = 0; i<3; i++) {
                sleep(1);
                a = a +1;
                NSLog(@"线程2执行任务a = %d",a);
                if (i==2) {
                    sleep(1);
                }
            }
            [lock unlock];
            NSLog(@"线程2解锁成功");
        });
    }
    else if (type == 1){
        //@synchronized
        __block int b1 = 0;
        __block int b2 = 0;
        dispatch_async(queue, ^{
            NSLog(@"线程1开始任务");
            @synchronized (self) {
                for (int i = 0; i<3; i++) {
                    sleep(1);
                    b1 = b1 +1;
                    NSLog(@"线程1执行任务b1 = %d",b1);
                    if (i==2) {
                        sleep(1);
                    }
                }
            }
        });
        dispatch_async(queue, ^{
            NSLog(@"线程2开始任务");
            @synchronized (self) {
                for (int i = 0; i<3; i++) {
                    sleep(1);
                    b2 = b2 +1;
                    NSLog(@"线程2执行任务b2 = %d",b2);
                    if (i==2) {
                        sleep(1);
                    }
                }
            }
        });
    }
    else if (type == 2){
        //NSConditionLock
        NSConditionLock *lock = [[NSConditionLock alloc]initWithCondition:0];
        __block int c = 0;
        dispatch_async(queue, ^{
            NSLog(@"线程1开始任务");
            [lock lockWhenCondition:0];
            for (int i = 0; i<3; i++) {
                sleep(1);
                c = c +1;
                NSLog(@"线程1执行任务c = %d",c);
            }
            [lock unlockWithCondition:1];
        });
        dispatch_async(queue, ^{
            NSLog(@"线程2开始任务");
            [lock lockWhenCondition:1];
            for (int i = 0; i<3; i++) {
                sleep(1);
                c = c +1;
                NSLog(@"线程2执行任务c = %d",c);
            }
            [lock unlockWithCondition:2];
        });
        dispatch_async(queue, ^{
            NSLog(@"线程3开始任务");
            [lock lockWhenCondition:2];
            for (int i = 0; i<3; i++) {
                sleep(1);
                c = c +1;
                NSLog(@"线程3执行任务c = %d",c);
            }
            [lock unlockWithCondition:3];
        });
    }
    else if (type == 3){
        //NSRecursiveLock
        NSRecursiveLock *lock = [[NSRecursiveLock alloc]init];
        dispatch_async(queue, ^{
            static void (^MyMethod)(int);
            MyMethod = ^(int val){
                [lock lock];
                if (val > 0) {
                    sleep(1);
                    NSLog(@"执行任务val=%d",val);
                    MyMethod(val-1);
                }
                [lock unlock];
            };
            MyMethod(5);
        });
    }
    else if (type == 4){
        //NSCondition
        __block int d = 0;
        NSCondition *lock = [[NSCondition alloc]init];
        dispatch_async(queue, ^{
            //上锁，并等待
            [lock lock];
            if (d == 0) {
                //等待
                NSLog(@"线程等待");
                [lock wait];
            }
            //执行任务2
            d = d+1;
            NSLog(@"执行条件任务2d=%d",d);
            //解锁
            [lock unlock];
        });
        dispatch_async(queue, ^{
            //上锁
            [lock lock];
            d = d + 1;
            //执行任务1
            NSLog(@"执行线程任务1d=%d",d);
            //发送信号，通知等待中的线程
            NSLog(@"发送信号");
            [lock signal];
            //解锁
            [lock unlock];
        });
    }
    else if (type == 5){
        //OSSpinLock
        __block OSSpinLock lock = OS_SPINLOCK_INIT;
        __block int e = 0;
        dispatch_async(queue, ^{
            OSSpinLockLock(&lock);
            for (int i = 0; i<3; i++) {
                sleep(1);
                e = e +1;
                NSLog(@"线程1执行任务e = %d",e);
            }
            OSSpinLockUnlock(&lock);
        });
        dispatch_async(queue, ^{
            OSSpinLockLock(&lock);
            for (int i = 0; i<3; i++) {
                sleep(1);
                e = e +1;
                NSLog(@"线程2执行任务e = %d",e);
            }
            OSSpinLockUnlock(&lock);
        });
    }
    else if (type == 6){
        //pthread_mutex 互斥锁
        static pthread_mutex_t lock;
        __block int f = 0;
        pthread_mutex_init(&lock,NULL);
        dispatch_async(queue, ^{
            pthread_mutex_lock(&lock);
            for (int i = 0; i<3; i++) {
                sleep(1);
                f = f +1;
                NSLog(@"线程1执行任务f = %d",f);
            }
            pthread_mutex_unlock(&lock);
        });
        dispatch_async(queue, ^{
            pthread_mutex_lock(&lock);
            for (int i = 0; i<3; i++) {
                sleep(1);
                f = f +1;
                NSLog(@"线程2执行任务f = %d",f);
            }
            pthread_mutex_unlock(&lock);
        });
    }
    else if (type == 7){
        static pthread_mutex_t lock;
        pthread_mutexattr_t attr;
        pthread_mutexattr_init(&attr); //初始化attr并且给它赋予默认
        pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE); //设置锁类型，这边是设置为递归锁
        pthread_mutex_init(&lock, &attr);
        pthread_mutexattr_destroy(&attr); //销毁一个属性对象，在重新进行初始化之前该结构不能重新使用
        
        dispatch_async(queue, ^{
            static void (^MyMethod)(int);
            MyMethod = ^(int val){
                pthread_mutex_lock(&lock);
                if (val > 0) {
                    sleep(1);
                    NSLog(@"执行任务val=%d",val);
                    MyMethod(val-1);
                }
                pthread_mutex_unlock(&lock);
            };
            MyMethod(5);
        });
    }
    else if (type == 8){
dispatch_semaphore_t signal = dispatch_semaphore_create(2);
dispatch_time_t overTime = dispatch_time(DISPATCH_TIME_NOW, 3.0f * NSEC_PER_SEC);
dispatch_async(queue, ^{
    dispatch_semaphore_wait(signal, overTime);
    sleep(1);
    NSLog(@"执行线程1任务");
    dispatch_semaphore_signal(signal);
});
dispatch_async(queue, ^{
    dispatch_semaphore_wait(signal, overTime);
    sleep(1);
    NSLog(@"执行线程2任务");
    dispatch_semaphore_signal(signal);
});
dispatch_async(queue, ^{
    dispatch_semaphore_wait(signal, overTime);
    sleep(1);
    NSLog(@"执行线程3任务");
    dispatch_semaphore_signal(signal);
});
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
