//
//  VMAudioDownloadManager.swift
//  VKMusicOffline
//
//  Created by Vjacheslav Volodko on 25.06.15.
//  Copyright (c) 2015 Vjacheslav Volodko. All rights reserved.
//

import Foundation

@objc
protocol VMAudioDownloadManagerDelegate {
    optional func downloadManager(downloadManager:VMAudioDownloadManager, didLoadFile url:NSURL, forAudioWithID audioID:NSNumber)
    optional func downloadManager(downloadManager:VMAudioDownloadManager, didLoadLyrics lyrics:VMLyrics, forAudio audio:VMAudio)
}

class VMAudioDownloadManager: NSObject, NSURLSessionDownloadDelegate {
    
    weak var delegate: VMAudioDownloadManagerDelegate? = nil
   
    var URLSession: NSURLSession?
    
    var backgroundURLSessionCompletionHandler: (() -> Void)?
    
    private var downloadTasks: Dictionary<Int, NSNumber> = Dictionary() // download task id, audio id
    
    init(delegate: VMAudioDownloadManagerDelegate?) {
        super.init()
        
        self.delegate = delegate
        let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("com.vv.vkmusic-offline")
        self.URLSession = NSURLSession(configuration: configuration, delegate: self, delegateQueue: NSOperationQueue.mainQueue())

    }
    
    func downloadAudio(audio:VMAudio) {
        if (audio.localFileName != nil) {
            return
        }
        let downloadTaskOptional = self.URLSession?.downloadTaskWithURL(audio.URL)
        if let downloadTask = downloadTaskOptional {
            self.downloadTasks[downloadTask.taskIdentifier] = audio.id
            downloadTask.taskDescription = audio.formattedTitle as String
            downloadTask.resume()
        }
        if let lyrics = audio.lyrics {
            if lyrics.text == nil {
                lyrics.loadText { (error: NSError!) -> Void in
                    self.delegate?.downloadManager?(self, didLoadLyrics: lyrics, forAudio: audio)
                }
            }
        }
    }
    
    func getAudioDownloadTaskList(completion: ((downloadTasks:[AnyObject]) -> Void)?) {
        self.URLSession?.getTasksWithCompletionHandler({ (dataTasks: [AnyObject]!, uploadTasks: [AnyObject]!, downloadTasks: [AnyObject]!) -> Void in
            if (downloadTasks != nil) {
                completion?(downloadTasks: downloadTasks)
            }
        })
    }
    
    // MARK: - NSURLSessionDownloadDelegate
    
    /* Sent when a download task that has completed a download.  The delegate should
    * copy or move the file at the given location to a new location as it will be
    * removed when the delegate message returns. URLSession:task:didCompleteWithError: will
    * still be called.
    */
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        if let audioID = self.downloadTasks[downloadTask.taskIdentifier] {
            self.delegate?.downloadManager?(self, didLoadFile: location, forAudioWithID: audioID)
        }
    }
    
    /* Sent periodically to notify the delegate of download progress. */
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        NSLog("URLSession downloadTask \(downloadTask.taskIdentifier) didWriteData \(bytesWritten) bytes, totalBytesWritten \(totalBytesWritten), totalBytesExpectedToWrite \(totalBytesExpectedToWrite)")
    }
    
    /* Sent when a download has been resumed. If a download failed with an
    * error, the -userInfo dictionary of the error will contain an
    * NSURLSessionDownloadTaskResumeData key, whose value is the resume
    * data.
    */
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        
    }
    
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        self.backgroundURLSessionCompletionHandler!()
    }

}
