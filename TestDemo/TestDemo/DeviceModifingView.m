//
//  DeviceModifingView.m
//  Meteorological
//
//  Created by 徐守卫 on 2017/10/18.
//  Copyright © 2017年 徐守卫. All rights reserved.
//

#import "DeviceModifingView.h"
#import "CommonFunc.h"

@interface DeviceModifingView()<UITextFieldDelegate>
{
    UITextField *m_field;
    UITextField *m_lost;
}

@end


@implementation DeviceModifingView
@synthesize delegate;

#define TAG_TEXT_FIELD      2000
#define TAG_TEXT_LOST       2001

-(instancetype)initChangeNameView
{
    self = [super initWithFrame:CGRectMake(0, 0, SCREEN_W, SCREEN_H)];
    if (self) {
        [self createSettingView];
    }
    
    return self;
}


- (void)createSettingView
{
    self.backgroundColor = COLOR_TRANCLUCENT_BACKGROUND_LIGHT;
    
    NSInteger nW = CGRectGetWidth(self.frame) / 3 * 2;
    NSInteger nH = nW;
    NSInteger nX = (CGRectGetWidth(self.frame) - nW) / 2;
    NSInteger nY = (CGRectGetHeight(self.frame) - nH) / 2;
    CGRect tmpRect = CGRectMake(nX, nY, nW, nH);
    UIView *whiteBG = [[UIView alloc] initWithFrame:tmpRect];
    whiteBG.layer.cornerRadius = 16;
    whiteBG.clipsToBounds = YES;
    whiteBG.backgroundColor = [UIColor whiteColor];
    [self addSubview:whiteBG];
    
    NSInteger nGap = 20;
    nH = 40;
    tmpRect = CGRectMake(nGap, nGap, nW - nGap * 2, nH);
    m_field = [[UITextField alloc] initWithFrame:tmpRect];
    m_field.placeholder = @"名称";
    m_field.tag = TAG_TEXT_FIELD;
    m_field.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    m_field.layer.borderWidth = 1;
    m_field.delegate = self;
    [whiteBG addSubview:m_field];

//    nY = CGRectGetMaxY(m_field.frame) + nGap;
//    tmpRect = CGRectMake(nGap, nY, nW - nGap * 2, nH);
//    m_lost = [[UITextField alloc] initWithFrame:tmpRect];
//    m_lost.tag = TAG_TEXT_LOST;
//    m_lost.layer.borderColor = [[UIColor lightGrayColor] CGColor];
//    m_lost.layer.borderWidth = 1;
//    m_lost.placeholder = @"防丢信息";
//    m_lost.delegate = self;
//    [whiteBG addSubview:m_lost];
    
    nW = (nW - nGap * 3) / 2;
    nY = CGRectGetMaxY(m_field.frame) + nGap;
    tmpRect = CGRectMake(nGap, nY, nW, nH);
    UIButton *cancelBtn = [[UIButton alloc] initWithFrame:tmpRect];
    [cancelBtn addTarget:self action:@selector(cancelBtnPressed) forControlEvents:UIControlEventTouchUpInside];
    [cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
    cancelBtn.backgroundColor = [UIColor lightGrayColor];
    cancelBtn.layer.cornerRadius = 4;
    cancelBtn.clipsToBounds = YES;
    [whiteBG addSubview:cancelBtn];
    
    tmpRect = CGRectMake(CGRectGetMaxX(cancelBtn.frame) + nGap, nY, nW, nH);
    UIButton *okBtn = [[UIButton alloc] initWithFrame:tmpRect];
    [okBtn setTitle:@"修改" forState:UIControlStateNormal];
    okBtn.backgroundColor = [CommonFunc colorWithHexString:@"#111f44"];
    okBtn.layer.cornerRadius = 4;
    okBtn.clipsToBounds = YES;
    [okBtn addTarget:self action:@selector(okBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    [whiteBG addSubview:okBtn];
    
    nH = CGRectGetMaxY(okBtn.frame) + nGap;
    tmpRect = whiteBG.frame;
    tmpRect.size.height = nH;
    whiteBG.frame = tmpRect;
}

-(void)okBtnPressed:(UIButton *)sender
{
    UITextField *field = [self viewWithTag:TAG_TEXT_FIELD];
    UITextField *lost = [self viewWithTag:TAG_TEXT_LOST];
    if (delegate && [delegate respondsToSelector:@selector(changeName:lost:)]) {
        [delegate changeName:field.text lost:lost.text];
    }
    
    [self removeFromSuperview];
}

-(void)cancelBtnPressed
{
    [self removeFromSuperview];
}


-(void)setName:(NSString *)name lost:(NSString *)lostStr
{
    UITextField *field = [self viewWithTag:TAG_TEXT_FIELD];
    UITextField *lost = [self viewWithTag:TAG_TEXT_LOST];

    field.text = name;
    lost.text = lostStr;
}


#pragma mark - Edit delegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    DLog(@"%@", string);
    if ([string isEqualToString:@"\n"]) {
        [m_lost resignFirstResponder];
        [m_field resignFirstResponder];
    }
    
    NSMutableString *newtxt = [NSMutableString stringWithString:textField.text];
    [newtxt replaceCharactersInRange:range withString:string];
    NSInteger nLetterLen = [CommonFunc checkIsHaveNumAndLetter:newtxt];
    
    if ((newtxt.length - nLetterLen) > 5)
        return NO;
    
    if (newtxt.length > 10) {
        return NO;
    }
    
    return YES;
}

@end
