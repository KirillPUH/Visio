//
//  SettingsTableViewController.swift
//  Visio
//
//  Created by Kirill Pukhov on 09.05.2022.
//

import UIKit

fileprivate enum Settings: CaseIterable {
    case faceRectangles
    
    func configureCell(for tableView: UITableView) -> UITableViewCell {
        switch self {
        case .faceRectangles:
            let cell = tableView.dequeueReusableCell(withIdentifier: SwitchSettingsTableViewCell.identifier) as! SwitchSettingsTableViewCell
            cell.configure(title: "Show face rectangles", key: "FaceRectangles")
            return cell
        }
    }
}

class SettingsTableViewController: UITableViewController {
    public static let identifier = "SettingsTableViewController"
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Settings.allCases.count
    }
    
    @objc
    func backButtonAction() {
        dismiss(animated: true)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        Settings.allCases[indexPath.row].configureCell(for: tableView)
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        false
    }
    
    override var prefersStatusBarHidden: Bool { true }
}
