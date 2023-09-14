import ChatRepo
import MEGAL10n
import MEGAUIKit
import UIKit

class ContactsGroupsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var newGroupChatLabel: UILabel!
    @IBOutlet weak var separatorView: UIView!

    var searchController = UISearchController()
    var groupChats = [MEGAChatListItem]()
    var searchingGroupChats = [MEGAChatListItem]()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = Strings.Localizable.groups
        navigationItem.backBarButtonItem = BackBarButtonItem(menuTitle: Strings.Localizable.groups)
        newGroupChatLabel.text = Strings.Localizable.newGroupChat
        
        searchController = UISearchController.customSearchController(searchResultsUpdaterDelegate: self, searchBarDelegate: self)
        navigationItem.searchController = searchController
        tableView.tableFooterView = UIView()  // This remove the separator line between empty cells
        
        updateAppearance()
        
        fetchGroupChatsList()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            AppearanceManager.forceSearchBarUpdate(searchController.searchBar, traitCollection: traitCollection)
            
            updateAppearance()
        }
    }
    
    // MARK: - Private
    
    private func updateAppearance() {
        view.backgroundColor = UIColor.mnz_backgroundGrouped(for: traitCollection)
        separatorView.backgroundColor = UIColor.mnz_separator(for: traitCollection)
        tableView.separatorColor = UIColor.mnz_separator(for: traitCollection)
        tableView.reloadData()
    }

    func fetchGroupChatsList() {
        guard let chatListItems = MEGAChatSdk.shared.chatListItems else {
            return
        }
        
        for i in 0..<chatListItems.size {
            guard let chatListItem = chatListItems.chatListItem(at: i) else {
                continue
            }
            if chatListItem.isGroup {
                groupChats.append(chatListItem)
            }
        }
        tableView.reloadData()
    }
    
    func addNewChatToList(chatRoom: MEGAChatRoom) {
        guard let newChatListItem = MEGAChatSdk.shared.chatListItem(forChatId: chatRoom.chatId) else {
            return
        }
        groupChats.append(newChatListItem)
        if isSearching {
            updateSearchResults(for: searchController)
        } else {
            tableView.insertRows(at: [IndexPath(row: groupChats.count - 1, section: 0)], with: .automatic)
        }
    }
    
    func showGroupChatRoom(at indexPath: IndexPath) {
        let chatListItem = searchingGroupChats.isNotEmpty ? searchingGroupChats[indexPath.row] : groupChats[indexPath.row]
        guard let chatRoom = MEGAChatSdk.shared.chatRoom(forChatId: chatListItem.chatId) else {
            return
        }
        let messagesVC = ChatViewController(chatRoom: chatRoom)
        navigationController?.pushViewController(messagesVC, animated: true)
    }
    
    @IBAction func showNewChatGroup() {
        guard let contactsNavigation = UIStoryboard(name: "Contacts", bundle: nil).instantiateViewController(withIdentifier: "ContactsNavigationControllerID") as? MEGANavigationController, let contactsVC = contactsNavigation.viewControllers.first as? ContactsViewController else {
            return
        }
        
        contactsVC.contactsMode = .chatCreateGroup
        contactsVC.createGroupChat = { [weak self] users, groupName, keyRotation, getChatlink, allowNonHostToAddParticipants in
            guard let users = users as? [MEGAUser] else {
                return
            }
            
            if keyRotation {
                MEGAChatSdk.shared.mnz_createChatRoom(
                    usersArray: users,
                    title: groupName,
                    allowNonHostToAddParticipants: allowNonHostToAddParticipants,
                    completion: { chatRoom in
                        DispatchQueue.main.async {
                            self?.addNewChatToList(chatRoom: chatRoom)
                            let messagesVC = ChatViewController(chatRoom: chatRoom)
                            self?.navigationController?.pushViewController(messagesVC, animated: true)
                        }
                    })
            } else {
                MEGAChatSdk.shared.createPublicChat(
                    withPeers: MEGAChatPeerList.mnz_standardPrivilegePeerList(usersArray: users),
                    title: groupName,
                    speakRequest: false,
                    waitingRoom: false,
                    openInvite: allowNonHostToAddParticipants,
                    delegate: ChatRequestDelegate { result in
                        guard case let .success(request) = result,
                              let chatRoom = MEGAChatSdk.shared.chatRoom(forChatId: request.chatHandle) else {
                            return
                        }
                        DispatchQueue.main.async {
                            self?.addNewChatToList(chatRoom: chatRoom)
                        }
                        if getChatlink {
                            MEGAChatSdk.shared.createChatLink(chatRoom.chatId, delegate: ChatRequestDelegate { result in
                                if case .success = result {
                                    let messagesVC = ChatViewController(chatRoom: chatRoom)
                                    messagesVC.publicChatWithLinkCreated = true
                                    messagesVC.publicChatLink = URL(string: request.text)
                                    self?.navigationController?.pushViewController(messagesVC, animated: true)
                                }
                            })
                        } else {
                            DispatchQueue.main.async {
                                let messagesVC = ChatViewController(chatRoom: chatRoom)
                                self?.navigationController?.pushViewController(messagesVC, animated: true)
                            }
                        }
                    })
            }
        }
        
        present(contactsNavigation, animated: true, completion: nil)
    }
}

// MARK: - UITableViewDataSource

extension ContactsGroupsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearching ? searchingGroupChats.count : groupChats.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let chatListItem = searchingGroupChats.isNotEmpty ? searchingGroupChats[indexPath.row] : groupChats[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "groupCell", for: indexPath) as? ContactsGroupTableViewCell else {
            fatalError("Could not dequeue cell with identifier groupCell")
        }
        cell.configure(for: chatListItem)
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension ContactsGroupsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        showGroupChatRoom(at: indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - DZNEmptyDataSetSource

extension ContactsGroupsViewController: DZNEmptyDataSetSource {
    func customView(forEmptyDataSet scrollView: UIScrollView) -> UIView? {
        return EmptyStateView.init(image: imageForEmptyDataSet(), title: titleForEmptyDataSet(), description: nil, buttonTitle: nil)
    }
    
    private func imageForEmptyDataSet() -> UIImage? {
        if self.searchController.isActive && self.searchController.searchBar.text?.isNotEmpty == true {
            return Asset.Images.EmptyStates.searchEmptyState.image
        } else {
            return Asset.Images.EmptyStates.chatEmptyState.image
        }
    }
    
    private func titleForEmptyDataSet() -> String? {
        if self.searchController.isActive && self.searchController.searchBar.text?.isNotEmpty == true {
            return Strings.Localizable.noResults
        } else {
            return Strings.Localizable.noConversations
        }
    }
}

// MARK: - UISearchResultsUpdating

extension ContactsGroupsViewController: UISearchResultsUpdating {
    
    var isSearching: Bool {
        searchController.isActive && !isSearchBarEmpty
    }
    
    var isSearchBarEmpty: Bool {
        searchController.searchBar.text?.isEmpty ?? true
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchString = searchController.searchBar.text else { return }
        if searchController.isActive {
            if searchString == "" {
                searchingGroupChats.removeAll()
            } else {
                searchingGroupChats = groupChats.filter({$0.chatTitle().contains(searchString)})
            }
        }
        tableView.reloadData()
    }
}

// MARK: - UISearchBarDelegate

extension ContactsGroupsViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchingGroupChats.removeAll()
    }
}
