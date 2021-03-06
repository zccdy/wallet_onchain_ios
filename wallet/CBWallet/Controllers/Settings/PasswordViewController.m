//
//  PasswordViewController.m
//  CBWallet
//
//  Created by Zin on 16/4/18.
//  Copyright © 2016年 Bitmain. All rights reserved.
//

#import "PasswordViewController.h"
#import "FormControlInputCell.h"

#import "Guard.h"
#import "CBWBackup.h"

#import "NSString+Password.h"

static NSString *const kPasswordViewControllerCurrentPasswordCellIdentifier = @"cell.current.password";
static NSString *const kPasswordViewControllerNewPasswordCellIdentifier = @"cell.new.password";
static NSString *const kPasswordViewControllerConfirmPasswordCellIdentifier = @"cell.confirm.password";
static NSString *const kPasswordViewControllerSaveButtonCellIdentifier = @"cell.save";

@interface PasswordViewController ()

@property (nonatomic, strong) NSString *currentPassword;
@property (nonatomic, strong) NSString *aNewPassword;
@property (nonatomic, strong) NSString *confirmPassword;

@property (nonatomic, weak) UITextField *currentPasswordTextField;
@property (nonatomic, weak) UITextField *aNewPasswordTextField;
@property (nonatomic, weak) UITextField *confirmPasswordTextField;
@property (nonatomic, weak) FormControlBlockButtonCell *saveButton;

@end

@implementation PasswordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = NSLocalizedStringFromTable(@"Navigation change_password", @"CBW", nil);
    
    [self.tableView registerClass:[FormControlInputCell class] forCellReuseIdentifier:kPasswordViewControllerCurrentPasswordCellIdentifier];
    [self.tableView registerClass:[FormControlInputCell class] forCellReuseIdentifier:kPasswordViewControllerNewPasswordCellIdentifier];
    [self.tableView registerClass:[FormControlInputCell class] forCellReuseIdentifier:kPasswordViewControllerConfirmPasswordCellIdentifier];
    [self.tableView registerClass:[FormControlBlockButtonCell class] forCellReuseIdentifier:kPasswordViewControllerSaveButtonCellIdentifier];
}

#pragma mark - Private Method
#pragma mark Handlers
- (void)p_handleEditingChanged:(id)sender {
    BOOL valid = YES;
    
    self.currentPassword = self.currentPasswordTextField.text;
    self.aNewPassword = self.aNewPasswordTextField.text;
    self.confirmPassword = self.confirmPasswordTextField.text;
    
    valid = self.currentPassword.length > 0 && valid;
    valid = self.aNewPassword.length > 0 && valid;
    valid = self.confirmPassword.length > 0 && valid;
    
    self.saveButton.enabled = valid;
}

- (void)p_handleSave:(id)sender {
    NSMutableString *message = [NSMutableString string];
    if (self.currentPassword.length == 0) {
        [message appendString:[NSString stringWithFormat:@"%@\n", NSLocalizedStringFromTable(@"Alert Message need_current_password", @"CBW", nil)]];
    }
    if (self.aNewPassword.length == 0) {
        [message appendString:[NSString stringWithFormat:@"%@\n", NSLocalizedStringFromTable(@"Alert Message need_new_password", @"CBW", nil)]];
    } else {
        // valid password
        double score = [self.aNewPassword passwordStrength];
        DLog(@"score: %f", score);
        if (score < 60) {
            [message appendString:NSLocalizedStringFromTable(@"Alert Message need_strong_password", @"CBW", @"Please input a strong password.")];
        }
        // confirm password
        if (![self.aNewPassword isEqualToString:self.confirmPassword]) {
            [message appendString:[NSString stringWithFormat:@"%@", NSLocalizedStringFromTable(@"Alert Message new_password_not_match", @"CBW", nil)]];
        }
    }
    
    if (message.length > 0) {
        [self alertMessage:message withTitle:NSLocalizedStringFromTable(@"Error", @"CBW", nil)];
        
        return;
    }
    
    // try to save
    if ([[Guard globalGuard] changeCode:self.currentPassword toNewCode:self.aNewPassword]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:NSLocalizedStringFromTable(@"Success", @"CBW", nil) preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okay = [UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"Okay", @"CBW", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            if (self.navigationController) {
                [self.navigationController popViewControllerAnimated:YES];
            } else {
                [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
            }
        }];
        [alert addAction:okay];
        [self presentViewController:alert animated:YES completion:nil];
        // 重新备份到 iCloud
        [CBWBackup saveToCloudKitWithCompletion:^(NSError *error) {
            // TODO: handle error
            if (error) {
                DLog(@"changed password, update iCloud backup failed. \n%@", error);
            }
        }];
    } else {
        [self alertErrorMessage:NSLocalizedStringFromTable(@"Alert Message invalid_current_password", @"CBW", nil)];
    }
    
}

#pragma mark - <UITableViewDataSource>
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;// current, new, save
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 1) {
        return 2;
    }
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0: {
            FormControlInputCell *cell = [tableView dequeueReusableCellWithIdentifier:kPasswordViewControllerCurrentPasswordCellIdentifier];
            cell.textField.placeholder = NSLocalizedStringFromTable(@"Placeholder current_password", @"CBW", nil);
            cell.textField.secureTextEntry = YES;
            cell.textField.text = self.currentPassword;
            [cell.textField addTarget:self action:@selector(p_handleEditingChanged:) forControlEvents:UIControlEventEditingChanged];
            self.currentPasswordTextField = cell.textField;
            return cell;
            break;
        }
        case 1: {
            switch (indexPath.row) {
                case 0: {
                    FormControlInputCell *cell = [tableView dequeueReusableCellWithIdentifier:kPasswordViewControllerNewPasswordCellIdentifier];
                    cell.textField.placeholder = NSLocalizedStringFromTable(@"Placeholder new_password", @"CBW", nil);
                    cell.textField.secureTextEntry = YES;
                    cell.textField.text = self.aNewPassword;
                    [cell.textField addTarget:self action:@selector(p_handleEditingChanged:) forControlEvents:UIControlEventEditingChanged];
                    self.aNewPasswordTextField = cell.textField;
                    return cell;
                    break;
                }
                case 1: {
                    FormControlInputCell *cell = [tableView dequeueReusableCellWithIdentifier:kPasswordViewControllerConfirmPasswordCellIdentifier];
                    cell.textField.placeholder = NSLocalizedStringFromTable(@"Placeholder confirm_password", @"CBW", nil);
                    cell.textField.secureTextEntry = YES;
                    cell.textField.text = self.confirmPassword;
                    [cell.textField addTarget:self action:@selector(p_handleEditingChanged:) forControlEvents:UIControlEventEditingChanged];
                    self.confirmPasswordTextField = cell.textField;
                    return cell;
                    break;
                }
            }
            break;
        }
        case 2: {
            FormControlBlockButtonCell *cell = [tableView dequeueReusableCellWithIdentifier:kPasswordViewControllerSaveButtonCellIdentifier];
            cell.textLabel.text = NSLocalizedStringFromTable(@"Button save", @"CBW", nil);
            cell.enabled = NO;
            self.saveButton = cell;
            return cell;
            break;
        }
    }
    return [tableView dequeueReusableCellWithIdentifier:BaseTableViewCellDefaultIdentifier];
}

#pragma mark <UITableViewDelegate>
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == [tableView numberOfSections] - 1) {
        return NSLocalizedStringFromTable(@"Tip about_master_password", @"CBW", nil);
    }
    return nil;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 2) {
        [self p_handleSave:nil];
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
