//
//  PickerKeyboard.swift
//  音ゲー（仮）
//
//  Created by Kohei Nakai on 2017/09/21.
//  Copyright © 2017年 NakaiKohei. All rights reserved.
//

import UIKit

class PickerKeyboard: UIControl {
	
	var data: [String] = ["シュガーソングとビターステップ", "ようこそジャパリパークへ", "オラシオン", "This game", "SAKURAスキップ","残酷な天使のテーゼ","にめんせい☆ウラオモテライフ！"] // ピッカーに表示させるデータ

	var textStore: String = "シュガーソングとビターステップ"	//入力文字列を保存するためのプロパティ
	
	// PickerViewで選択されたデータを表示する
	override func draw(_ rect: CGRect) {
		UIColor.black.set()
		UIRectFrame(rect)
		let paragraphStyle = NSMutableParagraphStyle()
		paragraphStyle.alignment = .center
		let attrs: [NSAttributedStringKey: Any] = [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 17), NSAttributedStringKey.paragraphStyle: paragraphStyle]
		textStore.draw(in:rect, withAttributes: attrs)
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		// viewのタッチジェスチャーを取る
		addTarget(self, action: #selector(PickerKeyboard.didTap(sender:)), for: .touchUpInside)
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		// viewのタッチジェスチャーを取る
		addTarget(self, action: #selector(PickerKeyboard.didTap(sender:)), for: .touchUpInside)
	}
	
	// タッチされたらFirst Responderになる
	@objc func didTap(sender: PickerKeyboard) {
		becomeFirstResponder()
	}
	
	 // ボタンを押したらresignしてキーボードを閉じる
	@objc func didTapDone(sender: UIButton) {
		resignFirstResponder()
	}
	
	// First Responderになるためにはこのメソッドは常にtrueを返す必要がある
	override var canBecomeFirstResponder: Bool {
		return true
	}
	
	 // inputViewをオーバーライドさせてシステムキーボードの代わりにPickerViewを表示
	override var inputView: UIView? {
		let pickerView = UIPickerView()
		pickerView.delegate = self
		let row = data.index(of: textStore) ?? -1
		pickerView.selectRow(row, inComponent: 0, animated: false)
		return pickerView
	}
	
	override var inputAccessoryView: UIView? {
		  // キーボードを閉じるための完了ボタン
		let button = UIButton(type: .system)
		button.setTitle("Done", for: .normal)
		button.addTarget(self, action: #selector(PickerKeyboard.didTapDone(sender:)), for: .touchUpInside)
		button.sizeToFit()
		
		// キーボードの上に置くアクセサリービュー
		let view = UIView(frame: CGRect(x: 0, y: 0, width: self.bounds.width, height: 44))
		view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
		view.backgroundColor = .groupTableViewBackground
		
		 // ボタンをアクセサリービュー上に設置
		button.frame.origin.x = 16
		button.center.y = view.center.y
		button.autoresizingMask = [.flexibleRightMargin, .flexibleBottomMargin, .flexibleTopMargin]
		view.addSubview(button)
		
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
	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		return data.count
	}
	
	func numberOfComponents(in pickerView: UIPickerView) -> Int {
		return 1
	}
	
	func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		return data[row]
	}
	
	func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		textStore = data[row]	 // ピッカーから選択されたらその値をtextStoreへ入れる
		setNeedsDisplay()
	}
}
