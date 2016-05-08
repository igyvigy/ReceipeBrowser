//
//  ReceipeCell.swift
//  ReceipeBrowser
//
//  Created by Andrii on 5/8/16.
//  Copyright © 2016 Andrii. All rights reserved.
//

import UIKit

class ReceipeCell: UITableViewCell {
    
    @IBOutlet weak var recImageView: UIImageView!
    @IBOutlet weak var recTitleLabel: UILabel!
    @IBOutlet weak var recRatingLabel: UILabel!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        recImageView.layer.cornerRadius = 5.0
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configureWithReceipe(receipe:AnyObject){
        if let imageData = receipe.valueForKey("image") as? NSData{
            recImageView.image = UIImage(data: imageData)
        } else {
            if let urlString = receipe.valueForKey("imageURL") as? String{
                recImageView.imageFromUrl(urlString)
            }
        }
        recTitleLabel.text = receipe.title
        if let rating = receipe.valueForKey("socialRank") as? NSNumber{
            recRatingLabel.text = "\(Int(rating))"
        }
    }

}
