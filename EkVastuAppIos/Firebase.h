// Custom Firebase.h header to fix FirebaseAuth-Swift.h issue
#ifndef Firebase_h
#define Firebase_h

#import <Foundation/Foundation.h>

// Core Firebase
#import <FirebaseCore/FirebaseCore.h>

// Firebase Auth
#if __has_include(<FirebaseAuth/FirebaseAuth.h>)
#import <FirebaseAuth/FirebaseAuth.h>
// Skip the Swift header import that causes issues
// #import <FirebaseAuth/FirebaseAuth-Swift.h>
#endif

// Firebase Firestore
#if __has_include(<FirebaseFirestore/FirebaseFirestore.h>)
#import <FirebaseFirestore/FirebaseFirestore.h>
#elif __has_include(<FirebaseFirestoreInternal/FirebaseFirestoreInternal.h>)
#import <FirebaseFirestoreInternal/FirebaseFirestoreInternal.h>
#endif

// Firebase Storage
#if __has_include(<FirebaseStorage/FirebaseStorage.h>)
#import <FirebaseStorage/FirebaseStorage.h>
#endif

// Firebase Dynamic Links
#if __has_include(<FirebaseDynamicLinks/FirebaseDynamicLinks.h>)
#import <FirebaseDynamicLinks/FirebaseDynamicLinks.h>
#endif

#endif /* Firebase_h */
