//
//  SprinklerStaticListViewController_iPhone.m
//  Sprinklers
//
//  Created by Daniel Cristolovean on 1/30/13.
//  Copyright (c) 2013 Tremend. All rights reserved.
//

#import "SprinklerStaticListViewController_iPhone.h"
#import "StorageManager.h"
#import "AddSprinklerViewController_iPhone.h"
#import "WebPageViewController.h"

@implementation SprinklerStaticListViewController_iPhone

#pragma mark - Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Remote Sprinklers";
        editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(edit)];
        UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNewSprinkler)];
        self.navigationItem.leftBarButtonItem = addButton;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.hidesBackButton = YES;
    _tableView.allowsSelectionDuringEditing = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive) name:@"ApplicationDidBecomeActive" object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _tableView.editing = NO;
    self.navigationItem.rightBarButtonItem = nil;
    editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(edit)];
    
    savedSprinklers = [NSMutableArray arrayWithArray:[[StorageManager current] getSprinklers]];
    if (!savedSprinklers || savedSprinklers.count == 0) {
         self.navigationItem.rightBarButtonItem = nil;
    } else {
         self.navigationItem.rightBarButtonItem = editButton;
    }
    [_tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (_shouldDisplayAdd) {
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
        self.navigationItem.backBarButtonItem = backButton;
        AddSprinklerViewController_iPhone *addSprinkler = [[AddSprinklerViewController_iPhone alloc] init];
        [self.navigationController pushViewController:addSprinkler animated:NO];
        _shouldDisplayAdd = NO;
    }
}

#pragma mark - Actions

- (void)appDidBecomeActive {
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (void)addNewSprinkler {
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem = backButton;
    AddSprinklerViewController_iPhone *addSprinkler = [[AddSprinklerViewController_iPhone alloc] init];
    [self.navigationController pushViewController:addSprinkler animated:YES];
}

- (void)edit {
    [_tableView setEditing:!_tableView.isEditing];
    
    if (_tableView.isEditing) {
        editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(edit)];
        self.navigationItem.rightBarButtonItem = editButton;
    } else {
        editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(edit)];
        self.navigationItem.rightBarButtonItem = editButton;
    }
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0)
        return 1;
    return savedSprinklers.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0)
        return 44.0f;
    return 50.0f;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return (indexPath.section == 1 && indexPath.row < savedSprinklers.count);
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Sprinkler *spr = savedSprinklers[indexPath.row];
        [[StorageManager current] deleteSprinkler:spr.name];
        [savedSprinklers removeObject:spr];
        [_tableView reloadData];
        if (savedSprinklers.count == 0) {
            self.navigationItem.rightBarButtonItem = nil;
            _tableView.editing = NO;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    if (indexPath.section == 1) {
        Sprinkler *spr = savedSprinklers[indexPath.row];
        cell.textLabel.text = spr.name;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", spr.address];
    }
    else  {
        cell.textLabel.text = @"Local Sprinklers";
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem = backButton;
    
    if (_tableView.isEditing && indexPath.section == 1) {
        AddSprinklerViewController_iPhone *addSprinkler = [[AddSprinklerViewController_iPhone alloc] init];
        addSprinkler.sprinkler = savedSprinklers[indexPath.row];
        [self.navigationController pushViewController:addSprinkler animated:YES];
        return;
    }
    
    if (indexPath.section == 1) {
        Sprinkler *sp = savedSprinklers[indexPath.row];        
        WebPageViewController *web = [[WebPageViewController alloc] initWithURL:sp.address];
        web.title = sp.name;
        [self.navigationController pushViewController:web animated:YES];
    } else {
        [UIView animateWithDuration:0.5
                         animations:^{
                             [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
                             [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:self.navigationController.view cache:NO];
                         }];
        [self.navigationController popViewControllerAnimated:NO];
    }
}

#pragma mark - Dealloc

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setTableView:nil];
    [super viewDidUnload];
}

@end
