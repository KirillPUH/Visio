//
//  SliderSettingsTableViewCell.swift
//  Visio
//
//  Created by Kirill Pukhov on 09.05.2022.
//

import UIKit

class SliderSettingsTableViewCell: UITableViewCell {
    public static let identifier = "SliderSettingsTableViewCell"
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var valueSlider: UISlider!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
