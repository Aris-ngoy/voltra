#import <React/RCTViewManager.h>
#import <React/RCTUIManager.h>

@interface RCT_EXTERN_REMAP_MODULE(VoltraView, VoltraViewManager, RCTViewManager)

RCT_EXPORT_VIEW_PROPERTY(payload, NSString)
RCT_EXPORT_VIEW_PROPERTY(viewId, NSString)

@end
