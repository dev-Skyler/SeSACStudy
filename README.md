<img src="https://user-images.githubusercontent.com/78537078/209440172-e6e20eee-514f-4d98-a549-dde88a67812c.png" width = "20%">

# SeSACStudy

- 현재 위치 기반 주변에서 내가 원하는 사람과 스터디를 할 수 있게 1대1 채팅으로 매칭 시켜주는 앱입니다.

</br>

<p>
<img src="https://user-images.githubusercontent.com/78537078/209194267-7c55028e-05ff-49ef-8f15-433f0f898354.png" width = "15%">
<img src="https://user-images.githubusercontent.com/78537078/209194185-3af35245-ffb2-4e14-817e-c0bbddfa1237.png" width = "15%">
<img src="https://user-images.githubusercontent.com/78537078/209194187-a4689579-f810-4a7f-b1cf-8544dbafb015.png" width = "15%">
<img src="https://user-images.githubusercontent.com/78537078/209194190-e1bff327-52da-43ac-bb65-4e4b11e66c42.png" width = "15%">
<img src="https://user-images.githubusercontent.com/78537078/209194194-458ae2b1-fe55-4536-8f4c-a788982d9024.png" width = "15%">
<img src="https://user-images.githubusercontent.com/78537078/209194520-49db17dd-d753-42fa-8252-fc713ddda990.png" width = "15%">
</p>

</br>

## 1. 제작 기간 & 참여 인원
- 2022년 11월 7일 ~ 12월 10일 (5주)
- 개인 프로젝트

</br>

## 2. 사용 기술
| kind | stack |
| ------ | ------ |
| 아키텍처 | `MVC` `MVVM` `Input/output` |
| 프레임워크 | `UIKit` `Foundation` `MapKit` `Network` `StoreKit` `CoreLocation`|
| UI | `Snapkit` `Codebase` |
| 라이브러리 | `Toast` `RxSwift` `RxCocoa` `SnapKit` `RxKeyboard` `Tabman` `SocketIO` `FirebaseAuth` `FirebaseMessaging` |
| 데이터베이스 | `Realm` |
| 네트워크 | `Alamofire` |
| 의존성관리 | `Swift Package Manager` |
| Tools | `Git / Github` `Jandi` |
| ETC | `DiffableDataSource` `Compositional Layout` |

</br>

## 3. 핵심 기능

이 서비스의 핵심 기능은 검색을 통해 스터디를 찾고 채팅으로 스터디에 대한 일정을 계획하는 것입니다.
- 검색 기능
- 채팅 기능
- 인앱 결제

<details>
<summary><b>핵심 기능 설명 펼치기</b></summary>

### 3.1 검색 기능

- 찾기 버튼 클릭 시 내가 원하는 태그 값 배열을 파라미터로 갖는 찾기 통신 실행
``` swift
func sesacSearch(completion: @escaping (String?, Int?, Error?) -> Void) {
    
    let url = UserDefaultsManager.baseURL + UserDefaultsManager.sesacPath
    
    let header: HTTPHeaders = [
        "idtoken": UserDefaultsManager.token,
        "Content-Type": "application/x-www-form-urlencoded"
    ]
    
    let parameter: [String : Any] = [
        "long": UserDefaultsManager.long,
        "lat": UserDefaultsManager.lat,
        "studylist": UserDefaultsManager.studyList.isEmpty ? ["anything"] : UserDefaultsManager.studyList
    ]
    let enc: ParameterEncoding = URLEncoding(arrayEncoding: .noBrackets)
    
    AF.request(url, method: .post, parameters: parameter, encoding: enc, headers: header).responseString { response in
        guard let statusCode = response.response?.statusCode else { return }
        switch response.result {
        case .success(let data):
            completion(data, statusCode, nil)
        case .failure(let error):
            completion(nil, statusCode, error)
        }
    }
}
```

- 통신을 통해 내 주변 태그 값 배열에 맞는 사용자들을 리스트로 구현
``` swift
func updateUI() {
    currentSnapshot = NSDiffableDataSourceSnapshot<FromQueueDB, Item>()
    let sections = pageboyPageIndex == 0 ? SesacList.aroundList : SesacList.requestList
    currentSnapshot.appendSections(sections)
    for section in sections {
        var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<Item>()
        let headerItem = Item(uid: section.uid, sesac: section.sesac, background: section.background, nick: section.nick)
        sectionSnapshot.append([headerItem])
        //let items = Item(sesac: nil, background: nil, nick: SesacList.aroundList[section].nick)
        //sectionSnapshot.append([items], to: headerItem)
        //sectionSnapshot.expand([headerItem])
        dataSource.apply(sectionSnapshot, to: section)
    }
}
```

### 3.2 채팅 기능

- 채팅 화면 진입 시 실시간 통신을 위한 소켓 연결
``` swift
socket.on(clientEvent: .connect) { data, ack in
    print("SOCKET IS CONNECTED", data, ack)
    self.socket.emit("changesocketid", ChatDataModel.shared.myUid)
}

SocketIOManager.shared.establishConnection()
```

- 이전 대화 기록 로드 후 채팅창에 나타냄
``` swift
APIService.loadChat { [weak self] (value, statusCode, error) in
    guard let statusCode = statusCode else { return }
    guard let status = NetworkError(rawValue: statusCode) else { return }
    switch status {
    case .success:
        value?.payload.forEach { ChatRepository.shared.saveChat(item: ChatData(chatId: $0.id, toChat: $0.to, fromChat: $0.from, chatContent: $0.chat, chatDate: $0.createdAt)) }
        self?.chatView.tableView.reloadData()
        if ChatRepository.shared.tasks?.count ?? 0 > 0 { 
        self?.chatView.tableView.scrollToRow(at: IndexPath(row: (ChatRepository.shared.tasks?.count ?? 0) - 1, section: 0), at: .bottom, animated: false)
        }
```

- 채팅 수신 시 NotificationCenter를 통해 값을 전달
``` swift
socket.on(TextCase.Chatting.ChatSokcet.chat.rawValue) { dataArray, ack in
    print("CHAT RECEIVED", dataArray, ack)
    
    //인코딩되어있는 내용을 타입캐스팅을 통해 알아볼 수 있게 변환함
    let data = dataArray[0] as! NSDictionary
    let id = data[TextCase.Chatting.ChatSokcet.id.rawValue] as! String
    let chat = data[TextCase.Chatting.ChatSokcet.chat.rawValue] as! String
    let createdAt = data[TextCase.Chatting.ChatSokcet.createdAt.rawValue] as! String
    let from = data[TextCase.Chatting.ChatSokcet.from.rawValue] as! String
    let to = data[TextCase.Chatting.ChatSokcet.to.rawValue] as! String
    
    NotificationCenter.default.post(name: NSNotification.Name("getMessage"), object: self, userInfo: [TextCase.Chatting.ChatSokcet.id.rawValue: id, TextCase.Chatting.ChatSokcet.chat.rawValue: chat, TextCase.Chatting.ChatSokcet.createdAt.rawValue: createdAt, TextCase.Chatting.ChatSokcet.from.rawValue: from, TextCase.Chatting.ChatSokcet.to.rawValue: to])
}
```

- NotificationCenter를 통해 전달받은 값을 채팅창에 실시간으로 나타냄
``` swift
@objc func getMessage(notification: NSNotification) {
    let id = notification.userInfo![TextCase.Chatting.ChatSokcet.id.rawValue] as! String
    let chat = notification.userInfo![TextCase.Chatting.ChatSokcet.chat.rawValue] as! String
    let createdAt = notification.userInfo![TextCase.Chatting.ChatSokcet.createdAt.rawValue] as! String
    let from = notification.userInfo![TextCase.Chatting.ChatSokcet.from.rawValue] as! String
    let to = notification.userInfo![TextCase.Chatting.ChatSokcet.to.rawValue] as! String
    
    let value = ChatData(chatId: id, toChat: to, fromChat: from, chatContent: chat, chatDate: createdAt)
    
    ChatRepository.shared.saveChat(item: value)
    chatView.tableView.reloadData()
    chatView.tableView.scrollToRow(at: IndexPath(row: (ChatRepository.shared.tasks?.count ?? 0) - 1, section: 0), at: .bottom, animated: false)
}
```

- 채팅 전송 버튼 클릭 시 네트워크 통신 후 성공 했을 경우 채팅창에 나타냄
``` swift
APIService.sendChat { value, statusCode, error in
    guard let statusCode = statusCode else { return }
    guard let status = NetworkError(rawValue: statusCode) else { return }
    switch status {
    case .success:
        guard let value = value else { return }
        ChatRepository.shared.saveChat(item: ChatData(chatId: value.id, toChat: value.to, fromChat: value.from, chatContent: value.chat, chatDate: value.createdAt))
        vc.tableView.reloadData()
        vc.tableView.scrollToRow(at: IndexPath(row: (ChatRepository.shared.tasks?.count ?? 0) - 1, section: 0), at: .bottom, animated: false)
    default:
        vc.showToast("잠시후 다시 요청해주세요.")
    }
}
```

### 3.3 인앱 결제

- 인앱 상품 ID 정의
``` swift
var productIdentifiers: Set<String> = ["com.memolease.sesac1.sprout1", "com.memolease.sesac1.sprout2", "com.memolease.sesac1.sprout3", "com.memolease.sesac1.sprout4", "com.memolease.sesac1.background1", "com.memolease.sesac1.background2", "com.memolease.sesac1.background3", "com.memolease.sesac1.background4", "com.memolease.sesac1.background5", "com.memolease.sesac1.background6", "com.memolease.sesac1.background7"]
```

- 정의된 상품 ID에 대한 정보 가져오기 및 사용자의 디바이스가 인앱결제가 가능한지 여부 확인
``` swift
if SKPaymentQueue.canMakePayments() {
    let request = SKProductsRequest(productIdentifiers: productIdentifiers)
    request.delegate = self
    request.start()
} else {
    print("In App Purchase Not Enabled")
}
```

- 인앱 상품 정보 조회
``` swift
func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
    
    let products = response.products
    
    if products.count > 0 {
        
        for i in products {
            productArray.append(i)
            //product = i //옵션. 테이블뷰 셀에서 구매하기 버튼 클릭 시, 버튼 클릭 시
            
            print(i.localizedTitle, i.price, i.priceLocale, i.localizedDescription)
        }
    } else {
        print("No Product Found") //계약 업데이트. 유료 계약 X. Capabilities X
    }
}
```

- 가격 버튼 클릭 시 인앱 결제 시작
``` swift
func purchaseStart(product: SKProduct) {
    let payment = SKPayment(product: product)
    SKPaymentQueue.default().add(payment)
    SKPaymentQueue.default().add(self)
}
```

- 구매 상태 Observing
``` swift
func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
    
    for transaction in transactions {
        switch transaction.transactionState {
        case .purchased: 
            receiptValidation(transaction: transaction, productIdentifier: transaction.payment.productIdentifier)
        case .failed: 
            SKPaymentQueue.default().finishTransaction(transaction)
        default:
            break
        }
    }
}
```

- 구매 상태가 승인으로 되었을 경우 영수증 검증
``` swift
func receiptValidation(transaction: SKPaymentTransaction, productIdentifier: String) { [weak self]    
    let receiptFileURL = Bundle.main.appStoreReceiptURL
    let receiptData = try? Data(contentsOf: receiptFileURL!)
    let receiptString = receiptData?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
    
    ShopDataModel.shared.receipt = receiptString ?? ""
    ShopDataModel.shared.product = productIdentifier
    SKPaymentQueue.default().finishTransaction(transaction)
    self?.inApp()
}
```

- 데이터 통신을 통해 결제가 확인되면 보유중인 아이템으로 변경
``` swift
func inApp() {
    APIService.inApp { [weak self] (value, statusCode, error) in
        guard let statusCode = statusCode else { return }
        guard let status = NetworkError(rawValue: statusCode) else { return }
        switch status {
        case .success: self?.loadMyInfo()
        case .invalidToken: self?.refreshToken2()
        default: self?.makeToast("잠시 후 다시 시도해 주세요.")
        }
    }
}
```
</details>

</br>

## 4. 트러블슈팅

</br>

## 5. 회고
- 프로젝트 개발에 대한 회고 : https://skylert.tistory.com/63
