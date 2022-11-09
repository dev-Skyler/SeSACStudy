//
//  PhoneAuthView.swift
//  SeSACStudy
//
//  Created by 이현호 on 2022/11/09.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class PhoneAuthView: BaseView {
    
    let disposeBag = DisposeBag()
    
    let viewModel = PhoneAuthViewModel()
    
    let label: UILabel = {
        let label = UILabel()
        label.textColor = BlackNWhite.black
        label.font = UIFont(name: Fonts.regular, size: 20)
        label.textAlignment = .center
        label.numberOfLines = 0
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.08
        paragraphStyle.alignment = .center
        label.attributedText = NSMutableAttributedString(string: "새싹 서비스 이용을 위해\n휴대폰 번호를 입력해 주세요", attributes: [NSAttributedString.Key.kern: -0.5, NSAttributedString.Key.paragraphStyle: paragraphStyle])
        return label
    }()
    
    let phoneNumberText: UITextField = {
        let text = UITextField()
        text.placeholder = "휴대폰 번호(-없이 숫자만 입력)"
        text.keyboardType = .numberPad
        return text
    }()
    
    let underline: UIView = {
        let view = UIView()
        view.backgroundColor = GrayScale.gray5
        return view
    }()
    
    let authButton: UIButton = {
        let button = UIButton()
        button.setTitle("인증 문자 받기", for: .normal)
        button.layer.cornerRadius = 10
        button.backgroundColor = GrayScale.gray5
        return button
    }()
    
    override func configure() {
        [authButton, underline, phoneNumberText, label].forEach { self.addSubview($0) }
    }
    
    override func setConstraints() {
        authButton.snp.makeConstraints { make in
            make.horizontalEdges.equalTo(self.safeAreaLayoutGuide).inset(16)
            make.bottom.equalTo(self.safeAreaLayoutGuide).multipliedBy(0.6)
            make.height.equalTo(self.safeAreaLayoutGuide).multipliedBy(0.07)
        }
        
        underline.snp.makeConstraints { make in
            make.height.equalTo(1)
            make.horizontalEdges.equalTo(self.safeAreaLayoutGuide).inset(16)
            make.bottom.equalTo(authButton.snp.top).multipliedBy(0.8)
        }
        
        phoneNumberText.snp.makeConstraints { make in
            make.horizontalEdges.equalTo(self.safeAreaLayoutGuide).inset(16)
            make.bottom.equalTo(underline.snp.top).offset(15)
            make.height.equalTo(self.safeAreaLayoutGuide).multipliedBy(0.1)
        }
        
        label.snp.makeConstraints { make in
            make.centerX.equalTo(self.safeAreaLayoutGuide)
            make.bottom.equalTo(phoneNumberText.snp.top).multipliedBy(0.8)
        }
    }
    
    override func bindData() {
        
        let input = PhoneAuthViewModel.Input(phoneNumberText: phoneNumberText.rx.text)
        let output = viewModel.transform(input: input)
        
        phoneNumberText.rx.controlEvent([.editingDidBegin, .editingDidEnd])
            .withUnretained(self)
            .bind { (vc, _) in
                vc.underline.backgroundColor = BlackNWhite.black
            }
            .disposed(by: disposeBag)
        
        //MARK: - 폰번호 하이픈 추가
        output.changeFormat
            .drive(phoneNumberText.rx.text)
            .disposed(by: disposeBag)        
        
        //MARK: - 폰번호에 대한 유효성 검사
        output.phoneNum
            .withUnretained(self)
            .bind(onNext: { (vc, value) in
                vc.authButton.isEnabled = value
                value ? (vc.authButton.backgroundColor = BrandColor.green ) : (vc.authButton.backgroundColor = GrayScale.gray6)
            })
            .disposed(by: disposeBag)
    }
    
    //MARK: - 키보드 내리기
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.endEditing(true)
    }
}