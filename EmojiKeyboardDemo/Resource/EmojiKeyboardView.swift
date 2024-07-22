//
//  EmojiKeyboardView.swift
//  EmojiKeyboardDemo
//
//  Created by li.wenxiu on 2024/7/15.
//

import UIKit

class EmojiKeyboardView: UIView, NibInstantiatable, UICollectionViewDelegate, UICollectionViewDataSource {
    
    private class KeyCell: UICollectionViewCell {
        
        var text: String? {
            didSet {
                self.label.text = text
                self.imageView.image = nil
            }
        }
        
        var image: UIImage? {
            didSet {
                self.imageView.image = image
                self.label.text = nil
            }
        }
        
        var contentInset: UIEdgeInsets = .zero
        
        private weak var label: UILabel!
        private weak var imageView: UIImageView!
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            let label = UILabel(frame: self.contentView.bounds)
            label.font = UIFont.systemFont(ofSize: 32)
            label.textAlignment = .center
            label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.contentView.addSubview(label)
            self.label = label
            
            let imageView = UIImageView(frame: self.contentView.bounds)
            imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            imageView.contentMode = .scaleAspectFit
            self.contentView.addSubview(imageView)
            self.imageView = imageView
            
            let selectedBackgroundView = UIView(frame: self.bounds)
            selectedBackgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            selectedBackgroundView.backgroundColor = UIColor.lightGray
            selectedBackgroundView.layer.cornerRadius = 10
            self.selectedBackgroundView = selectedBackgroundView
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            let imageWidth = self.contentView.bounds.width - contentInset.left - contentInset.right
            let imageHeight = self.contentView.bounds.height - contentInset.top - contentInset.bottom
            imageView.frame = .init(origin: .init(x: contentInset.left, y: contentInset.top),
                                    size: .init(width: imageWidth, height: imageHeight))
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var deleteButton: UIButton!
    @IBOutlet private weak var sendButton: UIButton!
    
    var inputHandler: ((EmojiKeyboard.Emoji) -> Void)?
    var returnHandler: (() -> Void)?
    var backspaceHandler: (() -> Void)?
    
    private let emojis = EmojiKeyboard.Emoji.all
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let numberOfColumns: CGFloat = 7
        let layoutItem = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1/numberOfColumns),
                                                                  heightDimension: .fractionalHeight(1)))
        layoutItem.contentInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)
        let layoutGroup = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                                                               heightDimension: .fractionalWidth(1/numberOfColumns)),
                                                             subitems: [layoutItem])
        let layoutSection = NSCollectionLayoutSection(group: layoutGroup)
        layoutSection.contentInsets = .init(top: 8, leading: 8, bottom: 56, trailing: 8)
        let compositionalLayout = UICollectionViewCompositionalLayout(section: layoutSection)
        self.collectionView.collectionViewLayout = compositionalLayout
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.register(KeyCell.self, forCellWithReuseIdentifier: "Cell")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        for view in superview?.subviews ?? [] {
            if view !== self {
                view.isHidden = true
            }
        }
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        if newSuperview == nil {
            for view in superview?.subviews ?? [] {
                if view !== self {
                    view.isHidden = false
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        self.emojis.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! KeyCell
        cell.image = UIImage(contentsOfFile: self.emojis[indexPath.item].imageURL.path)
        cell.contentInset = .init(top: 8, left: 8, bottom: 8, right: 8)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let emoji = self.emojis[indexPath.item]
        self.inputHandler?(emoji)
    }
    
    @IBAction private func sendButtonTapped(_ sender: UIButton) {
        self.returnHandler?()
    }
    
    @IBAction private func deleteButtonTapped(_ sender: UIButton) {
        self.backspaceHandler?()
    }
}
