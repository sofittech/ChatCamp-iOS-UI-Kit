//
//  UsersViewController.swift
//  ChatCamp Demo
//
//  Created by Saurabh Gupta on 21/05/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import UIKit
import ChatCamp
import SDWebImage
import MBProgressHUD

open class UsersViewController: UITableViewController {

//    @IBOutlet weak var tableView: UITableView! {
//        didSet {
//            tableView.delegate = self
//            tableView.dataSource = self
//            tableView.rowHeight = 70
//            tableView.estimatedRowHeight = 70
//            tableView.register(UINib(nibName: String(describing: UserTableViewCell.self), bundle: Bundle(for: UserTableViewCell.self)), forCellReuseIdentifier: UserTableViewCell.string())
//        }
//    }
    
    open var users: [CCPUser] = []
    open var filteredUsers: [CCPUser] = []
    fileprivate var usersToFetch: Int = 20
    fileprivate var loadingUsers = false
    open var usersQuery: CCPUserListQuery!
    let searchController = UISearchController(searchResultsController: nil)
    
    lazy var messageLabel: UILabel = {
        let messageLabel = UILabel()
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.textColor = .black
        messageLabel.center = view.center
        messageLabel.text = "No Users"
        
        return messageLabel
    }()
    
//    lazy var refreshControl: UIRefreshControl = {
//        let refreshControl = UIRefreshControl()
//        refreshControl.addTarget(self, action:
//            #selector(UsersViewController.handleRefresh(_:)),
//                                 for: UIControl.Event.valueChanged)
//        refreshControl.tintColor = UIColor(red: 48/255, green: 58/255, blue: 165/255, alpha: 1.0)
//
//        return refreshControl
//    }()
    
    public init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()

        setupTableView()
        setupRefereshControl()
        
        if #available(iOS 11.0, *) {
            navigationItem.hidesSearchBarWhenScrolling = false
        } else {
            // Do nothing
        }
        searchController.searchResultsUpdater = self
        searchController.searchBar.placeholder = "Search Users"
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        definesPresentationContext = true
        
        tableView.tableHeaderView = searchController.searchBar
        usersQuery = CCPClient.createUserListQuery()
        loadUsers(limit: usersToFetch)
    }
    
    fileprivate func setupTableView() {
//        tableView.delegate = self
//        tableView.dataSource = self
        tableView.rowHeight = 70
        tableView.estimatedRowHeight = 70
        tableView.register(UINib(nibName: String(describing: UserTableViewCell.self), bundle: Bundle(for: UserTableViewCell.self)), forCellReuseIdentifier: UserTableViewCell.string())
    }
    
    fileprivate func setupRefereshControl() {
        self.refreshControl = UIRefreshControl()
        guard let pullToRefreshControl = self.refreshControl else { return }
        pullToRefreshControl.addTarget(self, action:
        #selector(UsersViewController.handleRefresh(_:)),
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
                if users?.count ?? 0 <= 1 {
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
        refreshUsers(searchText: nil)
    }
    
    fileprivate func refreshUsers(searchText: String?) {
        usersQuery = CCPClient.createUserListQuery()
        loadingUsers = true
        if let text = searchText {
            usersQuery.setDisplayNameSearch(text)
        }
        usersQuery.load(limit: usersToFetch) { [unowned self] (users, error) in
            if error == nil {
                if users?.count ?? 0 == 0 {
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
    
    func searchBarIsEmpty() -> Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }
    
    func filterContentForSearchText(_ searchText: String) {
        if isFiltering() {
            refreshUsers(searchText: searchText)
        } else if searchController.isActive && searchBarIsEmpty() {
            refreshUsers(searchText: nil)
        } else if !searchController.isActive && searchBarIsEmpty() {
            refreshUsers(searchText: nil)
        }
    }
}

// MARK:- UITableViewDataSource
extension UsersViewController {
    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UserTableViewCell.string(), for: indexPath) as! UserTableViewCell

        let user = users[indexPath.row]
        cell.displayNameLabel.text = user.getDisplayName()
        if let avatarUrl = user.getAvatarUrl() {
            cell.avatarImageView?.sd_setImage(with: URL(string: avatarUrl), completed: nil)
        } else {
            cell.avatarImageView.setImageForName(string: user.getDisplayName() ?? "?", circular: true, textAttributes: nil)
        }
        if user.getIsOnline() ?? false {
            cell.onlineStatusImageView.image = UIImage(named: "online", in: Bundle(for: Message.self), compatibleWith: nil)
        } else {
            cell.onlineStatusImageView.image = UIImage(named: "offline", in: Bundle(for: Message.self), compatibleWith: nil)
        }
        
        return cell
    }
}

// MARK:- UITableViewDelegate
extension UsersViewController {
    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = users[indexPath.row]
        let userID = CCPClient.getCurrentUser().getId()
        let username = CCPClient.getCurrentUser().getDisplayName()
        
        let sender = Sender(id: userID, displayName: username!)
        
        CCPGroupChannel.create(name: user.getDisplayName() ?? "", userIds: [userID, user.getId()], isDistinct: true) { groupChannel, error in
            if error == nil {
                let chatViewController = ChatViewController(channel: groupChannel!, sender: sender)
                self.navigationController?.pushViewController(chatViewController, animated: true)
            } else {
                self.showAlert(title: "Error!", message: "Some error occured, please try again.", actionText: "OK")
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK:- ScrollView Delegate Methods
extension UsersViewController {
    override open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if (tableView.indexPathsForVisibleRows?.contains([0, users.count - 1]) ?? false) && !loadingUsers && users.count >= 19 {
            loadUsers(limit: usersToFetch)
        }
    }
}

extension UsersViewController: UISearchResultsUpdating {
    public func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
}
