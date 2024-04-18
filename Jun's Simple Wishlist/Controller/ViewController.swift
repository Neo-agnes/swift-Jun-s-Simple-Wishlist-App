import UIKit
import CoreData

class ViewController: UIViewController {
    /*
     스토리 보드에 올린 UI 컴포넌트들을 보여주어야 하고 동작을 구현 시켜주어야 합니다.
     */
    // 위시리스트 담기를 통해 실제 코어데이터의 모델을 넣어 주어야 하니 데이터를 넣기 위해 컨테이너를 하나 선언 해줍니다.
    var firstContainer: NSPersistentContainer? {
        (UIApplication.shared.delegate as? AppDelegate)?.firstContainer
    }
    
    // 현재 상태를 보여줄 데이터를 의미하는 코드 (이미지, 타이틀, 설명, 가격 등등등)
    // RemoteProduct = 원격으로 가져왔던 API를 찔러서 가져왔던 응답모델 타입
    var currentProduct: RemoteProduct? = nil {
        didSet { // didSet : DietProduct가 변한다면, 아래와 같은 작업을 수행하도록 하라..
            // guard(가드렛)사용이유 = DietProduct가 nil이 아닐경우에 가져와야 하니까 guard(가드렛)으로 바인딩 해줍니다.
            guard let currentProduct = self.currentProduct else { return }
            
            
            // DispatchQueue문을 사용하는데 main을 사용한 이유는 = UI가 변하거나 UI와 관련된 작업들은 모두 main에서 행해주어야 합니다. 즉, main 스레드에서 다루어 주어야 하기 때문에 main으로 가져옵니다.
            // async(어싱크) = 비동기
            DispatchQueue.main.async {
                self.imageView.image = nil // 비동기로 imageView의 image가 없다면 없고, 따로 다른 코드로 처리할 것이기 때문에 nil값으로 줍니다.
                // 아래 3개의 텍스트 레이블들은 스토리보드와 연결되어 있으니, 이들은 모두 String로 넘겨줄 수 있도록 설정 해 줍니다.
                self.titleLabel.text = currentProduct.title
                self.descriptionLabel.text = currentProduct.description
                self.priceLabel.text = "\(currentProduct.price)원"
            }
            
            // 위에서 nil로 이미지를 설정한 내용의 대한 이미지 데이터화 및 이미지->UI이미지로 변경->표출 이 과정들을 글로벌로 main 스레드에서 작동하지 않도록 감싸줍니다.
            // data 타입은 data입니다. 그렇기 때문에 'DietProduct'의 섬네일이 URL로 넘어올 것이며 때문에 contentsOf의 thumbnail(섬네일)이 URL로 넘어 오는 것입니다. 때문에 contentsOf에 해당하는 URL을 담아 데이터화 시켜줍니다. Data 타입으로 변환을 하고 Data을 가지고 UI 이미지로 변환을 해주는 과정입니다. 그래서 아래 이미지의 타입을 보면, UIImage로 변환을 해주되 data에 해당 URL을 가지고 만들어진 데이터를 넘겨주어 UIImage를 구현할 수 있는 것.
            DispatchQueue.global().async { [weak self] in
                if let data = try? Data(contentsOf: currentProduct.thumbnail),
                   let image = UIImage(data: data) {
                    DispatchQueue.main.async { self?.imageView.image = image }// 그렇게 된 이미지를 다시 main 스레드를 통해 UI에 보여 주어야 하니 imageView에 image는 위에서 변환된 이미지를 올려주는 것입니다. 이는 반드시 main 스레드에서 해주어야 함
                }
            }
        }
    }
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.fetchRemoteProduct()
    }
    
    // 다른 상품을 보는 버튼에 대한 IB액션을 정의
    @IBAction func nextBT(_ sender: UIButton) {
        self.fetchRemoteProduct() // 새 상품을 불러오는 함수 호출
    }
    
    // 장바구니에 담기 버튼에 대한 IB액션을 정의
    @IBAction func basKetBT(_ sender: UIButton) {
        self.saveWishProduct() // CoreData에 상품을 저장하는 함수 호출
    }
    
    // 장바구니에 담았던 내 상품에 대한 IB액션을 정의
    @IBAction func listBT(_ sender: UIButton) {
        // WishListViewController를 가져옵시다.
        guard let nextVC = self.storyboard?
            .instantiateViewController(identifier: "WishListViewController") as? WishListViewController else { return }
        
        // 잠시 떳다가 보여주는 형식
        self.present(nextVC, animated: true)
    }
    
    // URLSession을 통해서 RemoteProduct를 가져와서 dietProduct 변수에 저장
    func fetchRemoteProduct() {
        // 1 ~ 100 사이의 랜덤한 Int 숫자를 가져 옵니다.
        let productID = Int.random(in: 1...100)
        
        // URLSession을 통한 RemoteProduct 가져오기
        if let url = URL(string: "https://dummyjson.com/products/\(productID)") {
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                if let error = error {
                    print("Error:\(error)")
                } else if let data = data {
                    do {
                        // product를 디코드 -> currentProduct 변수에 담는다.
                        let product = try JSONDecoder().decode(RemoteProduct.self, from: data)
                        self.currentProduct = product
                    } catch {
                        print("Decode Error: \(error)")
                    }
                }
            }
            // 네트웤 요청 시작
            task.resume()
        }
    }
    // currentProduct 가져와서 코어데이터에 저장
    func saveWishProduct() {
        // CoreData의 관리 객체 컨텍스트를 가져오고 없다면 메서드를 종료
        guard let context = self.firstContainer?.viewContext else { return }
        
        // 현재 상품이 nil이 아닌지 확인하고 nil값이라면 메서드를 종료
        guard let currentProduct = self.currentProduct else { return }
        
        // CoreData에 새로운 Product 인스턴스를 생성하는 변수를 만들고
        let wishProduct = Product(context: context)
        
        // 새로운 Product 인스턴스에 현재 상품의 정보를 설정
        wishProduct.id = Int64(currentProduct.id) // 현재 상품의 id를 설정
        wishProduct.title = currentProduct.title // 현재 상품의 타이틀을 설정
        wishProduct.price = currentProduct.price // 현재 상품의 가격을 설정
        
        // 변경사항을 저장하고 혹시나 오류가 발생하더라도 무시하도록 명령
        try? context.save()
    }

}

