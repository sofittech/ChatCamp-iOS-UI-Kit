//
//  GroupChannelsViewController.swift
//  ChatCamp Demo
//
//  Created by Tanmay Khandelwal on 13/02/18.
//  Copyright © 2018 iFlyLabs Inc. All rights reserved.
//

import UIKit
import ChatCamp
import SDWebImage

open class GroupChannelsViewController: UITableViewController {
    
    open var channels: [CCPGroupChannel] = []
    fileprivate var loadingChannels = false
    fileprivate var db: SQLiteDatabase!
    var groupChannelsQuery: CCPGroupChannelListQuery!
    lazy var messageLabel: UILabel = {
        let messageLabel = UILabel()
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.textColor = .black
        messageLabel.center = view.center
        messageLabel.text = "No Recent Converstions"
        
        return messageLabel
    }()
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        
        do {
            let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                .appendingPathComponent("ChatDatabase.sqlite")
            db = try! SQLiteDatabase.open(path: fileURL.path)
            print("Successfully opened connection to database.")
            do {
                try db.createTable(table: Channel.self)
            } catch {
                print(db.errorMessage)
            }
        } catch SQLiteError.OpenDatabase(let message) {
            print("Unable to open database. Verify that you created the directory described in the Getting Started section.")
        }
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        groupChannelsQuery = CCPGroupChannel.createGroupChannelListQuery()
        setupNavigationBar()
        loadChannelsFromLocalStorage()
        refreshChannels()
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        CCPClient.addChannelDelegate(channelDelegate: self, identifier: GroupChannelsViewController.string())
        CCPClient.addConnectionDelegate(connectionDelegate: self, identifier: GroupChannelsViewController.string())
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        CCPClient.removeChannelDelegate(identifier: GroupChannelsViewController.string())
        CCPClient.removeConnectionDelegate(identifier: GroupChannelsViewController.string())
    }
}

// MARK:- Private Utility Methods
extension GroupChannelsViewController {    
    @objc fileprivate func addButtonTapped() {
        let createChannelViewController = UIViewController.createChannelViewController()
        if let viewController = createChannelViewController.topViewController as? CreateChannelViewController {
            viewController.channelCreated = { (channel, sender) in
                let chatViewController = ChatViewController(channel: channel, sender: sender)
                self.navigationController?.pushViewController(chatViewController, animated: true)
                self.updateGroupChannel(channel)
            }
        }
        present(createChannelViewController, animated: true, completion: nil)
    }
    
    fileprivate func updateGroupChannel(_ channel: CCPBaseChannel) {
        channels.insert(channel as! CCPGroupChannel, at: 0)
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        do {
            try self.db.updateGroupChannel(channel: channel as! CCPGroupChannel)
        } catch {
            print(self.db.errorMessage)
        }
    }
    
    fileprivate func setupTableView() {
        tableView.register(UINib(nibName: String(describing: ChatTableViewCell.self), bundle: Bundle(for: ChatTableViewCell.self)), forCellReuseIdentifier: ChatTableViewCell.string())
    }
    
    fileprivate func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.addButtonTapped))
        tabBarController?.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.addButtonTapped))
    }
    
    fileprivate func loadChannelsFromLocalStorage() {
        if let loadedChannels = self.db.getGroupChannels() {
            if loadedChannels.count > 0 {
                self.channels = loadedChannels
                self.tableView.reloadData()
            }
        }
    }
    
    fileprivate func refreshChannels() {
        loadingChannels = true
//        let groupChannelsListQuery = CCPGroupChannel.createGroupChannelListQuery()
        groupChannelsQuery.load { (channels, error) in
            if error == nil {
                if channels?.count == 0 {
                    self.messageLabel.frame = self.view.bounds
                    self.view.addSubview(self.messageLabel)
                    self.view.bringSubviewToFront(self.messageLabel)
                    self.tableView.tableFooterView = UIView()
                } else {
                    self.messageLabel.removeFromSuperview()
                    guard let channels = channels else { return }
                    self.channels = channels
                    
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                        self.loadingChannels = false
                    }
                    
                    do {
                        try self.db.insertGroupChannels(channels: channels)
                    } catch {
                        print(self.db.errorMessage)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.showAlert(title: "Can't Load Group Channels", message: "Unable to load Group Channels right now. Please try later.", actionText: "Ok")
                    self.loadingChannels = false
                }
            }
        }
    }
}

// MARK:- UITableViewDataSource
extension GroupChannelsViewController {
    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return channels.count
    }
    
    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ChatTableViewCell.string(), for: indexPath) as! ChatTableViewCell
        
        let channel = channels[indexPath.row]
        
        if channel.getParticipantsCount() == 2 {
            let participants = channel.getParticipants()
            for participant in participants {
                if participant.getId() != CCPClient.getCurrentUser().getId() {
                    cell.nameLabel.text = participant.getDisplayName()
                    if let avatarUrl = participant.getAvatarUrl() {
                        cell.avatarImageView?.sd_setImage(with: URL(string: avatarUrl), completed: nil)
                    } else {
                        cell.avatarImageView.setImageForName(string: participant.getDisplayName() ?? "?", backgroundColor: nil, circular: true, textAttributes: nil)
                    }
                } else {
                    continue
                }
            }
        } else {
            cell.nameLabel.text = channel.getName()
            if let avatarUrl = channel.getAvatarUrl() {
                cell.avatarImageView?.sd_setImage(with: URL(string: avatarUrl), completed: nil)
            } else {
                cell.avatarImageView.setImageForName(string: channel.getName(), circular: true, textAttributes: nil)
            }
        }
        let unreadMessageCount = channel.getUnreadMessageCount()
        if unreadMessageCount > 0 {
            cell.unreadCountLabel.isHidden = false
            if unreadMessageCount < 10 {
                cell.unreadCountLabel.text = String(unreadMessageCount)
            } else {
                cell.unreadCountLabel.text = "9+"
            }
        } else {
            cell.unreadCountLabel.isHidden = true
        }
        if let message = channel.getLastMessage(), let displayName = channel.getLastMessage()?.getUser().getDisplayName() {
            if message.getType() == "text" {
                cell.messageLabel.text =  displayName + ": " + message.getText()
            } else {
                cell.messageLabel.text =  displayName + ": " + message.getType()
            }
        }
        if let lastMessage = channel.getLastMessage() {
            let lastMessageTimeInterval = lastMessage.getInsertedAt()
            cell.lastMessageLabel.text = LastMessage.getDisplayableMessage(timeInterval: Double(lastMessageTimeInterval))
        }
        
        return cell
    }
}

// MARK:- UITableViewDelegate
extension GroupChannelsViewController {
    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let userID = CCPClient.getCurrentUser().getId()
        let username = CCPClient.getCurrentUser().getDisplayName()
        
        let sender = Sender(id: userID, displayName: username!)
        
        let chatViewController = ChatViewController(channel: channels[indexPath.row], sender: sender)
        navigationController?.pushViewController(chatViewController, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK:- CCPChannelDelegate
extension GroupChannelsViewController: CCPChannelDelegate {
    
    public func channelDidReceiveMessage(channel: CCPBaseChannel, message: CCPMessage) {
        if let index = channels.index(where: { (groupChannel) -> Bool in
            groupChannel.getId() == channel.getId()
        }) {
            channels.remove(at: index)
            updateGroupChannel(channel)
        } else {
            updateGroupChannel(channel)
        }
    }
    
    public func channelDidChangeTypingStatus(channel: CCPBaseChannel) { }
    
    public func channelDidUpdateReadStatus(channel: CCPBaseChannel) { }
    
    public func channelDidUpdated(channel: CCPBaseChannel) { }
    
    public func onTotalGroupChannelCount(count: Int, totalCountFilterParams: TotalCountFilterParams) { }
    
    public func onGroupChannelParticipantJoined(groupChannel: CCPGroupChannel, participant: CCPUser) { }
    
    public func onGroupChannelParticipantLeft(groupChannel: CCPGroupChannel, participant: CCPUser) { }
    
    public func onGroupChannelMessageUpdated(groupChannel: CCPGroupChannel, message: CCPMessage) { }
    
    public func onOpenChannelMessageUpdated(openChannel: CCPOpenChannel, message: CCPMessage) { }
    
    public func onGroupChannelParticipantDeclined(groupChannel: CCPGroupChannel, participant: CCPUser) { }
}

// MARK:- CCPConnectionDelegate
extension GroupChannelsViewController: CCPConnectionDelegate {
    public func connectionDidChange(isConnected: Bool) {
        if isConnected {
            refreshChannels()
        }
    }
}

// MARK:- ScrollView Delegate Methods
extension GroupChannelsViewController {
    override open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if (tableView.indexPathsForVisibleRows?.contains([0, channels.count - 1]) ?? false) && !loadingChannels && channels.count >= 20 {
            loadingChannels = true
            groupChannelsQuery.load { (channels, error) in
                if error == nil {
                    guard let channels = channels else { return }
                    self.channels.append(contentsOf: channels)
                    
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                        self.loadingChannels = false
                    }
                } else {
                    DispatchQueue.main.async {
                        self.showAlert(title: "Can't Load Group Channels", message: "Unable to load Group Channels right now. Please try later.", actionText: "Ok")
                        self.loadingChannels = false
                    }
                }
            }
        }
    }
}
