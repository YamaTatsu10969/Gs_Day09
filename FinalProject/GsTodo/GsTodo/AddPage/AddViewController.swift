//
//  AddViewController.swift
//  GsTodo
//
//  Created by yamamototatsuya on 2020/01/15.
//  Copyright © 2020 yamamototatsuya. All rights reserved.
//

import UIKit
import PKHUD
import FirebaseFirestore
import FirebaseUI

class AddViewController: UIViewController {
    
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var memoTextView: UITextView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var categoryTextField: UITextField!

    // 判定に使用するプロパティ
    var selectIndex: Int?
    var isSetImage = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMemoTextView()
        setupNavigationBar()


        
        // Editかどうかの判定
        if let index = selectIndex {
            title = "編集"
            let selectTask = TaskCollection.shared.getTask(at: index)
            titleTextField.text = selectTask.title
            memoTextView.text = selectTask.memo
            categoryTextField.text = selectTask.category.map { $0.rawValue }
            if let imageName = selectTask.imageName,
                let ref = TaskCollection.shared.getImageRef(imageName: imageName) {
                imageView.sd_setImage(with: ref)
            }
            #warning("7. デフォルトカテゴリ追加")
        }else {
            categoryTextField.text = Task.Category.private.rawValue
        }
    }
    
    // MARK: Setup
    fileprivate func setupMemoTextView() {
        memoTextView.layer.borderWidth = 1
        memoTextView.layer.borderColor = UIColor.lightGray.cgColor
        memoTextView.layer.cornerRadius = 3
    }
    
    fileprivate func setupNavigationBar() {
        title = "Add"
        let rightButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(tapSaveButton))
        navigationItem.rightBarButtonItem = rightButtonItem
    }

    // MARK: Action Method
    @objc func tapSaveButton() {
        print("Saveボタンを押したよ！")
        guard let title = titleTextField.text else {return}
        if title.isEmpty {
            print(title, "👿titleが空っぽだぞ〜")
            HUD.flash(.labeledError(title: nil, subtitle: "👿 タイトルが入力されていません！！！"), delay: 1)
            return // return を実行すると、このメソッドの処理がここで終了する。
        }

        var tmpTask = TaskCollection.shared.createTask()
        if let index = selectIndex {
            tmpTask = TaskCollection.shared.getTask(at: index)
        }
        tmpTask.title = title
        tmpTask.memo = memoTextView.text
        #warning("9. category の追加")
        tmpTask.category = categoryTextField.text.map { (Task.Category(rawValue: $0) ?? .work) }
        if isSetImage {
            print("🌞1. TaskCollection.shared.saveImage")
            TaskCollection.shared.saveImage(image: imageView.image) { (imageName) in
                print("🌞9.  saveImage の callback 呼び出した時に、ここが実行される")
                guard let imageName = imageName else {
                    HUD.flash(.labeledError(title: nil, subtitle: "👿 保存に失敗しました"), delay: 1)
                    return
                }
                tmpTask.imageName = imageName
                self.saveTask(tmpTask)
                print("🌞10. ")
            }
        } else {
            saveTask(tmpTask)
        }
    }

    @IBAction func tapImageView(_ sender: Any) {
        print("🌞 imageView をタップしたよ")
        // アクションシートを表示する
        let alertSheet = UIAlertController(title: nil, message: "選択してください", preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: "カメラで撮影", style: .default) { action in
            print("カメラが選択されました")
            self.presentPicker(sourceType: .camera)
        }
        let albumAction = UIAlertAction(title: "アルバムから選択", style: .default) { action in
            print("アルバムが選択されました")
            self.presentPicker(sourceType: .photoLibrary)
        }
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel) { action in
            print("キャンセルが選択されました")
        }
        alertSheet.addAction(cameraAction)
        alertSheet.addAction(albumAction)
        alertSheet.addAction(cancelAction)

        present(alertSheet, animated: true)
    }

    // MARK: Private Method
    private func saveTask(_ task: Task) {
        // ここで Edit か Add　かを判定している
        if let index = selectIndex {
            task.updatedAt = Timestamp()
            TaskCollection.shared.editTask(task: task, index: index)
        } else {
            TaskCollection.shared.addTask(task)
        }
        HUD.flash(.success, delay: 0.3)
        // 前の画面に戻る
        navigationController?.popViewController(animated: true)
    }

}

extension AddViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    func presentPicker(sourceType: UIImagePickerController.SourceType) {
        print("撮影画面かアルバム画面を表示するよ！")
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            let picker = UIImagePickerController()
            picker.sourceType = sourceType
            picker.delegate = self
            present(picker, animated: true)
        } else {
            print("SourceType が見つかりませんでした。。。")
        }
    }

    // 撮影もしくは画像を選択したら呼ばれる
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        print("撮影もしくは画像を選択したよ！")

        if let pickedImage = info[.originalImage] as? UIImage {
            imageView.contentMode = .scaleAspectFit
            imageView.image = pickedImage.resize(toWidth: 300)
            isSetImage = true
        }
        // 表示した画面を閉じる処理
        picker.dismiss(animated: true, completion: nil)
    }
}
