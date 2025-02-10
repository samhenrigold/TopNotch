//
//  ModalSheetViewController.swift
//  TopNotchDemo
//
//  Created by Sam Gold on 2025-02-10.
//

import UIKit

class ModalSheetViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = "Modal Sheet"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done,
                                                           target: self,
                                                           action: #selector(dismissModal))
    }
    
    @objc private func dismissModal() {
        dismiss(animated: true, completion: nil)
    }
}
