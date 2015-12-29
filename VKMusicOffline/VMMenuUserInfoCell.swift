//
//  VMMenuUserInfoCell.swift
//  VKMusicOffline
//
//  Created by Vjacheslav Volodjko on 25.09.14.
//  Copyright (c) 2014 Vjacheslav Volodko. All rights reserved.
//

import UIKit
import VKSdkFramework
import UIViews

class VMMenuUserInfoCell: UITableViewCell {
    
    // MARK: - IBOutlets
    @IBOutlet weak var firstNameLabel: UILabel!
    @IBOutlet weak var lastNameLabel: UILabel!
    @IBOutlet weak var userImageView: URLImageView!
    
    // MARK: - VKUser
    var user : VKUser! {
        willSet (newUser) {
            if (newUser != nil) {
                self.firstNameLabel.text = newUser.first_name
                self.lastNameLabel.text = newUser.last_name
                if let photoURLString = newUser.photo_200 {
                    self.userImageView.imageURL = NSURL(string:photoURLString)
                }
            }
        }
    }
    
    // MARK: - Overrides

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
