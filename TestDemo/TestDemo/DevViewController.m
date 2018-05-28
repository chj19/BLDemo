//
//  DevViewController.m
//  TestDemo
//
//  Created by 徐守卫 on 2018/4/8.
//  Copyright © 2018年 徐守卫. All rights reserved.
//

#import "DevViewController.h"
#import "CommonFunc.h"
#import "DeviceModifingView.h"

@interface DevViewController ()<DeviceModifingViewDelegate, BLEManagerDelegate>
{
    CBPeripheral *m_peri;
    
    UIButton *m_bindBtn;
    UIButton *m_unbindBtn;
    
    UIButton *m_callBtn;
    UIButton *m_disturbBtn;
    NSInteger m_nRing;
    UIButton *m_ringBtn;
    
    UITextField *m_nameField;
    UIButton *m_editBtn;
    
    UILabel *m_volLabel;
    UILabel *m_pressLabel;
    UILabel *m_tempLabel;
    UILabel *m_humiLabel;
    
    UILabel *m_nameLabel;
    NSString *m_nameStr;
    
    UIButton *m_dataBtn;
    BOOL m_bBinded;
}

@end

@implementation DevViewController
-(void)dealloc
{
    if (m_peri) {
//        [[BLEManager ShareInstance] disconnectPeripheral:m_peri];
        [[BLEManager ShareInstance] disconnectDevice];
        m_peri = nil;
    }
}

-(instancetype)initWith:(NSDictionary *)peripheralDic
{
    self = [super init];
    if (self) {
        if(peripheralDic)
        {
            NSString *idstr = [peripheralDic objectForKey:@"uuidstr"];
            NSString *adverKey = [NSString stringWithFormat:@"%@_adver", idstr];
            NSDictionary *adverDic = [peripheralDic objectForKey:adverKey];
            if (adverDic) {
                NSString *connectKey = [NSString stringWithFormat:@"%@_connect", idstr];
                id connectDic = [peripheralDic objectForKey:connectKey];
                if ([connectDic isKindOfClass:[CBPeripheral class]]) {
                    CBPeripheral *thePer = (CBPeripheral *)connectDic;
                    m_nameStr = GET(thePer.name);
                    m_peri = thePer;
                }
                else
                {
                    m_nameStr = @"";
                }
                
                NSString *name = GET([adverDic objectForKey:@"kCBAdvDataLocalName"]);
                
                if (name && [name length] > 0) {
                    m_nameStr = [NSString stringWithFormat:@"%@", name];
                }
            }
        }
    }
    
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cancelCalling) name:NOTI_DEV_CANCEL_CALL object:nil];

    [self addNavLabel];
    
    [self createView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [BLEManager ShareInstance].m_delegate = self;
}


-(void)addNavLabel
{
    m_nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(SCREEN_W / 3, 0, SCREEN_W / 3, SCREEN_NAV_H - STATUS_BAR_HEIGHT)];
    m_nameLabel.backgroundColor = [UIColor clearColor];
    m_nameLabel.textColor = [UIColor blackColor];
    m_nameLabel.textAlignment = NSTextAlignmentCenter;
    m_nameLabel.text = m_nameStr;
    m_nameLabel.tag = NAV_TITLE_LABEL;
    [self.navigationController.navigationBar addSubview:m_nameLabel];
}


-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [m_nameLabel removeFromSuperview];
    m_nameLabel = nil;
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(void)createView
{
    CGFloat fGapY = 20;
    CGFloat fGapX = 20;
    CGFloat fX = fGapX;
    CGFloat fY = SCREEN_NAV_H + fGapY;
    CGFloat fW = (SCREEN_W - fGapX * 3) / 2;
    CGFloat fH = 40;
    CGRect tmpRect = CGRectMake(fX, fY, fW, fH);
    m_bindBtn = [[UIButton alloc] initWithFrame:tmpRect];
    [m_bindBtn setTitle:@"绑定" forState:UIControlStateNormal];
    [m_bindBtn setBackgroundImage:[CommonFunc imageFromColor:[UIColor blueColor] frame:m_bindBtn.bounds] forState:UIControlStateHighlighted];
//    [m_bindBtn setBackgroundImage:[CommonFunc imageFromColor:[UIColor grayColor] frame:m_bindBtn.bounds] forState:UIControlStateNormal];
    [m_bindBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    m_bindBtn.layer.borderColor = [UIColor blackColor].CGColor;
    m_bindBtn.layer.borderWidth = .5;
    [m_bindBtn addTarget:self action:@selector(bindBtn) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:m_bindBtn];
    
    CGFloat fX2 = fGapX * 2 + fW;
    tmpRect = CGRectMake(fX2, fY, fW, fH);
    m_unbindBtn = [[UIButton alloc] initWithFrame:tmpRect];
    [m_unbindBtn setTitle:@"解绑" forState:UIControlStateNormal];
    [m_unbindBtn addTarget:self action:@selector(unbindBtn) forControlEvents:UIControlEventTouchUpInside];
    [m_unbindBtn setBackgroundImage:[CommonFunc imageFromColor:[UIColor blueColor] frame:m_unbindBtn.bounds] forState:UIControlStateHighlighted];
//    [m_unbindBtn setBackgroundImage:[CommonFunc imageFromColor:[UIColor grayColor] frame:m_unbindBtn.bounds] forState:UIControlStateNormal];
    m_unbindBtn.layer.borderColor = [UIColor blackColor].CGColor;
    m_unbindBtn.layer.borderWidth = .5;
    [m_unbindBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.view addSubview:m_unbindBtn];
    
    fY = CGRectGetMaxY(m_unbindBtn.frame) + fGapY;
    tmpRect = CGRectMake(fX, fY, fW, fH);
    m_callBtn = [[UIButton alloc] initWithFrame:tmpRect];
    [m_callBtn setBackgroundImage:[CommonFunc imageFromColor:[UIColor blueColor] frame:m_unbindBtn.bounds] forState:UIControlStateHighlighted];
    [m_callBtn setTitle:@"呼叫" forState:UIControlStateNormal];
    [m_callBtn setTitle:@"取消呼叫" forState:UIControlStateSelected];
    m_callBtn.layer.borderColor = [UIColor blackColor].CGColor;
    m_callBtn.layer.borderWidth = .5;
    [m_callBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [m_callBtn addTarget:self action:@selector(callBtn) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:m_callBtn];
    
    tmpRect = CGRectMake(fX2, fY, fW, fH);
    m_ringBtn = [[UIButton alloc] initWithFrame:tmpRect];
    [m_ringBtn setTitle:@"铃声" forState:UIControlStateNormal];
    [m_ringBtn setBackgroundImage:[CommonFunc imageFromColor:[UIColor blueColor] frame:m_unbindBtn.bounds] forState:UIControlStateHighlighted];
    m_ringBtn.layer.borderColor = [UIColor blackColor].CGColor;
    m_ringBtn.layer.borderWidth = .5;
    [m_ringBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [m_ringBtn addTarget:self action:@selector(ringBtn) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:m_ringBtn];
    
    fY = CGRectGetMaxY(m_ringBtn.frame) + fGapY;
    tmpRect = CGRectMake(fX, fY, fW, fH);
    m_disturbBtn = [[UIButton alloc] initWithFrame:tmpRect];
    [m_disturbBtn setTitle:@"勿扰" forState:UIControlStateNormal];
    [m_disturbBtn setBackgroundImage:[CommonFunc imageFromColor:[UIColor blueColor] frame:m_unbindBtn.bounds] forState:UIControlStateHighlighted];
    m_disturbBtn.layer.borderColor = [UIColor blackColor].CGColor;
    m_disturbBtn.layer.borderWidth = .5;
    [m_disturbBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [m_disturbBtn addTarget:self action:@selector(disturbBtn) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:m_disturbBtn];
    
//    fY = CGRectGetMaxY(m_disturbBtn.frame) + fGapY;
//    tmpRect = CGRectMake(fX, fY, fW, fH);
//    m_nameField = [[UITextField alloc] initWithFrame:tmpRect];
//    m_nameField.placeholder = @"修改名称";
//    m_nameField.layer.borderColor = [UIColor blackColor].CGColor;
//    m_nameField.layer.borderWidth = .5;
//    [self.view addSubview:m_nameField];
    
    tmpRect = CGRectMake(fX2, fY, fW, fH);
    m_editBtn = [[UIButton alloc] initWithFrame:tmpRect];
    m_editBtn.layer.borderWidth = .5;
    m_editBtn.layer.borderColor = [UIColor blackColor].CGColor;
    [m_editBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [m_editBtn setTitle:@"修改名称" forState:UIControlStateNormal];
    [m_editBtn addTarget:self action:@selector(editButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:m_editBtn];
    
    fY = CGRectGetMaxY(m_editBtn.frame) + fGapY;
    tmpRect = CGRectMake(fX, fY, fW, fH);
    m_tempLabel = [[UILabel alloc] initWithFrame:tmpRect];
    m_tempLabel.text = @"温度：";
    m_tempLabel.textColor = [UIColor blackColor];
    m_tempLabel.textAlignment = NSTextAlignmentLeft;
    [self.view addSubview:m_tempLabel];
    
    tmpRect = CGRectMake(fX2, fY, fW, fH);
    m_humiLabel = [[UILabel alloc] initWithFrame:tmpRect];
    m_humiLabel.textAlignment = NSTextAlignmentLeft;
    m_humiLabel.textColor = [UIColor blackColor];
    m_humiLabel.text = @"湿度：";
    [self.view addSubview:m_humiLabel];
    
    fY = CGRectGetMaxY(m_humiLabel.frame);
    tmpRect = CGRectMake(fX, fY, fW, fH);
    m_pressLabel = [[UILabel alloc] initWithFrame:tmpRect];
    m_pressLabel.textAlignment = NSTextAlignmentLeft;
    m_pressLabel.textColor = [UIColor blackColor];
    m_pressLabel.text = @"气压：";
    [self.view addSubview:m_pressLabel];
    
    tmpRect = CGRectMake(fX2, fY, fW, fH);
    m_volLabel = [[UILabel alloc] initWithFrame:tmpRect];
    m_volLabel.textAlignment = NSTextAlignmentLeft;
    m_volLabel.textColor = [UIColor blackColor];
    m_volLabel.text = @"电量：";
    [self.view addSubview:m_volLabel];
    
    fY = CGRectGetMaxY(m_volLabel.frame) + fGapY;
    fW = SCREEN_W - fGapX * 2;
    tmpRect = CGRectMake(fX, fY, fW, fH);
    m_dataBtn = [[UIButton alloc] initWithFrame:tmpRect];
    [m_dataBtn setTitle:@"获取数据" forState:UIControlStateNormal];
    [m_dataBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [m_dataBtn addTarget:self action:@selector(dataBtn) forControlEvents:UIControlEventTouchUpInside];
    m_dataBtn.layer.borderColor = [UIColor blackColor].CGColor;
    m_dataBtn.layer.borderWidth = .5;
    [self.view addSubview:m_dataBtn];
}

-(void)dataBtn
{
    if (!m_bBinded) {
        [CommonFunc showErrorMsg:@"请先绑定" parent:self];
        return;
    }
    [[BLEManager ShareInstance] sendMessage:@"01" peripheral:m_peri];
}

-(void)editButton
{
    if (!m_bBinded) {
        [CommonFunc showErrorMsg:@"请先绑定" parent:self];
        return;
    }
    DeviceModifingView *tmpView = [[DeviceModifingView alloc] initChangeNameView];
    tmpView.delegate = self;
//    [tmpView setName:m_nameBtn.titleLabel.text lost:m_lostStatusLab.text];
    [self.view addSubview:tmpView];
}


-(void)disturbBtn
{
    if (!m_bBinded) {
        [CommonFunc showErrorMsg:@"请先绑定" parent:self];
        return;
    }
    m_disturbBtn.selected = !m_disturbBtn.selected;
    if (m_disturbBtn.selected) {
        [[BLEManager ShareInstance] sendDataMessage:DEF_BLE_OPEN_DISTURB_REQ];
        [m_disturbBtn setTitle:@"勿扰已关" forState:UIControlStateNormal];
    }
    else
    {
        [[BLEManager ShareInstance] sendDataMessage:DEF_BLE_CLOSE_DISTUREB_REQ];
        [m_disturbBtn setTitle:@"勿扰已开" forState:UIControlStateNormal];
    }
}


-(void)ringBtn
{
    if (!m_bBinded) {
        [CommonFunc showErrorMsg:@"请先绑定" parent:self];
        return;
    }
    m_nRing += 1;
    if (m_nRing > 3) {
        m_nRing = 1;
    }
    switch (m_nRing) {
        case 1:
            [[BLEManager ShareInstance] sendDataMessage:DEF_BLE_RING1_REQ];
            [m_ringBtn setTitle:@"铃声1" forState:UIControlStateNormal];
            break;
        case 2:
            [[BLEManager ShareInstance] sendDataMessage:DEF_BLE_RING2_REQ];
            [m_ringBtn setTitle:@"铃声2" forState:UIControlStateNormal];
            break;
        case 3:
            [[BLEManager ShareInstance] sendDataMessage:DEF_BLE_RING3_REQ];
            [m_ringBtn setTitle:@"铃声3" forState:UIControlStateNormal];
            break;
        default:
            break;
    }
}


-(void)bindBtn
{
    if (m_peri) {
        [[BLEManager ShareInstance] sendMessage:@"FF" peripheral:m_peri];
        [[BLEManager ShareInstance] bindDevice:m_peri];
    }
}

-(void)unbindBtn
{
    if (!m_bBinded) {
        [CommonFunc showErrorMsg:@"请先绑定" parent:self];
        return;
    }
    if(m_peri)
    {
        [[BLEManager ShareInstance] unbindDevice:m_peri];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

-(void)callBtn
{
    if (!m_bBinded) {
        [CommonFunc showErrorMsg:@"请先绑定" parent:self];
        return;
    }
    if (m_peri) {
        m_callBtn.selected = !m_callBtn.selected;
        if (m_callBtn.selected) {
            [[BLEManager ShareInstance] sendMessage:DEF_BLE_CALL_REQ peripheral:m_peri];
        }
        else
        {
            [[BLEManager ShareInstance] sendMessage:DEF_BLE_CALL_RES peripheral:m_peri];
        }

    }
}

-(void)changeStatus:(statusLink)status
{
    switch (status) {
        case statusBinded:
        {
            m_bBinded = YES;
            [CommonFunc showErrorMsg:@"绑定成功" parent:self];
        }
            break;
        case statusDisconnected:
        {
            m_bBinded = NO;
            [CommonFunc showErrorMsg:@"连接断开" parent:self];
        }
            break;
        default:
            break;
    }
}


-(void)changeName:(NSString *)deviceName lost:(NSString *)lostName
{
    if (deviceName && [deviceName length]) {
        [CommonFunc setNavTitle:deviceName nav:self.navigationController];
        
        [[BLEManager ShareInstance] modifyDevName:deviceName];
    }
}

-(void)updateData:(MEBLEModel *)data
{
    m_tempLabel.text = [NSString stringWithFormat:@"温度: %@", data.temperature];
    m_humiLabel.text = [NSString stringWithFormat:@"湿度: %@", data.humidity];
    m_pressLabel.text = [NSString stringWithFormat:@"气压: %@", data.pressure];
    m_volLabel.text = [NSString stringWithFormat:@"电量: %@", data.electricity];
}

-(void)cancelCalling
{
    m_callBtn.selected = NO;
}


@end
