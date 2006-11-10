#import <Foundation/Foundation.h>

extern NSString *const kArticleHeadlineProperty;
extern NSString *const kArticleURLProperty;
extern NSString *const kArticleDescriptionProperty;
extern NSString *const kArticleDateProperty;
extern NSString *const kArticleReadProperty;

/* This property matches url of feed in feedStore */
extern NSString *const kArticleGroupURLProperty;

/* When feed list changed, mostly due to a fetch of rss.
 * Object is the changed feed. */
extern NSString *const RSSReaderFeedListChangedNotification;

/* Use this to send any information to log panel */
extern NSString *const RSSReaderLogNotification;

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
