#import <Foundation/Foundation.h>

extern NSString *const kArticleHeadlineProperty;
extern NSString *const kArticleURLProperty;
extern NSString *const kArticleDescriptionProperty;
extern NSString *const kArticleDateProperty;
extern NSString *const kArticleReadProperty;

/* This property matches url of feed in feedStore */
extern NSString *const kArticleGroupURLProperty;

/* Use this to send any information to log panel */
extern NSString *const RSSReaderLogNotification;

/* Notify when user want to change the font of user interface.
 * The new font should be read from user defaults */
extern NSString *const RSSReaderFontChangeNotification;

/* Toolbar */
extern NSString *const RSSReaderToolbarIdentifier;
extern NSString *const RSSReaderSubscribeToolbarItemIdentifier;
extern NSString *const RSSReaderRefreshAllToolbarItemIdentifier;
extern NSString *const RSSReaderSearchToolbarItemIdentifier;

/* Frame name for saving */
extern NSString *const RSSReaderMainWindowFrameName;

/* User Defaults */
extern NSString *const RSSReaderRemoveArticlesAfterDefaults;
extern NSString *const RSSReaderWebBrowserDefaults;
extern NSString *const RSSReaderBookmarkViewFrameDefaults;
extern NSString *const RSSReaderFeedListFontDefaults;
extern NSString *const RSSReaderArticleListFontDefaults;
extern NSString *const RSSReaderArticleContentFontDefaults;
extern NSString *const RSSReaderFeedListSizeDefaults;
extern NSString *const RSSReaderArticleListSizeDefaults;
extern NSString *const RSSReaderArticleContentSizeDefaults;
extern NSString *const RSSReaderUseSystemFontDefaults;
extern NSString *const RSSReaderUseSystemSizeDefaults;

