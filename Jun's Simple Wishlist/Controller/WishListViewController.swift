import UIKit
import CoreData
//import RemoteProduct

class WishListViewController: UITableViewController {
    // 앱 델리게이트에서 가져온 CoreData의 'NSPersistentContainer'를 저장하는 변수
    // 옵셔널 타입으로 선언되어 있으며, 앱 델리게이트가 AppDelegate이고 'firstContainer' 속성을 가진 경우에만 유효 한 부분
    var firstContainer: NSPersistentContainer? {
        // UIApplication의 'shared' 싱글톤 인스턴스를 사용하여 앱 델리게이트에 접근
        // 이것을 'AppDelegate'로 캐스팅 -> 'firstContainer' 속성을 가져옴
        // if(만약) 앱 델리게이트가 AppDelegate가 아니거나 firstContainer 속성이 없는 경우 nil 값을 반환
        (UIApplication.shared.delegate as? AppDelegate)?.firstContainer
    }
    
    var productList: [Product] = [] // 테이블 뷰에 표시할 상품 목록을 저장하는 배열
    
    override func viewDidLoad() {
        super.viewDidLoad() // 부모 클래스의 viewDidLoad 메서드를 호출
        // 테이블 뷰의 데이터 소스를 현재 뷰 컨트롤러(self)로 설정
        self.tableView.dataSource = self
        // 테이블 뷰에 사용할 셀을 등록, "Cell"이라는 재사용 식별자를 가진 기본 UITableViewCell을 사용
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        // CoreData에서 상품 정보를 불러와서 productList 변수에 저장하는 메서드를 호출
        setProductList()
        
        // 새로 고침을 작동 할 수 있도록 구현 해보자
        // UIRefreshControl을 생성
        let refreshControl = UIRefreshControl()
        
        // 당겨서 새로고침시 호출될 메서드를 addTarget으로 추가
        refreshControl.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
        
        // 테이블 뷰의 refreshControl 속성에 UIRefreshControl을 할당하여 연결
        self.refreshControl = refreshControl
        
        
    }
    
    // CoreData에서 상품 정보를 불러와, productList 변수에 저장
    private func setProductList() {
        // CoreData의 관리 객체 컨텍스트를 가져오고 없다면 메서드를 종료
        guard let context = self.firstContainer?.viewContext else { return }
        
        // Product 엔터티에 대한 요청(request)을 생성
        let request = Product.fetchRequest()
        
        // 컨텍스트에서 요청을 실행하고, 결과를 'productList' 배열에 저장
        // 만약 실행에 실패하면(예외가 발생하면), 'productList'를 'nil'값으로 설정
        if let productList = try? context.fetch(request) {
            self.productList = productList // 'productList' 배열에 결과를 저장
        }
    }
    
    
    // 'productList'의 'count'를 반환
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.productList.count
    }
    
    // 각 'index'별로 'tableView cell' 반환
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 재사용 가능한 셀을 가져오고 만약 없다면 새로운 셀을 생성
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        // 특정 indexPath에 대한 상품 데이터를 가져옴
        let product = self.productList[indexPath.row]
        
        // 상품의 id, title, price를 가져옴
        let id = product.id
        let title = product.title ?? "" // 제목이 없을 경우 빈 문자열 처리
        let price = product.price
        
        // 셀의 텍스트 레이블에 상품 정보를 표시
        cell.textLabel?.text = "[\(id)] \(title) - \(price)$"
        
        // Lv4 삭제 버튼 구현
        // 삭제 버튼을 생성
        let deleteButton = UIButton(type: .system)
        
        // 버튼에 "삭제"라는 텍스트를 설정
        deleteButton.setTitle("삭제", for: .normal)
        
        // 버튼의 프레임을 설정 (위치 및 크기)
        deleteButton.frame = CGRect(x: 0, y: 0, width: 60, height: 30)
        
        // 버튼에 액션을 추가 deleteButtonTapped(_:) 메서드가 호출되도록 설정
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped(_:)), for: .touchUpInside)
        
        // 셀의 accessoryView로 삭제 버튼을 설정, accessoryView는 셀의 오른쪽에 추가되는 보조 뷰
        cell.accessoryView = deleteButton
        
        // 구성된 셀을 반환
        return cell
        
    }
    
    //     Lv4 삭제 버튼 추가
    //     삭제 버튼을 눌렀을 때의 동작
    @objc func deleteButtonTapped(_ sender: UIButton) {
        // 버튼을 포함한 셀의 indexPath를 찾는다
        guard let cell = sender.superview as? UITableViewCell, // 버튼의 상위 뷰가 UITableViewCell인지 확인
              let indexPath = tableView.indexPath(for: cell) else { // 버튼이 속한 셀의 indexPath를 가져온다
            return // 셀을 찾지 못한 경우 메서드 실행을 종료
        }
        
        // 선택한 셀의 인덱스에 해당하는 상품을 productList 배열에서 가져오는 변수
        let selectedProduct = productList[indexPath.row]
        
        // CoreData에서 해당 상품을 삭제하는 변수
        if let context = firstContainer?.viewContext { // CoreData의 컨텍스트를 가져오고
            context.delete(selectedProduct) // 컨텍스트에서 선택한 상품을 삭제한다
            
            do {
                try context.save() // 변경사항을 저장하고
                // 데이터 소스를 업데이트하여 삭제된 항목이 화면에서 사라지도록 한다
                setProductList() // productList를 업데이트하고
                tableView.reloadData() // 테이블 뷰를 다시 로드하여 변경사항을 반영시켜주자
            } catch {
                // 오류가 발생한 경우 콘솔에 오류 메시지를 출력하자
                print("상품 오류: \(error)")
            }
        }
    }
    
    // 새로고침 동작
    @objc private func refresh(_ sender: Any) {
        setProductList() // 새로고침이 발생하면 상품 목록을 업데이트하고
        self.tableView.reloadData() // 테이블 뷰를 다시 로드하여 변경된 데이터를 반영 후
        self.refreshControl?.endRefreshing() // UIRefreshControl의 새로고침 상태를 종료
    }
}
