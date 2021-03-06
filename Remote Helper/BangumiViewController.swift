//
//  BangumiViewController.swift
//  Remote Helper
//
//  Created by Venj Chu on 2017/4/2.
//  Copyright © 2017年 Home. All rights reserved.
//

import UIKit
import PKHUD
import MWPhotoBrowser

class BangumiViewController: UITableViewController, MWPhotoBrowserDelegate, UIPopoverPresentationControllerDelegate {
    let CellIdentifier = "BangumiTableCell"
    var bangumi: Bangumi? = nil

    var editButton: UIBarButtonItem?
    var infoButton: UIBarButtonItem?
    var imagesButton: UIBarButtonItem?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Theme
        navigationController?.navigationBar.barTintColor = Helper.shared.mainThemeColor()
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor : UIColor.white]
        navigationController?.toolbar.tintColor = Helper.shared.mainThemeColor()

        // Revert back to old UITableView behavior
        if #available(iOS 9.0, *) {
            tableView.cellLayoutMarginsFollowReadableWidth = false
        }

        title = bangumi?.title ?? ""

        // Toolbar Button Items
        let selectAllButton = UIBarButtonItem(title: NSLocalizedString("Select All", comment: "Select All"), style: .plain, target: self, action: #selector(selectAllCells(_:)))
        let deSelectAllButton = UIBarButtonItem(title: NSLocalizedString("Deselect All", comment: "Deselect All"), style: .plain, target: self, action: #selector(deSelectAllCells(_:)))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let miButton = UIBarButtonItem(title: NSLocalizedString("Mi", comment: "Mi"), style: .plain, target: self, action: #selector(miDownloadAll(_:)))
        toolbarItems = [selectAllButton, deSelectAllButton, spaceButton, miButton]

        // Allow edit
        tableView.allowsSelection = true
        tableView.allowsMultipleSelectionDuringEditing = true

        // Navigation Items
        let editButtonItem = UIBarButtonItem(title: NSLocalizedString("Select", comment: "Select"), style: .plain, target: self, action: #selector(showEdit(_:)))
        editButton = editButtonItem
        let imagesButtonItem = UIBarButtonItem(title: NSLocalizedString("Images", comment: "Images"), style: .plain, target: self, action: #selector(showImages))
        imagesButton = imagesButtonItem
        let infoButtonItem = UIBarButtonItem(title: NSLocalizedString("Infomation", comment: "Infomation"), style: .plain, target: self, action: #selector(showInfo))
        infoButton = infoButtonItem
        navigationItem.rightBarButtonItems = [editButtonItem, imagesButtonItem, infoButtonItem]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }

    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.setToolbarHidden(true, animated: true)
        super.viewWillDisappear(animated)
    }

    // MARK: - BarButtonItem Actions

    @objc func selectAllCells(_ sender: Any?) {
        guard let count = bangumi?.links.count, count != 0 else { return }
        if tableView.isEditing {
            for i in 0 ..< count {
                let indexPath = IndexPath(row: i, section: 0)
                tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            }
        }
    }

    @objc func deSelectAllCells(_ sender: Any?) {
        guard let count = bangumi?.links.count, count != 0 else { return }
        if tableView.isEditing {
            for i in 0 ..< count {
                let indexPath = IndexPath(row: i, section: 0)
                tableView.deselectRow(at: indexPath, animated: false)
            }
        }
    }

    @objc func miDownloadAll(_ sender: Any?) {
        guard let links = bangumi?.links, links.count > 0 else { return }
        guard let linksToDownload = tableView.indexPathsForSelectedRows?.map({ links[$0.row] }) else { return }
        Helper.shared.miDownloadForLinks(linksToDownload, fallbackIn: self)
    }

    @objc func showEdit(_ sender: UIBarButtonItem?) {
        if !tableView.isEditing {
            tableView.setEditing(true, animated: true)
            editButton?.title = NSLocalizedString("Done", comment: "Done")
            infoButton?.isEnabled = false
            imagesButton?.isEnabled = false
            navigationController?.setToolbarHidden(false, animated: true)
        }
        else {
            exitEdit()
        }
    }

    func exitEdit() {
        navigationController?.setToolbarHidden(true, animated: true)
        tableView.setEditing(false, animated: true)
        editButton?.title = NSLocalizedString("Select", comment: "Select")
        infoButton?.isEnabled = true
        imagesButton?.isEnabled = true
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bangumi?.links.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: CellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: CellIdentifier)
        }

        let index = indexPath.row
        let link = bangumi?.links[index]
        cell.textLabel?.text = link?.vc_lastPathComponent() // TODO: Make it human-readable.
        return cell
    }

    // MARK: - Tableview delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Editing
        if tableView.isEditing { return }
        // Not editing
        tableView.deselectRow(at: indexPath, animated: true)
        let index = indexPath.row
        guard let link = bangumi?.links[index] else { return }
        UIPasteboard.general.string = link

        let alert = UIAlertController(title: NSLocalizedString("Info", comment: "Info"), message: link, preferredStyle: .alert)

        let miAction = UIAlertAction(title: NSLocalizedString("Mi", comment: "Mi"), style: .default) { (action) in
            Helper.shared.miDownloadForLink(link, fallbackIn: self)
        }
        alert.addAction(miAction)

        if link.matches("^magnet:") {
            let transmissionAction = UIAlertAction(title: "Transmission", style: .default) { (action) in
                Helper.shared.transmissionDownload(for: link)
            }
            alert.addAction(transmissionAction)
        }

        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel)
        alert.addAction(cancelAction)

        alert.view.tintColor = Helper.shared.mainThemeColor()

        self.present(alert, animated: true, completion: nil)
    }


    // MARK: - Select table view

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) { }

    // MARK: - Actions
    @objc func showImages(_ sender: Any?) {
        let photoBrowser = MWPhotoBrowser(delegate: self)
        photoBrowser?.displayActionButton = false
        photoBrowser?.displayNavArrows = true
        photoBrowser?.zoomPhotosToFill = false
        self.navigationController?.pushViewController(photoBrowser!, animated: true)
    }

    @objc func showInfo(_ sender: Any?) {
        if let info = bangumi?.info {
            let alert = UIAlertController(title: NSLocalizedString("Infomation", comment: "Infomation"), message: info, preferredStyle: .actionSheet)
            let cancelAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .cancel, handler: nil)
            alert.addAction(cancelAction)
            alert.popoverPresentationController?.delegate = self
            alert.view.tintColor = Helper.shared.mainThemeColor()
            present(alert, animated: true) {
                alert.popoverPresentationController?.passthroughViews = nil
            }
        }
        else {
            let alert = UIAlertController(title: NSLocalizedString("Info", comment: "Info"), message: NSLocalizedString("There's no infomation available.", comment: "There's no infomation available."), preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .cancel, handler: nil)
            alert.addAction(cancelAction)
            alert.view.tintColor = Helper.shared.mainThemeColor()
            present(alert, animated: true, completion: nil)
        }
    }

    // MARK: - UIPopoverPresentationControllerDelegate

    func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {
        popoverPresentationController.barButtonItem = infoButton
    }

    // MARK: - MWPhotoBrowserDelegate

    func numberOfPhotos(in photoBrowser: MWPhotoBrowser!) -> UInt {
        return UInt(bangumi?.images.count ?? 0)
    }

    func photoBrowser(_ photoBrowser: MWPhotoBrowser!, photoAt index: UInt) -> MWPhotoProtocol! {
        guard let imageLink = bangumi?.images[Int(index)] else { return nil }
        guard let url = URL(string: imageLink) else { return nil }
        let mwPhoto = MWPhoto(url: url)
        return mwPhoto
    }
}

public extension PKHUD {
    public func setMessage(_ message: String) {
        if let v = contentView as? PKHUDTextView {
            v.titleLabel.text = message
        }
        else {
            contentView = PKHUDTextView(text: message)
        }
    }
}
