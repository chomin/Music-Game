//
//  PickerKeyboard.swift
//  音ゲー（仮）
//
//  Created by Kohei Nakai on 2017/09/21.
//  Copyright © 2017年 NakaiKohei. All rights reserved.
//

import UIKit

class PickerKeyboard: UIControl {
    
    var musicNameArray: [String] = []       // ピッカーに表示させるデータ(DimentionsファイルのMusicNameから自動生成)
    var textStore: String                   // 入力文字列を保存するためのプロパティ(MusicName.first!.rawValueとするとfirstがnilになる)
    var isFirstMovedFromTitleLabel = false  // 一番最初に選択されたラベルを強調するためのもの
    var selectedRow: Int
    var headers: [Header] = []
    let pickerView = UIPickerView()
    
    var doneButton  : UIButton!
    var randomButton: UIButton!
    var buttons: [UIButton] {
        var buttons: [UIButton] = []
        buttons.append(doneButton)
        buttons.append(randomButton)
        return buttons
    }
    
    // PickerViewで'選択されたデータ'を表示する
    override func draw(_ rect: CGRect) {
        UIColor.black.set()
        UIRectFrame(rect)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attrs: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17), NSAttributedString.Key.paragraphStyle: paragraphStyle]
        textStore.draw(in:rect, withAttributes: attrs)
    }
    
    init(frame: CGRect, firstText: String, headers: [Header]) {
        
        textStore = firstText
        
        // ピッカーに初期値をセット(将来的にはファイル探索から)
        for header in headers {
            if header.videoID.isEmpty && header.videoID2.isEmpty {
                musicNameArray.append(header.title)
            } else {
                musicNameArray.append("★" + header.title)
            }
            
        }
        self.headers = headers
        
        if firstText.first == "★" {
            var searchText = firstText
            searchText.removeFirst()
            selectedRow = headers.map { $0.title } .index(of: searchText)!
        } else {
            selectedRow = headers.map { $0.title } .index(of: firstText)!
        }
        
        super.init(frame: frame)
        
        // viewのタッチジェスチャーを取る
        addTarget(self, action: #selector(PickerKeyboard.didTap(sender: )), for: .touchUpInside)
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        textStore = ""
        selectedRow = 0
        super.init(coder: aDecoder)
        // viewのタッチジェスチャーを取る
        addTarget(self, action: #selector(PickerKeyboard.didTap(sender: )), for: .touchUpInside)
    }
    
    // タッチされたらFirst Responderになる
    @objc func didTap(sender: PickerKeyboard) {
        becomeFirstResponder()
    }
    
    // ボタンを押したらresignしてキーボードを閉じる
    @objc func didTapDone(sender: UIButton) {
        resignFirstResponder()
    }
    
    @objc func didTapRandom(sender: UIButton) {
        pickerView.selectRow(Int.random(in: 0..<musicNameArray.count), inComponent: 0, animated: true)
    }
    
    @objc func onButton(sender: UIButton) {
        for button in buttons {
            guard sender != button else { continue }
            button.isEnabled = false
        }
    }
    
    @objc func touchUpOutsideButton(sender: UIButton) {
        for button in buttons {
            button.isEnabled = true
        }
    }
    
    // First Responderになるためにはこのメソッドは常にtrueを返す必要がある
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    // inputViewをオーバーライドさせてシステムキーボードの代わりにPickerViewを表示(初期配置)
    override var inputView: UIView? {
        pickerView.delegate = self
        let row = musicNameArray.index(of: textStore) ?? -1
        pickerView.selectRow(row, inComponent: 0, animated: true)
        pickerView.showsSelectionIndicator = true
        
        return pickerView
    }
    
    override var inputAccessoryView: UIView? {
        // キーボードの上に置くアクセサリービュー
        let view = UIView(frame: CGRect(x: 0, y: 0, width: self.bounds.width, height: 44))
        view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        view.backgroundColor = .groupTableViewBackground
        
        let doneButtonX: CGFloat = 16
        // キーボードを閉じるための完了ボタン
        doneButton = { () -> UIButton in
            let button = UIButton(type: .system)
            button.setTitle("Done", for: .normal)
            button.addTarget(self, action: #selector(PickerKeyboard.didTapDone(sender: )), for: .touchUpInside)
            button.addTarget(self, action: #selector(PickerKeyboard.onButton(sender: )), for: .touchDown)
            button.addTarget(self, action: #selector(PickerKeyboard.touchUpOutsideButton(sender: )), for: .touchUpOutside)
            button.sizeToFit()
            // ボタンをアクセサリービュー上に設置
            button.frame.origin.x = doneButtonX
            button.center.y = view.center.y
            button.autoresizingMask = [.flexibleRightMargin, .flexibleBottomMargin, .flexibleTopMargin]
            view.addSubview(button)
            
            return button
        }()
        
        // おまかせ選曲ボタン
        randomButton = { () -> UIButton in
            let button = UIButton(type: .system)
            button.setTitle("Random", for: .normal)
            button.addTarget(self, action: #selector(PickerKeyboard.didTapRandom(sender: )), for: .touchUpInside)
            button.addTarget(self, action: #selector(PickerKeyboard.onButton(sender: )), for: .touchDown)
            button.addTarget(self, action: #selector(PickerKeyboard.touchUpOutsideButton(sender: )), for: .touchUpOutside)
            button.sizeToFit()
            // ボタンをアクセサリービュー上に設置
            button.frame.origin.x = doneButtonX + button.frame.width*1.2
            button.center.y = view.center.y
            button.autoresizingMask = [.flexibleRightMargin, .flexibleBottomMargin, .flexibleTopMargin]
            view.addSubview(button)
            
            return button
        }()
        
        
        return view
    }
}

// UIKeyInputを適用させる
extension PickerKeyboard: UIKeyInput {
    // 以下の3つのメソッドはUIkeyInputで必ず実装しなければならないメソッド
    // 主にキーボード入力が行われたときにそれぞれのメソッドが呼び出される
    
    // It is not necessary to store text in this situation.
    // 入力されたテキストが存在するか
    var hasText: Bool {
        return !textStore.isEmpty
    }
    
    // テキストが入力されたときに呼ばれる
    func insertText(_ text: String) {
        textStore += text
        setNeedsDisplay()
    }
    
    // バックスペースが入力されたときに呼ばれる
    func deleteBackward() {
        textStore.remove(at: textStore.index(before: textStore.endIndex))
        setNeedsDisplay()
    }
}

// UIPickerViewDelegateとDataSourceを実装して、dataの内容をピッカーへ表示させる
extension PickerKeyboard: UIPickerViewDelegate, UIPickerViewDataSource {
    
    /*---------- UIPickerViewDataSourceの関数 -----------*/
    /// 列の数
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    /// 行の数
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return musicNameArray.count
    }
    
    /*----------  UIPickerViewDelegateの関数 -----------*/
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return pickerView.frame.height/4
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return musicNameArray[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        isFirstMovedFromTitleLabel = true
        
        textStore = musicNameArray[row]       // ピッカーから選択されたらその値をtextStoreへ入れる
        selectedRow = row
        
        for dataIndex in 0 ... musicNameArray.count-1 {
            if let label = pickerView.view(forRow: dataIndex, forComponent: component) as? UILabel {
                
                if dataIndex == row                          { setSelectedLabelColor    (label: label) }
                else if headers[dataIndex].group == "BDGP"   { setBackLabelPinkColor    (label: label) }
                else if headers[dataIndex].group == "MLTD"   { setBackLabelRedColor     (label: label) }
                else                                         { setBackLabelNormalColor  (label: label) }
            }
        }
        setNeedsDisplay()
    }
    
    /// 自分でカスタマイズしたビューをpickerに表示する.しょっちゅう呼び出されるが、対象のビューが曖昧なので全体のupdateの代わりとする.
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        
        if view != nil {    // ここには入らない
            
            return view!
        } else {
            
            let fontSize: CGFloat = pickerView.frame.height/8   // この値は開いたり閉じたりするときに急激に変化する
            
            let label = UILabel()   // 前のラベルは(こちらで保持していても)逐一解放される？ので新たにインスタンス化する必要あり
            label.text = self.musicNameArray[row]
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: fontSize)
            label.frame = CGRect(x: label.frame.minX, y: label.frame.minY, width: label.frame.width, height: pickerView.frame.height/4)
            
            
            if headers[row].group == "BDGP"        { setBackLabelPinkColor    (label: label) }
            else if headers[row].group == "MLTD"   { setBackLabelRedColor     (label: label) }
            else                                   { setBackLabelNormalColor  (label: label) }
//            if row > 7 {
//                label.textColor = UIColor.red
//            }
            
            if row == 0 && !isFirstMovedFromTitleLabel {
                setSelectedLabelColor(label: label)
            }
            
            return label
        }
    }
    
    func setSelectedLabelColor(label: UILabel) {
        label.textColor = UIColor.darkText
        label.backgroundColor = UIColor.lightGray
    }
    func setBackLabelNormalColor(label: UILabel) {
        label.textColor = UIColor.black
        label.backgroundColor = UIColor.clear
    }
    func setBackLabelRedColor(label: UILabel) {
        label.textColor = UIColor.red
        label.backgroundColor = UIColor.clear
    }
    func setBackLabelPinkColor(label: UILabel) {
        label.textColor = UIColor.init(red: 1.0, green: 0.25, blue: 1.0, alpha: 1.0)
        label.backgroundColor = UIColor.clear
    }
}
