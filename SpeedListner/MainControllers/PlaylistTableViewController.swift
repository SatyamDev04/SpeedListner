//
//  PlaylistTableViewController.swift
//  SpeedListner
//
//  Created by YATIN  KALRA on 17/09/24.
//


import UIKit

protocol PlaylistSelectionDelegate: AnyObject {
    func didSelectPlaylist(_ playlist: Playlist,from item:LibraryItem?)
    func didSelectPlaylist(_ playlist: Playlist,from items:[LibraryItem]?)
}


class PlaylistTableViewController: UITableViewController {

    weak var delegate: PlaylistSelectionDelegate?

    var playlists: [Playlist] = []
    var item: LibraryItem?
    var items: [LibraryItem] = []
    var allowMoveToParent = false
    var allowMoveToRoot = false
    var parentPlaylist: Playlist?
    
    
    private var flattenedPlaylists: [PlaylistDisplayItem] = []

    private var sectionedPlaylists: [(parent: Playlist, children: [Playlist])] = []

    override func viewDidLoad() {
        super.viewDidLoad()
      tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PlaylistCell")
        navigationController?.navigationBar.backgroundColor = #colorLiteral(red: 0.3098039216, green: 0, blue: 0.3921568627, alpha: 1)

        buildHierarchy()
      
    }

    private func buildHierarchy() {
        print("[DEBUG] Building nested playlist display list...")
        flattenedPlaylists = []

        // Inject special destinations FIRST
        if allowMoveToParent, let parent = parentPlaylist {
            let item = PlaylistDisplayItem(
                playlist: parent,
                indentLevel: 0,
                isExpanded: false,
                hasChildren: false
            )
            flattenedPlaylists.append(item)
        }

        if allowMoveToRoot {
            let dummyContext = NewDataMannagerClass.persistentContainer.viewContext
            let rootPlaceholder = Playlist(context: dummyContext)
            rootPlaceholder.title = "__LIBRARY_ROOT__"

            let item = PlaylistDisplayItem(
                playlist: rootPlaceholder,
                indentLevel: 0,
                isExpanded: false,
                hasChildren: false
            )
            flattenedPlaylists.append(item)
        }

        for parent in playlists {
            flatten(playlist: parent, indentLevel: 0)
        }
    }


    private func flatten(playlist: Playlist, indentLevel: Int) {
        let children = (playlist.children?.allObjects as? [Playlist]) ?? []
        let hasChildren = !children.isEmpty

        let displayItem = PlaylistDisplayItem(
            playlist: playlist,
            indentLevel: indentLevel,
            isExpanded: false,
            hasChildren: hasChildren
        )

        flattenedPlaylists.append(displayItem)
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return flattenedPlaylists.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = flattenedPlaylists[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlaylistCell", for: indexPath)
        
        let prefix = item.hasChildren ? (item.isExpanded ? "▾" : "▸") : "•"
        let indent = String(repeating: "    ", count: item.indentLevel)
        
        if item.playlist.title == "__LIBRARY_ROOT__" {
            cell.textLabel?.text = "⬆︎ Move to Library"
        } else if item.playlist == parentPlaylist {
            cell.textLabel?.text = "⬆︎ Move to Parent Folder"
        } else {
            cell.textLabel?.text = "\(indent)\(prefix) \(item.playlist.title ?? "Untitled")"
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = flattenedPlaylists[indexPath.row]

        if item.hasChildren {
            toggleExpansion(at: indexPath.row)
        } else {
            print("[DEBUG] Selected leaf playlist: \(item.playlist.title ?? "Untitled")")
            if !items.isEmpty {
                delegate?.didSelectPlaylist(item.playlist, from: self.items)
            } else {
                delegate?.didSelectPlaylist(item.playlist, from: self.item)
            }
            dismiss(animated: true, completion: nil)
        }
    }
    
    
    
    private func toggleExpansion(at index: Int) {
        var item = flattenedPlaylists[index]
        guard item.hasChildren else { return }

        item.isExpanded.toggle()
        flattenedPlaylists[index] = item

        let playlist = item.playlist
        let children = (playlist.children?.allObjects as? [Playlist]) ?? []

        if item.isExpanded {
            let childItems = children.map {
                PlaylistDisplayItem(
                    playlist: $0,
                    indentLevel: item.indentLevel + 1,
                    isExpanded: false,
                    hasChildren: ($0.children?.count ?? 0) > 0
                )
            }
            flattenedPlaylists.insert(contentsOf: childItems, at: index + 1)
        } else {
         //   removeDescendants(of: playlist, startingAt: index + 1)
            if !items.isEmpty {
                delegate?.didSelectPlaylist(item.playlist, from: self.items)
            } else {
                delegate?.didSelectPlaylist(item.playlist, from: self.item)
                dismiss(animated: true, completion: nil)
            }
        }

        tableView.reloadData()
    }

    private func removeDescendants(of parent: Playlist, startingAt index: Int) {
        var removeCount = 0
        for i in index..<flattenedPlaylists.count {
            let item = flattenedPlaylists[i]
            if isDescendant(of: parent, item: item) {
                removeCount += 1
            } else {
                break
            }
        }

        flattenedPlaylists.removeSubrange(index..<(index + removeCount))
    }

    private func isDescendant(of parent: Playlist, item: PlaylistDisplayItem) -> Bool {
        var current = item.playlist.parent
        while let c = current {
            if c == parent {
                return true
            }
            current = c.parent
        }
        return false
    }
}
//class PlaylistTableViewController: UITableViewController {
//
//   
//    weak var delegate: PlaylistSelectionDelegate?
//    var playlists: [Playlist] = []
//    var item:LibraryItem?
//    var items:[LibraryItem] = []
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PlaylistCell")
//        self.navigationController?.navigationBar.backgroundColor = #colorLiteral(red: 0.3098039216, green: 0, blue: 0.3921568627, alpha: 1)
//    }
//    
//    // MARK: - Table view data source
//    
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return playlists.count
//    }
//    
//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "PlaylistCell", for: indexPath)
//        let playlist = playlists[indexPath.row]
//        cell.textLabel?.text = playlist.title
//        return cell
//    }
//    
//    // MARK: - Table view delegate
//    
//    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let selectedPlaylist = playlists[indexPath.row]
//        if !items.isEmpty {
//            delegate?.didSelectPlaylist(selectedPlaylist, from: self.items)
//        }else{
//            delegate?.didSelectPlaylist(selectedPlaylist, from: self.item)
//        }
//        dismiss(animated: true, completion: nil)
//    }
//}

struct PlaylistDisplayItem {
    let playlist: Playlist
    let indentLevel: Int
    var isExpanded: Bool
    var hasChildren: Bool
}
