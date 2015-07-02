//
//  VMSynchronizedAudioList.swift
//  VKMusicOffline
//
//  Created by Vjacheslav Volodko on 25.06.15.
//  Copyright (c) 2015 Vjacheslav Volodko. All rights reserved.
//

import Foundation
import VK
import CoreDataStorage

class VMSynchronizedAudioList: VMOfflineAudioList {
    
    var model: CDModel!
    var downloadManager: VMAudioDownloadManager!
    var user: VKUser?
    
    override var identifier: NSUUID {
        get {
            return NSUUID.vm_syncAudioListUUID
        }
        set {
            
        }
    }
    
    override init(storedAudioList: CDAudioList) {
        super.init(storedAudioList: storedAudioList)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private var request: VKRequest? {
        if let user = self.user {
            return VKApi.requestWithMethod("audio.get",
                andParameters:[VK_API_OWNER_ID: user.id],
                andHttpMethod:"GET")
        } else {
            return nil
        }
    }
    
    func synchronize() {
        self.request?.executeWithResultBlock({ (response: VKResponse!) -> Void in
            if response != nil {
                if let vkAudios = VKAudios(dictionary:(response.json as! [NSObject : AnyObject])) {
                    
                    var audiosToDelete: [VMAudio] = []
                    
                    let loadedAudios = vkAudios.items.copy() as! [VKAudio]
                    let storedAudios = self.storedAudioList.audios
                    
                    var updatedAudios: [VMAudio] = []
                    var audiosToInsert: [Int: VMAudio] = [:]
                        
                    for (var i: Int = 0; i < loadedAudios.count; i++) {
                        let loadedAudio = loadedAudios[i]
                        if let storedAudio = self.model.audioWithID(loadedAudio.id) {
                            let loadedAudio = VMAudio(storedAudio: storedAudio)
                            updatedAudios.append(loadedAudio)
                            
                            // in case audio was not already loaded for some reason (e.g. app crash)
                            if loadedAudio.localFileName == nil {
                                self.downloadManager.downloadAudio(loadedAudio)
                            }
                        } else {
                            let addedAudio = VMAudio(audio: loadedAudio)
                            updatedAudios.append(addedAudio)
                            audiosToInsert[i] = addedAudio
                            self.downloadManager.downloadAudio(addedAudio)
                        }
                    }
                    
                    var commonAudios = self.audios.filter {
                        return find(loadedAudios.map{ $0.id }, $0.id) != nil
                    }
                    
                    var audiosToMove: [(audio: VMAudio, from: Int, to: Int)] = []
                    for audio in commonAudios {
                        if let oldIndex = find(self.audios, audio), newIndex = find(updatedAudios, audio)
                            where oldIndex != newIndex {
                                audiosToMove.append((audio: audio, from: oldIndex, to: newIndex))
                        }
                    }
                    
                    var audiosToRemove = self.audios.filter {
                        return find(loadedAudios.map{ $0.id }, $0.id) == nil
                    }
                    
                    // TODO: use insertedAudios, audiosToMove and audiosToRemove to make updates
                    
                    self.audios = updatedAudios
                }
            }
        }, errorBlock: { (error: NSError!) -> Void in
            
        })
    }
    
    
}
