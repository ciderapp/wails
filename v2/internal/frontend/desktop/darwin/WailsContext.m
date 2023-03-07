//go:build darwin
//
//  WailsContext.m
//  test
//
//  Created by Lea Anthony on 10/10/21.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "WailsContext.h"
#import "WailsAlert.h"
#import "WailsMenu.h"
#import "WindowDelegate.h"
#import "message.h"
#import "Role.h"
#import "NSURLProtocol+WebKitSupport.h"
#import "CiderProtocolInterceptor.h"

@implementation FujisanWKWebView

- (WKNavigation*)loadRequest:(NSURLRequest *)request {
    NSLog(@"Modifying request loadRequest");
    NSLog(@"%@", request.URL);
    if([[request.URL absoluteString] containsString:@"https://beta.music.apple.com"]) {
        NSMutableURLRequest *modified = [request mutableCopy];
        NSURL *anotherURL = [NSURL URLWithString:@"wails://"];
        [modified setURL:anotherURL];
        [modified setValue:@"Cider-2;?client=dotnet" forHTTPHeaderField:@"User-Agent"];
        [modified setValue:@"1" forHTTPHeaderField:@"DNT"];
        [modified setValue:@"amp-api.music.apple.com" forHTTPHeaderField:@"Authority" ];
        [modified setValue:@"https://music.apple.com" forHTTPHeaderField:@"Origin" ];
        [modified setValue:@"https://music.apple.com" forHTTPHeaderField:@"Referer" ];
        [modified setValue:@"empty" forHTTPHeaderField:@"sec-fetch-dest" ];
        [modified setValue:@"cors" forHTTPHeaderField:@"sec-fetch-mode"];
        [modified setValue:@"same-site" forHTTPHeaderField:@"sec-fetch-site"];
        return [super loadRequest:[modified copy]];
    }
    return [super loadRequest:request];
}

@end

typedef void (^schemeTaskCaller)(id<WKURLSchemeTask>);

@implementation WailsWindow

- (BOOL)canBecomeKeyWindow
{
    return YES;
}

- (void) applyWindowConstraints {
    [self setMinSize:self.userMinSize];
    [self setMaxSize:self.userMaxSize];
}

- (void) disableWindowConstraints {
    [self setMinSize:NSMakeSize(0, 0)];
    [self setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
}

@end

@implementation WailsContext

- (void) SetSize:(int)width :(int)height {
    
    if (self.shuttingDown) return;
    
    NSRect frame = [self.mainWindow frame];
    frame.origin.y += frame.size.height - height;
    frame.size.width = width;
    frame.size.height = height;
    [self.mainWindow setFrame:frame display:TRUE animate:FALSE];
}

- (void) SetPosition:(int)x :(int)y {
    
    if (self.shuttingDown) return;
    
    NSScreen* screen = [self getCurrentScreen];
    NSRect windowFrame = [self.mainWindow frame];
    NSRect screenFrame = [screen frame];
    windowFrame.origin.x = screenFrame.origin.x + (float)x;
    windowFrame.origin.y = (screenFrame.origin.y + screenFrame.size.height) - windowFrame.size.height - (float)y;
    
    [self.mainWindow setFrame:windowFrame display:TRUE animate:FALSE];
}

- (void) SetMinSize:(int)minWidth :(int)minHeight {
    
    if (self.shuttingDown) return;
    
    NSSize size = { minWidth, minHeight };
    self.mainWindow.userMinSize = size;
    [self.mainWindow setMinSize:size];
    [self adjustWindowSize];
}


- (void) SetMaxSize:(int)maxWidth :(int)maxHeight {
    
    if (self.shuttingDown) return;
    
    NSSize size = { FLT_MAX, FLT_MAX };
    
    size.width = maxWidth > 0 ? maxWidth : FLT_MAX;
    size.height = maxHeight > 0 ? maxHeight : FLT_MAX;
    
    self.mainWindow.userMaxSize = size;
    [self.mainWindow setMaxSize:size];
    [self adjustWindowSize];
}


- (void) adjustWindowSize {
    
    if (self.shuttingDown) return;
    
    NSRect currentFrame = [self.mainWindow frame];
    
    if ( currentFrame.size.width > self.mainWindow.userMaxSize.width ) currentFrame.size.width = self.mainWindow.userMaxSize.width;
    if ( currentFrame.size.width < self.mainWindow.userMinSize.width ) currentFrame.size.width = self.mainWindow.userMinSize.width;
    if ( currentFrame.size.height > self.mainWindow.userMaxSize.height ) currentFrame.size.height = self.mainWindow.userMaxSize.height;
    if ( currentFrame.size.height < self.mainWindow.userMinSize.height ) currentFrame.size.height = self.mainWindow.userMinSize.height;

    [self.mainWindow setFrame:currentFrame display:YES animate:FALSE];
    
}

- (void) dealloc {
    [self.appdelegate release];
    [self.mainWindow release];
    [self.mouseEvent release];
    [self.userContentController release];
    [self.applicationMenu release];
    [super dealloc];
}

- (NSScreen*) getCurrentScreen {
    NSScreen* screen = [self.mainWindow screen];
    if( screen == NULL ) {
        screen = [NSScreen mainScreen];
    }
    return screen;
}

- (void) SetTitle:(NSString*)title {
    [self.mainWindow setTitle:title];
}

- (void) Center {
     [self.mainWindow center];
}

- (BOOL) isFullscreen {
    NSWindowStyleMask masks = [self.mainWindow styleMask];
    if ( masks & NSWindowStyleMaskFullScreen ) {
        return YES;
    }
    return NO;
}

- (void) CreateWindow:(int)width :(int)height :(bool)frameless :(bool)resizable :(bool)fullscreen :(bool)fullSizeContent :(bool)hideTitleBar :(bool)titlebarAppearsTransparent :(bool)hideTitle :(bool)useToolbar :(bool)hideToolbarSeparator :(bool)webviewIsTransparent :(bool)hideWindowOnClose :(NSString*)appearance :(bool)windowIsTranslucent :(int)minWidth :(int)minHeight :(int)maxWidth :(int)maxHeight :(bool)fraudulentWebsiteWarningEnabled {
    NSWindowStyleMask styleMask = 0;
    
    if( !frameless ) {
        if (!hideTitleBar) {
            styleMask |= NSWindowStyleMaskTitled;
        }
        styleMask |= NSWindowStyleMaskClosable;
    }
    
    styleMask |= NSWindowStyleMaskMiniaturizable;

    if( fullSizeContent || frameless || titlebarAppearsTransparent ) {
        styleMask |= NSWindowStyleMaskFullSizeContentView;
    }

    if (resizable) {
        styleMask |= NSWindowStyleMaskResizable;
    }
    
    self.mainWindow = [[WailsWindow alloc] initWithContentRect:NSMakeRect(0, 0, width, height)
                                                      styleMask:styleMask backing:NSBackingStoreBuffered defer:NO];
        
    if (!frameless && useToolbar) {
        id toolbar = [[NSToolbar alloc] initWithIdentifier:@"wails.toolbar"];
        [toolbar autorelease];
        [toolbar setShowsBaselineSeparator:!hideToolbarSeparator];
        [self.mainWindow setToolbar:toolbar];
    
    }
    
    [self.mainWindow setTitleVisibility:hideTitle];
    [self.mainWindow setTitlebarAppearsTransparent:titlebarAppearsTransparent];
    
//    [self.mainWindow canBecomeKeyWindow];
    
    id contentView = [self.mainWindow contentView];
    if (windowIsTranslucent) {
        NSVisualEffectView *effectView = [NSVisualEffectView alloc];
        NSRect bounds = [contentView bounds];
        [effectView initWithFrame:bounds];
        [effectView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [effectView setBlendingMode:NSVisualEffectBlendingModeBehindWindow];
        [effectView setState:NSVisualEffectStateActive];
        [contentView addSubview:effectView positioned:NSWindowBelow relativeTo:nil];
    }
    
    if (appearance != nil) {
        NSAppearance *nsAppearance = [NSAppearance appearanceNamed:appearance];
        [self.mainWindow setAppearance:nsAppearance];
    }
    

    NSSize minSize = { minWidth, minHeight };
    NSSize maxSize = { maxWidth, maxHeight };
    if (maxSize.width == 0) {
        maxSize.width = FLT_MAX;
    }
    if (maxSize.height == 0) {
        maxSize.height = FLT_MAX;
    }
    self.mainWindow.userMaxSize = maxSize;
    self.mainWindow.userMinSize = minSize;
    
    if( !fullscreen ) {
        [self.mainWindow applyWindowConstraints];
    }
    
    WindowDelegate *windowDelegate = [WindowDelegate new];
    windowDelegate.hideOnClose = hideWindowOnClose;
    windowDelegate.ctx = self;
    [self.mainWindow setDelegate:windowDelegate];

    // Webview stuff here!
    WKWebViewConfiguration *config = [WKWebViewConfiguration new];
    config.suppressesIncrementalRendering = true;
    config.applicationNameForUserAgent = @"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36";
    [config setURLSchemeHandler:self forURLScheme:@"wails"];
    config.preferences.javaScriptCanOpenWindowsAutomatically = YES;


    [config.preferences setValue:[NSNumber numberWithBool:true] forKey:@"developerExtrasEnabled"];
    [config.preferences setValue:@NO forKey:@"webSecurityEnabled"];
    [config.preferences setValue:@YES forKey:@"javaScriptCanOpenWindowsAutomatically"];
    [config.preferences setValue:@YES forKey:@"legacyEncryptedMediaAPIEnabled"];
    

    // if (@available(macOS 10.15, *)) {
    //     config.preferences.fraudulentWebsiteWarningEnabled = fraudulentWebsiteWarningEnabled;
    // }

    WKUserContentController* userContentController = [WKUserContentController new];

    [userContentController addScriptMessageHandler:self name:@"external"];
    config.userContentController = userContentController;
    self.userContentController = userContentController;

    if (self.debug) {
        [config.preferences setValue:@YES forKey:@"developerExtrasEnabled"];
    } else {
        // Disable default context menus
        WKUserScript *initScript = [WKUserScript new];
        [initScript initWithSource:@"window.wails.flags.disableWailsDefaultContextMenu = true;"
                     injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                  forMainFrameOnly:false];
        [userContentController addUserScript:initScript];
    }
    
    self.webview = [FujisanWKWebView alloc];
    CGRect init = { 0,0,0,0 };
    [self.webview initWithFrame:init configuration:config];
    [contentView addSubview:self.webview];
    [self.webview setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
    CGRect contentViewBounds = [contentView bounds];
    [self.webview setFrame:contentViewBounds];
    
    if (webviewIsTransparent) {
        [self.webview setValue:[NSNumber numberWithBool:!webviewIsTransparent] forKey:@"drawsBackground"];
    }
    
    [self.webview setNavigationDelegate:self];

    self.webview.UIDelegate = self;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:FALSE forKey:@"NSAutomaticQuoteSubstitutionEnabled"];
    
    // Mouse monitors
    [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskLeftMouseDown handler:^NSEvent * _Nullable(NSEvent * _Nonnull event) {
        id window = [event window];
        if (window == self.mainWindow) {
            self.mouseEvent = event;
        }
        return event;
    }];
    
    [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskLeftMouseUp handler:^NSEvent * _Nullable(NSEvent * _Nonnull event) {
        id window = [event window];
        if (window == self.mainWindow) {
            self.mouseEvent = nil;
            [self ShowMouse];
        }
        return event;
    }];
    
    self.applicationMenu = [NSMenu new];
    
}

- (NSMenuItem*) newMenuItem :(NSString*)title :(SEL)selector :(NSString*)key :(NSEventModifierFlags)flags {
    NSMenuItem *result = [[[NSMenuItem alloc] initWithTitle:title action:selector keyEquivalent:key] autorelease];
    if( flags != 0 ) {
        [result setKeyEquivalentModifierMask:flags];
    }
    return result;
}

- (NSMenuItem*) newMenuItem :(NSString*)title :(SEL)selector :(NSString*)key  {
    return [self newMenuItem :title :selector :key :0];
}

- (NSMenu*) newMenu :(NSString*)title {
    WailsMenu *result = [[WailsMenu new] initWithTitle:title];
    [result setAutoenablesItems:NO];
    return result;
}

- (void) Quit {
    processMessage("Q");
}

- (void) loadRequest :(NSString*)url {
    NSURL *wkUrl = [NSURL URLWithString:url];
    NSURLRequest *wkRequest = [NSURLRequest requestWithURL:wkUrl];
    [self.webview loadRequest:wkRequest];
}

- (void) SetBackgroundColour:(int)r :(int)g :(int)b :(int)a {
    float red = r/255.0;
    float green = g/255.0;
    float blue = b/255.0;
    float alpha = a/255.0;
    
    id colour = [NSColor colorWithCalibratedRed:red green:green blue:blue alpha:alpha ];
    
    [self.mainWindow setBackgroundColor:colour];
}

- (void) HideMouse {
    [NSCursor hide];
}

- (void) ShowMouse {
    [NSCursor unhide];
}

- (bool) IsFullScreen {
    long mask = [self.mainWindow styleMask];
    return (mask & NSWindowStyleMaskFullScreen) == NSWindowStyleMaskFullScreen;
}

// Fullscreen sets the main window to be fullscreen
- (void) Fullscreen {
    if( ! [self IsFullScreen] ) {
        [self.mainWindow disableWindowConstraints];
        [self.mainWindow toggleFullScreen:nil];
    }
}

// UnFullscreen resets the main window after a fullscreen
- (void) UnFullscreen {
    if( [self IsFullScreen] ) {
        [self.mainWindow applyWindowConstraints];
        [self.mainWindow toggleFullScreen:nil];
    }
}

- (void) Minimise {
    [self.mainWindow miniaturize:nil];
}

- (void) UnMinimise {
    [self.mainWindow deminiaturize:nil];
}

- (bool) IsMinimised {
    return [self.mainWindow isMiniaturized];
}

- (void) Hide {
    [self.mainWindow orderOut:nil];
}

- (void) Show {
    [self.mainWindow makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
}

- (void) HideApplication {
    [[NSApplication sharedApplication] hide:self];
}

- (void) ShowApplication {
    [[NSApplication sharedApplication] unhide:self];
    [[NSApplication sharedApplication] activateIgnoringOtherApps:TRUE];

}

- (void) Maximise {
    if (![self.mainWindow isZoomed]) {
        [self.mainWindow zoom:nil];
    }
}

- (void) ToggleMaximise {
        [self.mainWindow zoom:nil];
}

- (void) UnMaximise {
    if ([self.mainWindow isZoomed]) {
        [self.mainWindow zoom:nil];
    }
}

- (void) SetAlwaysOnTop:(int)onTop {
    if (onTop) {
        [self.mainWindow setLevel:NSStatusWindowLevel];
    } else {
        [self.mainWindow setLevel:NSNormalWindowLevel];
    }
}

- (bool) IsMaximised {
    return [self.mainWindow isZoomed];
}

- (void) ExecJS:(NSString*)script {
   [self.webview evaluateJavaScript:script completionHandler:nil];
}

- (void)webView:(WKWebView *)webView runOpenPanelWithParameters:(WKOpenPanelParameters *)parameters
    initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSArray<NSURL *> * URLs))completionHandler {
    
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.allowsMultipleSelection = parameters.allowsMultipleSelection;
    if (@available(macOS 10.14, *)) {
        openPanel.canChooseDirectories = parameters.allowsDirectories;
    }
    
    [openPanel 
        beginSheetModalForWindow:webView.window
        completionHandler:^(NSInteger result) {
            if (result == NSModalResponseOK)
                completionHandler(openPanel.URLs);
            else
                completionHandler(nil);
        }];
}

- (void)webView:(nonnull WKWebView *)webView startURLSchemeTask:(nonnull id<WKURLSchemeTask>)urlSchemeTask {
    // This callback is run with an autorelease pool
    processURLRequest(self, urlSchemeTask);
}

- (void)webView:(nonnull WKWebView *)webView stopURLSchemeTask:(nonnull id<WKURLSchemeTask>)urlSchemeTask {
    NSInputStream *stream = urlSchemeTask.request.HTTPBodyStream;
    if (stream) {
        NSStreamStatus status = stream.streamStatus;
        if (status != NSStreamStatusClosed && status != NSStreamStatusNotOpen) {
            [stream close];
        }
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    processMessage("DomReady");
}

- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures
{
    if (![[navigationAction.request.URL absoluteString] isEqualToString:@""]){
    if (![[navigationAction.request.URL absoluteString] containsString:@"https://authorize.music.apple.com/woa"] && ([[navigationAction.request.URL absoluteString] containsString:@"http://"] || [[navigationAction.request.URL absoluteString] containsString:@"https://"])  ) {
       [[NSWorkspace sharedWorkspace] openURL:[navigationAction.request URL]];
    } else if (!self.loginStarted){
    self.loginStarted = true;    
    self.loginwvconfig = configuration;
    [self.webview evaluateJavaScript:@"webkit.messageHandlers.external.postMessage(`devtoken=${MusicKit.getInstance().developerToken}`);" completionHandler:nil];
    }
    NSLog( @"Pop up webview navigationAction URL: '%@'", navigationAction.request.URL.absoluteString );}
    // WKWebView* popupWebView = [[WKWebView alloc] initWithFrame:webView.frame configuration:configuration];
    // popupWebView.UIDelegate = self;
    // popupWebView.navigationDelegate = self;

    // NSViewController* vc = [[NSViewController alloc] initWithNibName:nil bundle:nil];
    // vc.view = popupWebView;
     
    // NSWindow* window  = [NSWindow windowWithContentViewController:vc];
    // [window center];

    // [webView.window.contentViewController presentViewControllerAsSheet:vc];
    // return popupWebView;
    // [_webView removeFromSuperview];
    // [configuration.preferences setValue:@NO forKey:@"webSecurityEnabled"];
    return nil;
}

- (void)userContentController:(nonnull WKUserContentController *)userContentController didReceiveScriptMessage:(nonnull WKScriptMessage *)message {
    NSString *m = message.body;
    NSLog(@"%@", m);
    // Check for drag
    if ( [m isEqualToString:@"drag"] ) {
        if( [self IsFullScreen] ) {
            return;
        }
        if( self.mouseEvent != nil ) {
           [self.mainWindow performWindowDragWithEvent:self.mouseEvent];
        }
        return;
    }

    if ([m containsString:@"devtoken="]) {
        NSRange searchRange = NSMakeRange(9 , [m length]  - 9 );
        self.devToken = [m substringWithRange:searchRange]; 
        NSString *xhookinjectb64 = @"ZnVuY3Rpb24gZ2V0Q29va2llKG5hbWUpIHtjb25zdCB2YWx1ZSA9IGA7ICR7ZG9jdW1lbnQuY29va2llfWA7Y29uc3QgcGFydHMgPSB2YWx1ZS5zcGxpdChgOyAke25hbWV9PWApO2lmIChwYXJ0cy5sZW5ndGggPT09IDIpIHJldHVybiBwYXJ0cy5wb3AoKS5zcGxpdCgnOycpLnNoaWZ0KCk7fSB2YXIgbXlJbnRlcnZhbCA9IHNldEludGVydmFsKGZ1bmN0aW9uKCkge2lmIChnZXRDb29raWUoJ21lZGlhLXVzZXItdG9rZW4nKSl7IHdlYmtpdC5tZXNzYWdlSGFuZGxlcnMuRnVqaVNhZmFyaUlQQy5wb3N0TWVzc2FnZShgdXNlcnRva2VuPSR7Z2V0Q29va2llKCdtZWRpYS11c2VyLXRva2VuJyl9YCk7Y2xlYXJJbnRlcnZhbChteUludGVydmFsKTt9IH0sIDUwKTs=";
        NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:xhookinjectb64 options:0];
        NSString *xhookinject = [[NSString alloc] initWithData:decodedData encoding:NSUTF8StringEncoding];
        WKUserScript *script = [[WKUserScript alloc] initWithSource:xhookinject injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:NO];
        [self.loginwvconfig.userContentController addUserScript:script];
        [self.userContentController addScriptMessageHandler:self name:@"FujiSafariIPC"];
        self.loginwebview = [[WKWebView alloc] initWithFrame:self.webview.frame configuration:self.loginwvconfig];
        NSString *urlAddress = [NSString stringWithFormat:@"https://beta.music.apple.com/includes/commerce/authenticate?product=music&isFullscreen=false&isModal=true&locale=en-US&iso2code=us&expectsModalLayout=true&devToken=%@&productVersion=2308.9.0-music", self.devToken];
        NSURL *url = [NSURL URLWithString:urlAddress];
        NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
        [self.loginwebview loadRequest:requestObj];
        [NSURLProtocol wk_unregisterScheme:@"http"];
        [NSURLProtocol wk_unregisterScheme:@"https"];
        self.loginwebview.navigationDelegate = self;
        self.loginwebview.UIDelegate = self;
        self.loginwebview.frame = CGRectMake(self.webview.frame.size.width * 0.2, self.webview.frame.size.height * 0.2, self.webview.frame.size.width * 0.6, self.webview.frame.size.height * 0.6);
        [self.webview addSubview:self.loginwebview];
        return;
    }

    if([m containsString:@"usertoken="]) {
        NSRange searchRange2 = NSMakeRange(10 , [m length]  - 10 );
        NSString* userToken = [m substringWithRange:searchRange2]; 
        [NSURLProtocol wk_registerScheme:@"http"];
        [NSURLProtocol wk_registerScheme:@"https"];
        [self.loginwebview removeFromSuperview];
        self.loginwebview = nil;
        [self.webview evaluateJavaScript:[NSString stringWithFormat:@"localStorage.setItem('music.ampwebplay.media-user-token','%@');" , userToken] completionHandler:nil];
        self.loginStarted = false; 
        self.loginwvconfig = nil;
        self.devToken = nil;
        [self.webview reload];
        return;
    }
    
    const char *_m = [m UTF8String];
    
    processMessage(_m);
}


/***** Dialogs ******/
-(void) MessageDialog :(NSString*)dialogType :(NSString*)title :(NSString*)message :(NSString*)button1 :(NSString*)button2 :(NSString*)button3 :(NSString*)button4 :(NSString*)defaultButton :(NSString*)cancelButton :(void*)iconData :(int)iconDataLength {

    WailsAlert *alert = [WailsAlert new];
    
    int style = NSAlertStyleInformational;
    if (dialogType != nil ) {
        if( [dialogType isEqualToString:@"warning"] ) {
            style = NSAlertStyleWarning;
        }
        if( [dialogType isEqualToString:@"error"] ) {
            style = NSAlertStyleCritical;
        }
    }
    [alert setAlertStyle:style];
    if( title != nil ) {
        [alert setMessageText:title];
    }
    if( message != nil ) {
        [alert setInformativeText:message];
    }
    
    [alert addButton:button1 :defaultButton :cancelButton];
    [alert addButton:button2 :defaultButton :cancelButton];
    [alert addButton:button3 :defaultButton :cancelButton];
    [alert addButton:button4 :defaultButton :cancelButton];
    
    NSImage *icon = nil;
    if (iconData != nil) {
        NSData *imageData = [NSData dataWithBytes:iconData length:iconDataLength];
        icon = [[NSImage alloc] initWithData:imageData];
    }
    if( icon != nil) {
       [alert setIcon:icon];
    }
    [alert.window setLevel:NSFloatingWindowLevel];

    long response = [alert runModal];
    int result;

    if( response == NSAlertFirstButtonReturn ) {
        result = 0;
    }
    else if( response == NSAlertSecondButtonReturn ) {
        result = 1;
    }
    else if( response == NSAlertThirdButtonReturn ) {
        result = 2;
    } else {
        result = 3;
    }
    processMessageDialogResponse(result);
}

-(void) OpenFileDialog :(NSString*)title :(NSString*)defaultFilename :(NSString*)defaultDirectory :(bool)allowDirectories :(bool)allowFiles :(bool)canCreateDirectories :(bool)treatPackagesAsDirectories :(bool)resolveAliases :(bool)showHiddenFiles :(bool)allowMultipleSelection :(NSString*)filters {
    
    
    // Create the dialog
    NSOpenPanel *dialog = [NSOpenPanel openPanel];

    // Valid but appears to do nothing.... :/
    if( title != nil ) {
        [dialog setTitle:title];
    }

    // Filters - semicolon delimited list of file extensions
    if( allowFiles ) {
        if( filters != nil && [filters length] > 0) {
            filters = [filters stringByReplacingOccurrencesOfString:@"*." withString:@""];
            filters = [filters stringByReplacingOccurrencesOfString:@" " withString:@""];
            NSArray *filterList = [filters componentsSeparatedByString:@";"];
#ifdef USE_NEW_FILTERS
                NSMutableArray *contentTypes = [[NSMutableArray new] autorelease];
                for (NSString *filter in filterList) {
                    if (@available(macOS 11.0, *)) {
                        UTType *t = [UTType typeWithFilenameExtension:filter];
                        [contentTypes addObject:t];
                    }
                }
            if (@available(macOS 11.0, *)) {
                [dialog setAllowedContentTypes:contentTypes];
            }
#else
                [dialog setAllowedFileTypes:filterList];
#endif
        } else {
            [dialog setAllowsOtherFileTypes:true];
        }
        // Default Filename
        if( defaultFilename != nil ) {
            [dialog setNameFieldStringValue:defaultFilename];
        }
        
        [dialog setAllowsMultipleSelection: allowMultipleSelection];
        [dialog setShowsHiddenFiles: showHiddenFiles];

    }

    // Default Directory
    if( defaultDirectory != nil ) {
        NSURL *url = [NSURL fileURLWithPath:defaultDirectory];
        [dialog setDirectoryURL:url];
    }


    // Setup Options
    [dialog setCanChooseFiles: allowFiles];
    [dialog setCanChooseDirectories: allowDirectories];
    [dialog setCanCreateDirectories: canCreateDirectories];
    [dialog setResolvesAliases: resolveAliases];
    [dialog setTreatsFilePackagesAsDirectories: treatPackagesAsDirectories];

    // Setup callback handler
    [dialog beginSheetModalForWindow:self.mainWindow completionHandler:^(NSModalResponse returnCode) {
        if ( returnCode != NSModalResponseOK) {
            processOpenFileDialogResponse("[]");
            return;
        }
        NSMutableArray *arr = [NSMutableArray new];
        for (NSURL *url in [dialog URLs]) {
            [arr addObject:[url path]];
        }
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:arr options:0 error:nil];
        NSString *nsjson = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        processOpenFileDialogResponse([nsjson UTF8String]);
        [nsjson release];
        [arr release];
    }];
    
}


-(void) SaveFileDialog :(NSString*)title :(NSString*)defaultFilename :(NSString*)defaultDirectory :(bool)canCreateDirectories :(bool)treatPackagesAsDirectories :(bool)showHiddenFiles :(NSString*)filters; {
    
    
    // Create the dialog
    NSSavePanel *dialog = [NSSavePanel savePanel];

    // Do not hide extension
    [dialog setExtensionHidden:false];
    
    // Valid but appears to do nothing.... :/
    if( title != nil ) {
        [dialog setTitle:title];
    }

    // Filters - semicolon delimited list of file extensions
    if( filters != nil && [filters length] > 0) {
        filters = [filters stringByReplacingOccurrencesOfString:@"*." withString:@""];
        filters = [filters stringByReplacingOccurrencesOfString:@" " withString:@""];
        NSArray *filterList = [filters componentsSeparatedByString:@";"];
#ifdef USE_NEW_FILTERS
            NSMutableArray *contentTypes = [[NSMutableArray new] autorelease];
            for (NSString *filter in filterList) {
                if (@available(macOS 11.0, *)) {
                    UTType *t = [UTType typeWithFilenameExtension:filter];
                    [contentTypes addObject:t];
                }
            }
        if( contentTypes.count == 0) {
            [dialog setAllowsOtherFileTypes:true];
        } else {
            if (@available(macOS 11.0, *)) {
                [dialog setAllowedContentTypes:contentTypes];
            }
        }

#else
            [dialog setAllowedFileTypes:filterList];
#endif
    } else {
        [dialog setAllowsOtherFileTypes:true];
    }
    // Default Filename
    if( defaultFilename != nil ) {
        [dialog setNameFieldStringValue:defaultFilename];
    }
    
    // Default Directory
    if( defaultDirectory != nil ) {
        NSURL *url = [NSURL fileURLWithPath:defaultDirectory];
        [dialog setDirectoryURL:url];
    }

    // Setup Options
    [dialog setCanSelectHiddenExtension:true];
//    dialog.isExtensionHidden = false;
    [dialog setCanCreateDirectories: canCreateDirectories];
    [dialog setTreatsFilePackagesAsDirectories: treatPackagesAsDirectories];
    [dialog setShowsHiddenFiles: showHiddenFiles];

    // Setup callback handler
    [dialog beginSheetModalForWindow:self.mainWindow completionHandler:^(NSModalResponse returnCode) {
        if ( returnCode == NSModalResponseOK ) {
            NSURL *url = [dialog URL];
            if ( url != nil ) {
                processSaveFileDialogResponse([url.path UTF8String]);
                return;
            }
        }
        processSaveFileDialogResponse("");
    }];
        
}

- (void) SetAbout :(NSString*)title :(NSString*)description :(void*)imagedata :(int)datalen {
    self.aboutTitle = title;
    self.aboutDescription = description;
   
    NSData *imageData = [NSData dataWithBytes:imagedata length:datalen];
    self.aboutImage = [[NSImage alloc] initWithData:imageData];
}

-(void) About {
    
    WailsAlert *alert = [WailsAlert new];
    [alert setAlertStyle:NSAlertStyleInformational];
    if( self.aboutTitle != nil ) {
        [alert setMessageText:self.aboutTitle];
    }
    if( self.aboutDescription != nil ) {
        [alert setInformativeText:self.aboutDescription];
    }
    
    
    [alert.window setLevel:NSFloatingWindowLevel];
    if ( self.aboutImage != nil) {
        [alert setIcon:self.aboutImage];
    }

    [alert runModal];
}

@end

