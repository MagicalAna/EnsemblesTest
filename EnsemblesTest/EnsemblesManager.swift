//
//  EnsemblesManager.swift
//  totowallet
//
//  Created by MagicAna on 2023/3/1.
//

import UIKit
import Ensembles
import MagicalRecord
import CoreData


class EnsemblesManager: NSObject, CDEPersistentStoreEnsembleDelegate {
    static let manager = EnsemblesManager()
    var cloudFileSystem: CDEICloudFileSystem!
    var ensemble: CDEPersistentStoreEnsemble!
    
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    func setup() {
        CDESetCurrentLoggingLevel(CDELoggingLevel.verbose.rawValue)
        
        let model = NSManagedObjectModel.mr_newManagedObjectModelNamed("EnsemblesTest.momd")!
        NSManagedObjectModel.mr_setDefaultManagedObjectModel(model)
        MagicalRecord.setShouldAutoCreateManagedObjectModel(false)
        MagicalRecord.setupAutoMigratingCoreDataStack()
        
        let modelURL = Bundle.main.url(forResource: "EnsemblesTest", withExtension: "momd")
        let storeURL = NSPersistentStore.mr_defaultLocalStoreUrl()
        
        cloudFileSystem = CDEICloudFileSystem(ubiquityContainerIdentifier: "iCloud.com.ziheng.CoreDataTest")
        ensemble = CDEPersistentStoreEnsemble(ensembleIdentifier: "Model", persistentStore: storeURL, managedObjectModelURL: modelURL!, cloudFileSystem: cloudFileSystem)
        ensemble.delegate = self
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(localSaveOccurred(_:)),
                                               name: NSNotification.Name.CDEMonitoredManagedObjectContextDidSave,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(cloudDataDidDownload(_:)),
                                               name: NSNotification.Name.CDEICloudFileSystemDidDownloadFiles,
                                               object: nil)
    }
    
    
    func enterBackground() {
        let identifier = UIApplication.shared.beginBackgroundTask()
        NSManagedObjectContext.mr_default().mr_saveToPersistentStore {
            [weak self] _, _ in
            guard let self = self else { return }
            self.sync {
                UIApplication.shared.endBackgroundTask(identifier)
            }
        }
    }
    
    
    @objc func localSaveOccurred(_ notif: Notification) {
        sync(completion: nil)
    }
    
    
    @objc func cloudDataDidDownload(_ notif: Notification) {
        sync(completion: nil)
    }
    
    
    func sync(completion: (() -> Void)?) {
        guard !ensemble.isMerging else { return }
        if !ensemble.isLeeched {
            ensemble.leechPersistentStore {
                error in
                if let error = error {
                    print(error.localizedDescription)
                }
                completion?()
            }
        } else {
            ensemble.merge {
                error in
                if let error = error {
                    print(error.localizedDescription)
                }
                completion?()
            }
        }
    }
    
    
    // MARK: - CDEPersistentStoreEnsembleDelegate
    func persistentStoreEnsemble(_ ensemble: CDEPersistentStoreEnsemble, didSaveMergeChangesWith notification: Notification) {
        let rootContext = NSManagedObjectContext.mr_rootSaving()
        rootContext.performAndWait {
            rootContext.mergeChanges(fromContextDidSave: notification)
        }

        let mainContext = NSManagedObjectContext.mr_default()
        mainContext.performAndWait {
            mainContext.mergeChanges(fromContextDidSave: notification)
        }
        
        let inserted: Set<NSManagedObject> = (notification.userInfo?["inserted"] as? Set<NSManagedObject>) ?? []
        let updated: Set<NSManagedObject> = (notification.userInfo?["updated"] as? Set<NSManagedObject>) ?? []
        let deleted: Set<NSManagedObject> = (notification.userInfo?["deleted"] as? Set<NSManagedObject>) ?? []
        let insertCount = inserted.count
        let updateCount = updated.count
        let deleteCount = deleted.count
        print("SYNC", #function, "didSaveMergeChangesWith insert \(insertCount)  updated \(updateCount)  delete \(deleteCount)")
    }
    
    
    func persistentStoreEnsemble(_ ensemble: CDEPersistentStoreEnsemble, globalIdentifiersFor objects: [NSManagedObject]) -> [NSObject] {
        return objects.map({ $0.value(forKey: "id") as! NSObject })
    }
    
    
    func persistentStoreEnsembleWillImportStore(_ ensemble: CDEPersistentStoreEnsemble) {
        print("SYNC", #function)
    }
    
    func persistentStoreEnsembleDidImportStore(_ ensemble: CDEPersistentStoreEnsemble) {
        print("SYNC", #function)
    }
    
    func persistentStoreEnsemble(_ ensemble: CDEPersistentStoreEnsemble, shouldSaveMergedChangesIn savingContext: NSManagedObjectContext, reparationManagedObjectContext reparationContext: NSManagedObjectContext) -> Bool {
        return true
    }
    
    func persistentStoreEnsemble(_ ensemble: CDEPersistentStoreEnsemble, didFailToSaveMergedChangesIn savingContext: NSManagedObjectContext, error: Error, reparationManagedObjectContext reparationContext: NSManagedObjectContext) -> Bool {
        print("SYNC", #function, error)
        return false
    }
    
    func persistentStoreEnsemble(_ ensemble: CDEPersistentStoreEnsemble, willMergeChangesForEntity entity: NSEntityDescription) {
        let log = "willMergeChangesForEntity \(entity.name ?? "")"
        print("SYNC", log)
    }
    
    func persistentStoreEnsemble(_ ensemble: CDEPersistentStoreEnsemble, didMergeChangesForEntity entity: NSEntityDescription) {
        let log = "didMergeChangesForEntity \(entity.name ?? "")"
        print("SYNC", log)
    }
    
    func persistentStoreEnsemble(_ ensemble: CDEPersistentStoreEnsemble, didDeleechWithError error: Error) {
        print("SYNC", "\(#function) \(error)")
    }
}
