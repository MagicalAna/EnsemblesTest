//
//  ViewController.swift
//  Simple Sync in Swift
//
//  Created by Drew McCormack on 31/01/16.
//  Copyright © 2016 Drew McCormack. All rights reserved.
//

import UIKit
import CoreData
import MagicalRecord
import ReactiveCocoa
import ReactiveSwift


class ViewController: UIViewController {
    
    var managedObjectContext: NSManagedObjectContext!
    
    var numberLabel: UILabel!
    var activityIndicator: UIActivityIndicatorView!
    var button: UIButton!
    var syncButton: UIButton!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        numberLabel = UILabel()
        numberLabel.textAlignment = .center
        numberLabel.font = UIFont.systemFont(ofSize: 108, weight: .ultraLight)
        view.addSubview(numberLabel)
        
        activityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
        view.addSubview(activityIndicator)
        
        button = UIButton()
        button.setTitle("Add Model", for: .normal)
        button.setTitleColor(.blue, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        button.reactive.controlEvents(.touchUpInside).observeValues {
            [weak self] _ in
            guard let self = self else { return }
            let numberHolder = NumberHolder.mr_createEntity()
            numberHolder?.uniqueIdentifier = Date().formatted()
            
            NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait()
            EnsemblesManager.manager.sync {
                [weak self] in
                guard let self = self else { return }
                self.refresh()
            }
        }
        view.addSubview(button)
        
        syncButton = UIButton()
        syncButton.setTitle("Sync", for: .normal)
        syncButton.setTitleColor(.blue, for: .normal)
        syncButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        syncButton.reactive.controlEvents(.touchUpInside).observeValues {
            [weak self] _ in
            guard let self = self else { return }
            EnsemblesManager.manager.sync {
                [weak self] in
                guard let self = self else { return }
                self.refresh()
            }
        }
        view.addSubview(syncButton)
        
        refresh()
    }
    
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        numberLabel.frame = CGRect(x: 0, y: 126, width: view.bounds.width, height: 123)
        activityIndicator.sizeToFit()
        activityIndicator.center = CGPoint(x: view.bounds.width / 2, y: numberLabel.frame.maxY + 19 + activityIndicator.bounds.height / 2)
        button.sizeToFit()
        button.center = CGPoint(x: view.bounds.width / 2, y: activityIndicator.frame.maxY + 55 + button.bounds.height / 2)
        syncButton.sizeToFit()
        syncButton.center = CGPoint(x: view.bounds.width / 2, y: button.frame.maxY + 55 + syncButton.bounds.height / 2)
    }
    
    
    @objc func refresh() {
        let count = NumberHolder.mr_findAll()?.count ?? -1
        numberLabel.text = "\(count)"
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }
}

