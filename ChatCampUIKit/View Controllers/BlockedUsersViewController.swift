//
//  BlockedUsersViewController.swift
//  ChatCampUIKit
//
//  Created by Saurabh Gupta on 04/09/18.
//  Copyright © 2018 chatcamp. All rights reserved.
//

import UIKit
import ChatCamp
import SDWebImage
import MBProgressHUD

open class BlockedUsersViewController: UITableViewController {
    
    var users: [CCPUser] = []
    fileprivate var usersToFetch: Int = 20
    fileprivate var loadingUsers = false
    var usersQuery: CCPUserListQuery!
    lazy var messageLabel: UILabel = {
        let messageLabel = UILabel()
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.textColor = .black
        messageLabel.center = view.center
        messageLabel.text = "No Blocked Users"
        
        return messageLabel
    }()
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Blocked Users"
        
        setupTableView()
        setupRefereshControl()
        
        usersQuery = CCPClient.createBlockedUserListQuery()
        loadUsers(limit: usersToFetch)
    }
    
    fileprivate func setupTableView() {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        tableView.register(UINib(nibName: String(describing: ChatTableViewCell.self), bundle: Bundle(for: ChatTableViewCell.self)), forCellReuseIdentifier: ChatTableViewCell.identifier)
    }
    
    fileprivate func setupRefereshControl() {
        self.refreshControl = UIRefreshControl()
        guard let pullToRefreshControl = self.refreshControl else { return }
        pullToRefreshControl.addTarget(self, action:
            #selector(BlockedUsersViewController.handleRefresh(_:)),
                                       for: UIControl.Event.valueChanged)
        pullToRefreshControl.tintColor = UIColor(red: 48/255, green: 58/255, blue: 165/255, alpha: 1.0)
        tableView.addSubview(pullToRefreshControl)
    }
    
    fileprivate func loadUsers(limit: Int) {
        let progressHud = MBProgressHUD.showAdded(to: self.view, animated: true)
        progressHud.label.text = "Loading..."
        progressHud.contentColor = .black
        loadingUsers = true
        usersQuery.load(limit: limit) { [unowned self] (users, error) in
            progressHud.hide(animated: true)
            if error == nil {
                if users?.count == 0 {
                    self.messageLabel.frame = self.view.bounds
                    self.view.addSubview(self.messageLabel)
                    self.view.bringSubviewToFront(self.messageLabel)
                    self.tableView.tableFooterView = UIView()
                } else {
                    self.messageLabel.removeFromSuperview()
                    guard let users = users else { return }
                    self.users.append(contentsOf: users.filter({ $0.getId() != CCPClient.getCurrentUser().getId() }))
                    
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                        self.loadingUsers = false
                    }
                }
                
                if self.refreshControl?.isRefreshing ?? false {
                    self.refreshControl?.endRefreshing()
                }
            } else {
                DispatchQueue.main.async {
                    self.showAlert(title: "Can't Load Users", message: "Unable to load Users right now. Please try later.", actionText: "Ok")
                    self.loadingUsers = false
                    if self.refreshControl?.isRefreshing ?? false {
                        self.refreshControl?.endRefreshing()
                    }
                }
            }
        }
    }
    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        usersQuery = CCPClient.createBlockedUserListQuery()
        let progressHud = MBProgressHUD.showAdded(to: self.view, animated: true)
        progressHud.label.text = "Loading..."
        progressHud.contentColor = .black
        loadingUsers = true
        usersQuery.load(limit: usersToFetch) { [unowned self] (users, error) in
            progressHud.hide(animated: true)
            if error == nil {
                if users?.count == 0 {
                    self.messageLabel.frame = self.view.bounds
                    self.view.addSubview(self.messageLabel)
                    self.view.bringSubviewToFront(self.messageLabel)
                    self.tableView.tableFooterView = UIView()
                } else {
                    self.users.removeAll()
                    self.messageLabel.removeFromSuperview()
                    guard let users = users else { return }
                    self.users.append(contentsOf: users.filter({ $0.getId() != CCPClient.getCurrentUser().getId() }))
                    
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                        self.loadingUsers = false
                    }
                }
                
                if self.refreshControl?.isRefreshing ?? false {
                    self.refreshControl?.endRefreshing()
                }
            } else {
                DispatchQueue.main.async {
                    self.showAlert(title: "Can't Load Users", message: "Unable to load Users right now. Please try later.", actionText: "Ok")
                    self.loadingUsers = false
                    if self.refreshControl?.isRefreshing ?? false {
                        self.refreshControl?.endRefreshing()
                    }
                }
            }
        }
    }
}

// MARK:- UITableViewDataSource
extension BlockedUsersViewController {
    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ChatTableViewCell.string(), for: indexPath) as! ChatTableViewCell
        cell.nameLabel.centerYAnchor.constraint(equalTo: cell.centerYAnchor).isActive = true
        
        let user = users[indexPath.row]
        cell.nameLabel.text = user.getDisplayName()
        cell.messageLabel.text = ""
        cell.accessoryLabel.text = "Unblock"
        cell.unreadCountLabel.isHidden = true
        if let avatarUrl = user.getAvatarUrl() {
            cell.avatarImageView?.sd_setImage(with: URL(string: avatarUrl), completed: nil)
        } else {
            cell.avatarImageView.setImageForName(string: user.getDisplayName() ?? "?", circular: true, textAttributes: nil)
        }
        
        return cell
    }
}

// MARK:- UITableViewDelegate
extension BlockedUsersViewController {
    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = users[indexPath.row]
        let progressHud = MBProgressHUD.showAdded(to: self.view, animated: true)
        CCPClient.unblockUser(userId: user.getId()) { (participant, error) in
            progressHud.hide(animated: true)
            if error == nil {
                self.users.remove(at: indexPath.row)
                tableView.reloadData()
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK:- ScrollView Delegate Methods
extension BlockedUsersViewController {
    override open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if (tableView.indexPathsForVisibleRows?.contains([0, users.count - 1]) ?? false) && !loadingUsers && users.count >= (usersToFetch - 1) {
            loadUsers(limit: usersToFetch)
        }
    }
}

