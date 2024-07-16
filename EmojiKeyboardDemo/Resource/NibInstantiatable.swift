//
//  Nib.swift
//  Hertown
//
//  Created by li.wenxiu on 2024/7/15.
//

import Foundation
import UIKit

protocol NibInstantiatable: AnyObject {
    static var nibName: String { get }
}

extension NibInstantiatable where Self: UIView {
    static var nibName: String {
        return String(describing: self)
    }
    static var nib: UINib {
        return UINib(nibName: nibName, bundle: nil)
    }
}

extension NibInstantiatable {
    static func instantiateFromNib() -> Self {
        UINib(nibName: nibName, bundle: nil).instantiate(withOwner: nil, options: nil).first(where: { $0 is Self }) as! Self
    }
}
