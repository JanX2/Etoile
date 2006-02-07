/* All Rights reserved */

@interface AppController : NSObject
{
  	id list;
  	id status;
  	id resultsTests;
  	id summary;
	id popupTestsSets;
  	id preferencesPanel;
	id preferencesController;
}

- (void) showPreferencesPanel: (id)sender;
- (void) runTests: (id)sender;
- (void) popupTestsSets: (id)sender;

- (NSArray *) scanOutput: (NSString *)output;

- (void) noLight;
- (void) greenLight;
- (void) redLight;

- (void) testsSetsChanged: (NSNotification *)not;

@end
