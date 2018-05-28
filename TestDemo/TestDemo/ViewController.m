//
//  ViewController.m
//  TestDemo
//
//  Created by 徐守卫 on 2018/4/4.
//  Copyright © 2018年 徐守卫. All rights reserved.
//

#import "ViewController.h"
#import "ConstDefine.h"
#import "BLEManager.h"
#import "CommonFunc.h"
#import "DevViewController.h"

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource, BLEManagerDelegate>
{
    UITableView *m_table;
    NSMutableArray *m_peripheralArr;
    NSMutableArray *m_checkArr;
    
    UIButton *m_searchBtn;
    NSDictionary* m_selDic;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    // Do any additional setup after loading the view, typically from a nib.
    [self createView];
    
    m_searchBtn = [[UIButton alloc] initWithFrame:CGRectMake(25, 5, 80, 36)];
    [m_searchBtn setTitle:@"重新搜索" forState:UIControlStateNormal];
    [m_searchBtn.titleLabel setFont:[UIFont boldSystemFontOfSize:15]];
    [m_searchBtn setTitleColor:[CommonFunc colorWithHexString:@"#0076FF"] forState:UIControlStateNormal];
    [m_searchBtn addTarget:self action:@selector(RightAction:) forControlEvents:UIControlEventTouchUpInside];
    [m_searchBtn setBackgroundColor:[UIColor whiteColor]];
    
    UIBarButtonItem *BarBtn1 = [[UIBarButtonItem alloc] initWithCustomView:m_searchBtn];
    self.navigationItem.rightBarButtonItem = BarBtn1;

    [[BLEManager ShareInstance] initManager];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [m_checkArr removeAllObjects];
    [m_peripheralArr removeAllObjects];
    
    [BLEManager ShareInstance].m_delegate = self;
    [[BLEManager ShareInstance] startScan];
}


-(void)RightAction:(UIButton *)btn
{
    [m_peripheralArr removeAllObjects];
    [m_checkArr removeAllObjects];
    [m_table reloadData];
    
    [[BLEManager ShareInstance] startScan];
}


-(void)createView
{
    CGFloat fX = 0;
    CGFloat fY = SCREEN_NAV_H;
    CGFloat fW = SCREEN_W;
    CGFloat fH = VIEW_HEIGHT;
    CGRect tmpRect = CGRectMake(fX, fY, fW, fH);
    m_table = [[UITableView alloc] initWithFrame:tmpRect];
    m_table.delegate = self;
    m_table.dataSource = self;
//    m_table.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:m_table];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)discoverDevice:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    
    if ((peripheral.name && [peripheral.name length] > 0) || ([[advertisementData objectForKey:@"kCBAdvDataLocalName"] length] > 0))
    {
        NSMutableDictionary *peripheralDic = [[NSMutableDictionary alloc] init];
        NSString *UUIDString = [NSString stringWithFormat:@"%@_connect", peripheral.identifier.UUIDString];
        [peripheralDic setObject:peripheral forKey:UUIDString];
        
        [peripheralDic setObject:[NSString stringWithFormat:@"%@", peripheral.identifier.UUIDString] forKey:@"uuidstr"];
        
        UUIDString = [NSString stringWithFormat:@"%@_adver", peripheral.identifier.UUIDString];
        [peripheralDic setObject:advertisementData forKey:UUIDString];
        if (!m_peripheralArr) {
            m_peripheralArr = [[NSMutableArray alloc] init];
        }
        
        if (!m_checkArr) {
            m_checkArr = [[NSMutableArray alloc] init];
        }
        
        if (YES == [m_checkArr containsObject:peripheral.identifier.UUIDString])
        {
            BOOL bRet = [self checkNewPeripheral:peripheral adver:advertisementData];
            if (bRet) {
                [m_table reloadData];
            }
            return;
        }
        
        [m_checkArr addObject:peripheral.identifier.UUIDString];
        
        //        DLog(@"searched peripheral: %@", peripheral);
        [m_peripheralArr addObject:peripheralDic];
        
        [m_table reloadData];
    }
    
}


-(BOOL)checkNewPeripheral:(CBPeripheral *)peripheral adver:(NSDictionary<NSString *, id> *)advertisementData
{
    NSInteger nCount = [m_peripheralArr count];
    //    NSString *identiStr = peripheral.identifier.UUIDString;
    NSString *adverName = [advertisementData objectForKey:@"kCBAdvDataLocalName"];
    for (NSInteger i = 0; i < nCount; i++) {
        NSDictionary *theDic = [m_peripheralArr objectAtIndex:i];
        NSString *connctStr = [NSString stringWithFormat:@"%@_connect", peripheral.identifier.UUIDString];
        CBPeripheral *thePeri = [theDic objectForKey:connctStr];
        if (NO == [thePeri.identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString]) {
            continue;
        }
        
        //        NSString *UUIDString = [NSString stringWithFormat:@"%@_connect", peripheral.identifier.UUIDString];
        NSString *UUIDString = [NSString stringWithFormat:@"%@_adver", peripheral.identifier.UUIDString];
        NSDictionary *adverDic = [theDic objectForKey:UUIDString];
        NSString *preAdverName = [adverDic objectForKey:@"kCBAdvDataLocalName"];
        if ([preAdverName isEqualToString:adverName] && [@"" isEqualToString:adverName] == NO) {
            return NO;
        }
        else
        {
            NSMutableDictionary *peripheralDic = [[NSMutableDictionary alloc] init];
            NSString *UUIDString = [NSString stringWithFormat:@"%@_connect", peripheral.identifier.UUIDString];
            [peripheralDic setObject:peripheral forKey:UUIDString];
            
            [peripheralDic setObject:[NSString stringWithFormat:@"%@", peripheral.identifier.UUIDString] forKey:@"uuidstr"];
            
            UUIDString = [NSString stringWithFormat:@"%@_adver", peripheral.identifier.UUIDString];
            [peripheralDic setObject:advertisementData forKey:UUIDString];
            [m_peripheralArr replaceObjectAtIndex:i withObject:peripheralDic];
            return YES;
        }
    }
    
    return NO;
}



- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [m_peripheralArr count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identiStr = @"searchPeripheral";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identiStr];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identiStr];
    }
    else
    {
    }
    
    NSDictionary *dataDic = [m_peripheralArr objectAtIndex:indexPath.row];
    //        DLog(@"%@", dataDic);
    NSString *idstr = [dataDic objectForKey:@"uuidstr"];
    NSString *adverKey = [NSString stringWithFormat:@"%@_adver", idstr];
    NSDictionary *adverDic = [dataDic objectForKey:adverKey];
    if (adverDic) {
        NSString *name = GET([adverDic objectForKey:@"kCBAdvDataLocalName"]);
        
        if (name && [name length] > 0) {
            cell.textLabel.text = [NSString stringWithFormat:@"%@", name];
        }
        else
        {
            NSString *connectKey = [NSString stringWithFormat:@"%@_connect", idstr];
            id connectDic = [dataDic objectForKey:connectKey];
            if ([connectDic isKindOfClass:[CBPeripheral class]]) {
                CBPeripheral *thePer = (CBPeripheral *)connectDic;
                cell.textLabel.text = GET(thePer.name);
            }
            else
            {
                cell.textLabel.text = @"";
            }
        }
    }
    else
    {
        NSString *connectKey = [NSString stringWithFormat:@"%@_connect", idstr];
        id connectDic = [dataDic objectForKey:connectKey];
        if ([connectDic isKindOfClass:[CBPeripheral class]]) {
            CBPeripheral *thePer = (CBPeripheral *)connectDic;
            cell.textLabel.text = GET(thePer.name);
        }
        else
        {
            cell.textLabel.text = @"";
        }
    }
    
    
    cell.selectedBackgroundView.backgroundColor = [CommonFunc colorWithHexString:@"#e2e3e4"];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self selectDevice:indexPath.row];
}


-(void)selectDevice:(NSInteger)nSelIndex
{
    [[BLEManager ShareInstance] stopScan];
    
    
    if (nSelIndex >= [m_peripheralArr count]) {
        return;
    }

    NSDictionary *dataDic = [m_peripheralArr objectAtIndex:nSelIndex];
    NSString *perKey = [NSString stringWithFormat:@"%@_connect",GET([dataDic objectForKey:@"uuidstr"])];
    CBPeripheral *thePeripheral = [dataDic objectForKey:perKey];
    NSString *dicKey = [NSString stringWithFormat:@"%@_adver",GET([dataDic objectForKey:@"uuidstr"])];
    NSDictionary *theAdDic = [dataDic objectForKey:dicKey];
    [[BLEManager ShareInstance] connectDevice:thePeripheral advertisementData:theAdDic];
    m_selDic = dataDic;
}


-(void)didConnectDevice:(CBPeripheral *)peripheral
{
    [[BLEManager ShareInstance] discoverServices];
    
    DevViewController *theCtrl = [[DevViewController alloc] initWith:m_selDic];
    [self.navigationController pushViewController:theCtrl animated:YES];
}

-(void)didConnectDeviceFailed:(CBPeripheral *)peripheral
{
    [CommonFunc showErrorMsg:@"连接蓝牙失败" parent:self];
}

//
//-(void)changeStatus:(statusLink)status
//{
//    switch (status) {
//        case statusConnected:
//            [
//            break;
//            
//        default:
//            break;
//    }
//}

@end
