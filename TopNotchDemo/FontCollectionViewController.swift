//
//  FontTableViewController.swift
//  TopNotchDemo
//
//  Created by Sam Gold on 2025-02-10.
//

import UIKit
import TopNotch

class FontTableViewController: UITableViewController {
    
    private let fontFamilies = UIFont.familyNames
    
    override init(style: UITableView.Style = .insetGrouped) {
        super.init(style: style)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Font Families"
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "FontCell")
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Show Modal", style: .plain, target: self, action: #selector(showModal))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let watermarkConfig = TopNotchConfiguration(animationDuration: 0.3,
                                                    shouldAnimate: true,
                                                    shouldHideForTaskSwitcher: false)
        
        let notchLabel = UILabel()
        notchLabel.text = "Top Notch!"
        notchLabel.textColor = .white
        notchLabel.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.7)
        notchLabel.textAlignment = .center
        
        TopNotchManager.shared.show(customView: notchLabel, with: watermarkConfig)
    }
    
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fontFamilies.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "FontCell", for: indexPath)
        cell.textLabel?.text = fontFamilies[indexPath.row]
        return cell
    }
    
    // MARK: - Actions
    
    @objc private func showModal() {
        let modalVC = ModalSheetViewController()
        let nav = UINavigationController(rootViewController: modalVC)
        nav.modalPresentationStyle = .automatic
        present(nav, animated: true, completion: nil)
    }
}
