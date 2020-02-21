//
//  TaskListViewController.swift
//  GsTodo
//
//  Created by yamamototatsuya on 2020/01/15.
//  Copyright © 2020 yamamototatsuya. All rights reserved.
//

import UIKit
import FirebaseAuth

class TaskListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // この ViewController で delegate のメソッドを使うために記述している。
        tableView.delegate = self
        // この ViewController で datasouce のメソッドを使うために記述している。
        tableView.dataSource = self
        // nib と xib はほぼ一緒
        let nib = UINib(nibName: "CustomCell", bundle: nil)
        // tableView に使う xib ファイルを登録している。
        tableView.register( nib, forCellReuseIdentifier: "CustomCell")
        
        // デリゲートのメソッドを使うために記述している。
        // delegete に自分を入れて、TaskCollection で行われた変更を知ることができるようにしている。
        TaskCollection.shared.delegate = self
        
        setupNavigationBar()
        // Do any additional setup after loading the view.
    }
    
    fileprivate func setupNavigationBar() {
        let rightButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(showAddScreen))
        #warning("4. ソートする用のボタンを作成")
        let sortButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(tapSortButton))
        navigationItem.rightBarButtonItems = [rightButtonItem, sortButtonItem]
        
        let leftButtonItem = UIBarButtonItem(title: "logout", style: .plain, target: self, action: #selector(logout))
        navigationItem.leftBarButtonItem = leftButtonItem
    }
    
    @objc func showAddScreen() {
        let vc = AddViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func logout() {
        do {
            try Auth.auth().signOut()
            // 強制的に現在の表示している vc を変更する
            let vc = LoginViewController()
            let sceneDelegate = view.window?.windowScene?.delegate as! SceneDelegate
            sceneDelegate.window?.rootViewController = vc
        } catch {
            print("error:",error.localizedDescription)
        }
        // [swift - UIApplication.shared.delegate equivalent for SceneDelegate xcode11? - Stack Overflow](https://stackoverflow.com/questions/56588843/uiapplication-shared-delegate-equivalent-for-scenedelegate-xcode11)
        // [iOS13のSceneDelegate周りのアプリの起動シーケンス - Qiita](https://qiita.com/omochimetaru/items/31df103ef98a9d84ae6b)
    }
    
    // MARK: UITableView
    
    /// 1つの Section の中の Row　の数を定義する(セルの数を定義)
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return TaskCollection.shared.taskCount()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 登録したセルを使う。 as! CustomCell としないと、UITableViewCell のままでしか使えない。
        let cell = tableView.dequeueReusableCell(withIdentifier: "CustomCell", for: indexPath) as! CustomCell
        cell.titleLabel?.text = TaskCollection.shared.getTask(at: indexPath.row).title
        return cell
    }
    
    // セルをタップした時の処理
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        #warning("タップした後に色がつくのを消す処理を追加")
        tableView.deselectRow(at: indexPath, animated: true)
        
        let vc = AddViewController()
        vc.selectIndex = indexPath.row
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // スワイプした時の処理
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        TaskCollection.shared.removeTask(index: indexPath.row)
    }

    #warning("5. ソートボタンのメソッドを作成")
    @objc private func tapSortButton(_ sender: Any) {
        // アクションシートを表示する
        let alertSheet = UIAlertController(title: nil, message: "選択してください", preferredStyle: .actionSheet)
        let englishAction = UIAlertAction(title: "private", style: .default) { action in
            print("englishが選択されました")
            TaskCollection.shared.loadWithQuery(queryValue: Task.Category.private.rawValue)

        }
        let workAction = UIAlertAction(title: "work", style: .default) { action in
            print("workが選択されました")
                        TaskCollection.shared.loadWithQuery(queryValue: Task.Category.work.rawValue)
        }
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel)
        alertSheet.addAction(englishAction)
        alertSheet.addAction(workAction)
        alertSheet.addAction(cancelAction)

        present(alertSheet, animated: true)
    }
    
}

// extension で分けた方が見やすくなる
extension TaskListViewController: TaskCollectionDelegate {
    // デリゲートのメソッド
    func saved() {
        // tableView をリロードして、画面を更新する。
        tableView.reloadData()
    }
    
    func loaded() {
        tableView.reloadData()
    }
}
