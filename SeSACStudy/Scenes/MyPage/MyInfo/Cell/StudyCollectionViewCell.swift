//
//  StudyCollectionViewCell.swift
//  SeSACStudy
//
//  Created by 이현호 on 2022/11/17.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class StudyCollectionViewCell: BaseCollectionViewCell {
    
    let disposeBag = DisposeBag()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: Fonts.medium, size: 14)
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.08
        label.attributedText = NSMutableAttributedString(string: "자주 하는 스터디", attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
        return label
    }()
    
    let studyInfo: UITextField = {
        let text = UITextField()
        text.placeholder = "스터디를 입력해 주세요"
        return text
    }()
    
    let textline: UIView = {
        let line = UIView()
        line.backgroundColor = GrayScale.gray3
        return line
    }()
    
    override func configure() {
        [titleLabel, studyInfo, textline].forEach{ contentView.addSubview($0) }
    }
    
    override func setConstraints() {
        titleLabel.snp.makeConstraints {
            $0.leading.verticalEdges.equalTo(safeAreaLayoutGuide).inset(16)
        }
        
        textline.snp.makeConstraints {
            $0.height.equalTo(1)
            $0.top.equalTo(titleLabel.snp.bottom).offset(-8)
            $0.trailing.equalTo(safeAreaLayoutGuide).inset(16)
            $0.width.equalTo(safeAreaLayoutGuide).multipliedBy(0.5)
        }
        
        studyInfo.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(16)
            $0.centerY.equalTo(titleLabel)
            $0.centerX.equalTo(textline.snp.centerX).offset(8)
            $0.trailing.equalTo(textline.snp.trailing)
        }
    }
    
    override func bindData() {
        //MARK: - 유저 디폴트 값을 studyInfo 텍스트에 적용
        studyInfo.text = UserDefaultsManager.study
        
        studyInfo.rx.controlEvent([.editingDidEnd, .editingDidEndOnExit])
            .withUnretained(self)
            .bind { (vc, _) in
                UserDefaultsManager.study = vc.studyInfo.text
            }
            .disposed(by: disposeBag)
    }
    
    //MARK: - 스터디 편집에 대한 종료
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.endEditing(true)
    }
}
