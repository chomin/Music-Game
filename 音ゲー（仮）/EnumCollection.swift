
/// 列挙型の全要素を取得できるようにするプロトコル
public protocol EnumCollection: Hashable {  // 関数内でhashValueを利用する & Arrayの要素に入れるためにHashableを適用?
    static func cases() -> AnySequence<Self>
    static var allValues: [Self] { get }
}

public extension EnumCollection {
    
    public static func cases() -> AnySequence<Self> {
        return AnySequence { () -> AnyIterator<Self> in // AnySequenceを使い、一時的な無名Sequenceを作る。初期化時にmakeIteratorの実装をクロージャで渡すようなイメージ.
            
            var raw = 0
            return AnyIterator {
                let current: Self = withUnsafePointer(to: &raw) { $0.withMemoryRebound(to: self, capacity: 1) { $0.pointee } }  // currentには列挙型の各要素が順番に入る。最後は空白？が入り、guardで返される。
                guard current.hashValue == raw else {
                    return nil
                }
                raw += 1
                return current
            }
        }
    }
    
    public static var allValues: [Self] {
        return Array(self.cases())  // Sequenceから配列を作る。(Array(1...4)で[1,2,3,4]を作るときも同じイニシャライザを使う)
    }
    
    public static var first: Self? { return Self.allValues.first }
}

/*
 public protocol Sequence { // Swift Standard Library内にある。
    public func makeIterator() -> Self.Iterator // IteratorProtocolに準拠するインスタンスを返す関数。（IteratorProtocolの説明は以下。）
 }
 
 makeIterator()を実装することでSequenceを適用できる(デフォルト実装を利用できる場合は自分で実装する必要なし。どっかにprotocol extensionがある？公式によると、デフォルトはReturns an iterator over the elements of this sequence.)。Sequenceを適用すると、「for i in ...」の中に入れられたり、mapやcontainsなどの関数を使えるようになる。
 
 
 public protocol IteratorProtocol {
    public mutating func next() -> Self.Element?
 }
 
 next()を呼ぶたびに「次のElement」を返し、最後の要素の次はnilを返す。返り値は任意の要素型。
 
 参考：https://qiita.com/a-beco/items/2c0432217bbf41ee54e3
 */
