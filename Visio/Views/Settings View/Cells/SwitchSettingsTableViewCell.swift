//
//  SwitchSettingsTableViewCell.swift
//  Visio
//
//  Created by Kirill Pukhov on 09.05.2022.
//

import UIKit
import RxSwift
import RxCocoa

final class SwitchSettingsTableViewCell: UITableViewCell {
    public static let identifier = "SwitchSettingsTableViewCell"
    
    private var disposeBag: DisposeBag!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var optionSwitch: UISwitch!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        disposeBag = DisposeBag()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    public func configure(title: String, key: String) {
        titleLabel.text = title
        
        if UserDefaults.standard.object(forKey: key) == nil {
            UserDefaults.standard.set(false, forKey: key)
            optionSwitch.isOn = false
        } else {
            optionSwitch.isOn = UserDefaults.standard.bool(forKey: key)
        }
        
        optionSwitch.rx.value.asDriver()
            .drive(onNext: { isOn in
                UserDefaults.standard.set(isOn, forKey: key)
            })
            .disposed(by: disposeBag)
    }

}
