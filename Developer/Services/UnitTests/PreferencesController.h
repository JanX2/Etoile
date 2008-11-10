/* All Rights reserved */

@interface PreferencesController : NSObject
{
  id popupTestsSets;
  id tvBundles;
  id windowPreferences;
  id windowRenameSet;
  id windowNewSet;
  id toolPathField;
  NSString *selectedSetKey;
}

- (NSUserDefaults *) userDefaults;

/*
 * Actions
 */

- (void) checkWithTests: (id)sender;
- (void) popupRunTestsSets: (id)sender;
- (void) ukrunPath: (id)sender;
- (void) addTestsBundle: (id)sender;
- (void) removeTestsBundle: (id)sender;
- (void) endSetWindow: (id)sender;

- (void) endNewSetSheet: (id)sheet returnCode: (int)tag contextInfo: (id)info;
- (void) endRenameSetSheet: (id)sheet returnCode: (int)tag contextInfo: (id)info;

@end

/*
 * Notifications
 */
extern NSString *TestsSetsChangedNotification;

/*
 * Defaults
 */
 
extern NSString *ToolPathDefault;
extern NSString *TestsSetsDefault;
extern NSString *ActiveTestsSetDefault;
extern NSString *LastEditedTestsSetDefault;
