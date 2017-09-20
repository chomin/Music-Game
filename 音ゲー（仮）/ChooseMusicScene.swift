//
//  ChooseSoundScene.swift
//  音ゲー（仮）
//
//  Created by Kohei Nakai on 2017/09/05.
//  Copyright © 2017年 NakaiKohei. All rights reserved.
//



import SpriteKit
import GameplayKit

class ChooseMusicScene: SKScene {
//	 var textStore: String = ""	//入力された文字列
//
//
//	required init?(coder aDecoder: NSCoder) {
//		super.init(coder: aDecoder)
//
//		// viewのタッチジェスチャーを取る
//		addTarget(self, action: #selector(ChooseMusicScene.didTap(_:)), forControlEvents: .TouchDown)
//	}
//
//	// タッチされたらFirst Responderになる
//	func didTap(sender: ChooseMusicScene) {
//		becomeFirstResponder()
//	}
//
//	// First Responderになるためにはこのメソッドは常にtrueを返す必要がある
//	override func canBecomeFirstResponder() -> Bool {
//		return true
//	}
//
//	var data: [String] = ["月曜日", "火曜日", "水曜日", "木曜日", "金曜日", "土曜日", "日曜日"]
//
//	// inputViewをオーバーライドさせてシステムキーボードの代わりにPickerViewを表示
//	override var inputView: UIView? {
//		let pickerView = UIPickerView()
//		pickerView.delegate = self
//		let row = data.indexOf(textStore) ?? -1
//		pickerView.selectRow(row, inComponent: 0, animated: false)
//		return pickerView
//	}
//
//
//	//出し入れ
//	override var inputAccessoryView: UIView? {
//		// キーボードを閉じるための完了ボタン
//		let button = UIButton(type: .System)
//		button.setTitle("Done", forState: .Normal)
//		button.addTarget(self, action: #selector(PickerKeyboard.didTapDone(_:)), forControlEvents: .TouchDown)
//		button.sizeToFit()
//
//		// キーボードの上に置くアクセサリービュー
//		let view = UIView(frame: CGRect(x: 0, y: 0, width: self.bounds.width, height: 44))
//		view.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
//		view.backgroundColor = .groupTableViewBackgroundColor()
//
//		// ボタンをアクセサリービュー上に設置
//		button.frame.origin.x = 16
//		button.center.y = view.center.y
//		button.autoresizingMask = [.FlexibleRightMargin, .FlexibleBottomMargin, .FlexibleTopMargin]
//		view.addSubview(button)
//
//		return view
//	}
//
//	// ボタンを押したらresignしてキーボードを閉じる
//	func didTapDone(sender: UIButton) {
//		resignFirstResponder()
//	}
//
//	// PickerViewで選択されたデータを表示する
//	override func drawRect(rect: CGRect) {
//		UIColor.blackColor().set()
//		UIRectFrame(rect)
//		let paragraphStyle = NSMutableParagraphStyle()
//		paragraphStyle.alignment = .Center
//		let attrs: [String: AnyObject] = [NSFontAttributeName: UIFont.systemFontOfSize(17), NSParagraphStyleAttributeName: paragraphStyle]
//		NSString(string: textStore).drawInRect(rect, withAttributes: attrs)
//	}
//
//	override func didMove(to view: SKView) {
//
//
//	}
//
//
//	override func update(_ currentTime: TimeInterval) {
//		// Called before each frame is rendered
//	}
//}
//
//// UIKeyInputを適用させる
//extension ChooseMusicScene: UIKeyInput {
//
//	// 以下の3つのメソッドはUIkeyInputで必ず実装しなければならないメソッド
//	// 主にキーボード入力が行われたときにそれぞれのメソッドが呼び出される
//
//	// 入力されたテキストが存在するか
//	func hasText() -> Bool {
//		return !textStore.isEmpty
//	}
//
//	// テキストが入力されたときに呼ばれる
//	func insertText(text: String) {
//		textStore += text
//		setNeedsDisplay()
//	}
//
//	// バックスペースが入力されたときに呼ばれる
//	func deleteBackward() {
//		textStore.removeAtIndex(textStore.characters.endIndex.predecessor())
//		setNeedsDisplay()
//	}
//}
//
//// UIPickerViewDelegateとDataSourceを実装して、dataの内容をピッカーへ表示させる
//extension ChooseMusicScene: UIPickerViewDelegate, UIPickerViewDataSource {
//	func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
//		return data.count
//	}
//
//	func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
//		return 1
//	}
//
//	func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
//		return data[row]
//	}
//
//	func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
//		// ピッカーから選択されたらその値をtextStoreへ入れる
//		textStore = data[row]
//		setNeedsDisplay()
//	}
}

