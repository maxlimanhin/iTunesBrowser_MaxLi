//
//  SongTableViewCell.swift
//  iTunesBrowser
//
//  Created by Max on 3/12/2020.
//

import UIKit

class SongTableViewCell: UITableViewCell {

    @IBOutlet var bgView: UIView!
    @IBOutlet weak var thrumbnailImageVIew: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
}
