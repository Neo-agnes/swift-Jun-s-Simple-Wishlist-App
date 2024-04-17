import Foundation

// URLSession을 통해서 가져올 상품의 Decodable Model
struct RemoteProduct: Decodable {
    let id: Int // 정보
    let title: String // 제목
    let description: String // 설명
    let price: Double // 가격
    let thumbnail: URL // 연결정보
}
// 위에서 지정된 부분들은 위시리스트 담기를 눌렀을 경우 위시리스트에서 표시가 되어야 함.
