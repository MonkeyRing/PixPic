//
//  PostService.swift
//  P-effect
//
//  Created by Jack Lapin on 16.02.16.
//  Copyright © 2016 Yalantis. All rights reserved.
//

import Foundation

private let messageUploadSuccessful = "Upload successful!"

typealias LoadingPostsCompletion = (posts: [Post]?, error: NSError?) -> Void

class PostService {
    lazy var reachabilityService = ReachabilityService()
    
    // MARK: - Public methods
    func loadPosts(user: User? = nil, completion: LoadingPostsCompletion) {
        let query = Post.sortedQuery
        query.limit = Constants.DataSource.QueryLimit
        loadPosts(user, query: query, completion: completion)
    }
    
    func loadPagedPosts(user: User? = nil, offset: Int = 0, completion: LoadingPostsCompletion) {
        let query = Post.sortedQuery
        query.limit = Constants.DataSource.QueryLimit
        query.skip = offset
        loadPosts(user, query: query, completion: completion)
    }
    
    func savePost(image: PFFile, comment: String? = nil) {
        image.saveInBackgroundWithBlock({ succeeded, error in
            if succeeded {
                print("Saved!")
                self.uploadPost(image, comment: comment)
            } else if let error = error {
                print(error)
            }
            },
            progressBlock: { progress in
                print("Uploaded: \(progress)%")
            }
        )
    }
    
    // MARK: - Private methods
    private func uploadPost(image: PFFile, comment: String?) {
        guard let user = User.currentUser() else {
            // Auth service
            return
        }
        let post = Post(image: image, user: user, comment: comment)
        post.saveInBackgroundWithBlock{ succeeded, error in
            if succeeded {
                AlertService.simpleAlert(messageUploadSuccessful)
                NSNotificationCenter.defaultCenter().postNotificationName(
                    Constants.NotificationName.NewPostUploaded,
                    object: nil
                )
            } else {
                if let error = error?.localizedDescription {
                    print(error)
                }
            }
        }
    }
    
    private func loadPosts(user: User?, query: PFQuery, completion: LoadingPostsCompletion) {
        var posts = [Post]()
        
        if User.currentUser() == nil {
            print("No user signUP")
            completion(posts: nil, error: nil)
            return
        }
        
        if !reachabilityService.isReachable() {
            query.fromLocalDatastore()
        }
        
        if let user = user {
            query.whereKey("user", equalTo: user)
        }
        query.findObjectsInBackgroundWithBlock { objects, error in
            if let objects = objects {
                for object in objects {
                    posts.append(object as! Post)
                    object.saveEventually()
                    object.pinInBackground()
                }
                completion(posts: posts, error: nil)
            } else if let error = error {
                print(error.localizedDescription)
                completion(posts: nil, error: error)
            } else {
                completion(posts: nil, error: nil)
            }
        }
    }
    
}