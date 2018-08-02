//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import Foundation

public enum FontTextStyle: String {
    case `default`   = "default"
    case largeTitle  = "largeTitle"
    case inputText   = "inputText"
}

public enum FontSize: String {
    case large  = "large"
    case normal = "normal"
    case medium = "medium"
    case small  = "small"
}

public enum FontWeight: String {
    case ultraLight = "ultraLight"
    case thin     = "thin"
    case light    = "light"
    case regular  = "regular"
    case medium   = "medium"
    case semibold = "semibold"
    case bold     = "bold"
    case heavy    = "heavy"
    case black    = "black"
}

@available(iOSApplicationExtension 8.2, *)
extension FontWeight {
    static let weightMapping: [FontWeight: UIFont.Weight] = [
        .ultraLight: UIFont.Weight.ultraLight,
        .thin:       UIFont.Weight.thin,
        .light:      UIFont.Weight.light,
        .regular:    UIFont.Weight.regular,
        .medium:     UIFont.Weight.medium,
        .semibold:   UIFont.Weight.semibold,
        .bold:       UIFont.Weight.bold,
        .heavy:      UIFont.Weight.heavy,
        .black:      UIFont.Weight.black
    ]
    
    /// Weight mapping used when the bold text accessibility setting is
    /// enabled. Light weight fonts won't render bold, so we use regular
    /// weights instead.
    static let accessibilityWeightMapping: [FontWeight: UIFont.Weight] = [
        .ultraLight: UIFont.Weight.regular,
        .thin:       UIFont.Weight.regular,
        .light:      UIFont.Weight.regular,
        .regular:    UIFont.Weight.regular,
        .medium:     UIFont.Weight.medium,
        .semibold:   UIFont.Weight.semibold,
        .bold:       UIFont.Weight.bold,
        .heavy:      UIFont.Weight.heavy,
        .black:      UIFont.Weight.black
    ]
    
    public func fontWeight(accessibilityBoldText: Bool? = nil) -> UIFont.Weight {
        let boldTextEnabled = accessibilityBoldText ?? UIAccessibilityIsBoldTextEnabled()
        let mapping = boldTextEnabled ? type(of: self).accessibilityWeightMapping : type(of: self).weightMapping
        return mapping[self]!
    }
    
    public init(weight: UIFont.Weight) {
        self = (type(of: self).weightMapping.filter {
            $0.value == weight
            }.first?.key) ?? FontWeight.regular
    }
}

extension UIFont {
    static func systemFont(ofSize size: CGFloat, contentSizeCategory: UIContentSizeCategory, weight: FontWeight) -> UIFont {
        if #available(iOSApplicationExtension 8.2, *) {
            return self.systemFont(ofSize: round(size * UIFont.wr_preferredContentSizeMultiplier(for: contentSizeCategory)), weight: weight.fontWeight())
        } else {
            return self.systemFont(ofSize: round(size * UIFont.wr_preferredContentSizeMultiplier(for: contentSizeCategory)))
        }
    }
    
    @objc public var classySystemFontName: String {
        get {
            let weightSpecifier = { () -> String in 
                guard #available(iOSApplicationExtension 8.2, *),
                    let traits = self.fontDescriptor.object(forKey: UIFontDescriptor.AttributeName.traits) as? NSDictionary,
                    let floatWeight = traits[UIFontDescriptor.TraitKey.weight] as? NSNumber else {
                        return ""
                }
                
                return "-\(FontWeight(weight: UIFont.Weight(rawValue: CGFloat(floatWeight.floatValue))).rawValue.capitalized)"
            }()
            
            return "System\(weightSpecifier) \(self.pointSize)"
        }
    }
}

extension UIFont {
    @objc public var isItalic: Bool {
        return fontDescriptor.symbolicTraits.contains(.traitItalic)
    }
    
    @objc public func italicFont() -> UIFont {
        
        if isItalic {
            return self
        } else {
            var symbolicTraits = fontDescriptor.symbolicTraits
            symbolicTraits.insert([.traitItalic])
            
            if let newFontDescriptor = fontDescriptor.withSymbolicTraits(symbolicTraits) {
                return UIFont(descriptor: newFontDescriptor, size: pointSize)
            } else {
                return self
            }
        }
    }
}

public struct FontSpec: Hashable {
    public let size: FontSize
    public let weight: FontWeight
    public let fontTextStyle: FontTextStyle


    /// init method of FontSpec
    ///
    /// - Parameters:
    ///   - size: a FontSize enum
    ///   - weight: a FontWeight enum, if weight == nil, then apply the default value .light
    ///   - fontTextStyle: FontTextStyle enum value.
    public init(_ size: FontSize, _ weight: FontWeight, _ fontTextStyle: FontTextStyle = .default) {
        self.size = size
        self.weight = weight
        self.fontTextStyle = fontTextStyle
    }
}

extension FontSpec {
    var fontWithoutDynamicType: UIFont? {
        return FontScheme(contentSizeCategory: .medium).font(for: self)
    }
}

extension FontSpec: CustomStringConvertible {
    public var description: String {
        var descriptionString = "\(self.size)"
        descriptionString += "-\(weight)"
        descriptionString += "-\(fontTextStyle.rawValue)"
        return descriptionString
    }
}

@objcMembers public final class FontScheme: NSObject {
    public typealias FontMapping = [FontSpec: UIFont]
    
    public var fontMapping: FontMapping = [:]
    
    fileprivate static func mapFontTextStyleAndFontSizeAndPoint(fintSizeTuples allFontSizes: [(fontSize: FontSize, point: CGFloat)], mapping: inout [FontSpec : UIFont], fontTextStyle: FontTextStyle, contentSizeCategory: UIContentSizeCategory) {
        let allFontWeights: [FontWeight] = [.ultraLight, .thin, .light, .regular, .medium, .semibold, .bold, .heavy, .black]
        for fontWeight in allFontWeights {
            for fontSizeTuple in allFontSizes {
                mapping[FontSpec(fontSizeTuple.fontSize, .regular, fontTextStyle)]      = UIFont.systemFont(ofSize: fontSizeTuple.point, contentSizeCategory: contentSizeCategory, weight: .light)

                mapping[FontSpec(fontSizeTuple.fontSize, fontWeight, fontTextStyle)] = UIFont.systemFont(ofSize: fontSizeTuple.point, contentSizeCategory: contentSizeCategory, weight: fontWeight)
            }
        }
    }

    public static func defaultFontMapping(with contentSizeCategory: UIContentSizeCategory) -> FontMapping {
        var mapping: FontMapping = [:]


        // The ratio is following 11:12:16:24, same as default case
        let largeTitleFontSizeTuples: [(fontSize: FontSize, point: CGFloat)] = [(fontSize: .large,  point: 40),
                                                                                (fontSize: .normal, point: 26),
                                                                                (fontSize: .medium, point: 20),
                                                                                (fontSize: .small,  point: 18)]
        mapFontTextStyleAndFontSizeAndPoint(fintSizeTuples: largeTitleFontSizeTuples, mapping: &mapping, fontTextStyle: .largeTitle, contentSizeCategory: contentSizeCategory)


        let inputTextFontSizeTuples: [(fontSize: FontSize, point: CGFloat)] = [(fontSize: .large,  point: 21),
                                                                               (fontSize: .normal, point: 14),
                                                                               (fontSize: .medium, point: 11),
                                                                               (fontSize: .small,  point: 10)]
        mapFontTextStyleAndFontSizeAndPoint(fintSizeTuples: inputTextFontSizeTuples, mapping: &mapping, fontTextStyle: .inputText, contentSizeCategory: contentSizeCategory)

        /// fontTextStyle: none

        mapping[FontSpec(.large, .regular, .default)]      = UIFont.systemFont(ofSize: 24, contentSizeCategory: contentSizeCategory, weight: .light)
        mapping[FontSpec(.large, .medium, .default)]    = UIFont.systemFont(ofSize: 24, contentSizeCategory: contentSizeCategory, weight: .medium)
        mapping[FontSpec(.large, .semibold, .default)]  = UIFont.systemFont(ofSize: 24, contentSizeCategory: contentSizeCategory, weight: .semibold)
        mapping[FontSpec(.large, .regular, .default)]   = UIFont.systemFont(ofSize: 24, contentSizeCategory: contentSizeCategory, weight: .regular)
        mapping[FontSpec(.large, .light, .default)]     = UIFont.systemFont(ofSize: 24, contentSizeCategory: contentSizeCategory, weight: .light)
        mapping[FontSpec(.large, .thin, .default)]      = UIFont.systemFont(ofSize: 24, contentSizeCategory: contentSizeCategory, weight: .thin)

        mapping[FontSpec(.normal, .regular, .default)]     = UIFont.systemFont(ofSize: 16, contentSizeCategory: contentSizeCategory, weight: .light)
        mapping[FontSpec(.normal, .light, .default)]    = UIFont.systemFont(ofSize: 16, contentSizeCategory: contentSizeCategory, weight: .light)
        mapping[FontSpec(.normal, .thin, .default)]     = UIFont.systemFont(ofSize: 16, contentSizeCategory: contentSizeCategory, weight: .thin)
        mapping[FontSpec(.normal, .regular, .default)]  = UIFont.systemFont(ofSize: 16, contentSizeCategory: contentSizeCategory, weight: .regular)
        mapping[FontSpec(.normal, .semibold, .default)] = UIFont.systemFont(ofSize: 16, contentSizeCategory: contentSizeCategory, weight: .semibold)
        mapping[FontSpec(.normal, .medium, .default)]   = UIFont.systemFont(ofSize: 16, contentSizeCategory: contentSizeCategory, weight: .medium)

        mapping[FontSpec(.medium, .regular, .default)]     = UIFont.systemFont(ofSize: 12, contentSizeCategory: contentSizeCategory, weight: .light)
        mapping[FontSpec(.medium, .medium, .default)]   = UIFont.systemFont(ofSize: 12, contentSizeCategory: contentSizeCategory, weight: .medium)
        mapping[FontSpec(.medium, .semibold, .default)] = UIFont.systemFont(ofSize: 12, contentSizeCategory: contentSizeCategory, weight: .semibold)
        mapping[FontSpec(.medium, .regular, .default)]  = UIFont.systemFont(ofSize: 12, contentSizeCategory: contentSizeCategory, weight: .regular)

        mapping[FontSpec(.small, .regular, .default)]      = UIFont.systemFont(ofSize: 11, contentSizeCategory: contentSizeCategory, weight: .light)
        mapping[FontSpec(.small, .medium, .default)]    = UIFont.systemFont(ofSize: 11, contentSizeCategory: contentSizeCategory, weight: .medium)
        mapping[FontSpec(.small, .semibold, .default)]  = UIFont.systemFont(ofSize: 11, contentSizeCategory: contentSizeCategory, weight: .semibold)
        mapping[FontSpec(.small, .regular, .default)]   = UIFont.systemFont(ofSize: 11, contentSizeCategory: contentSizeCategory, weight: .regular)
        mapping[FontSpec(.small, .light, .default)]     = UIFont.systemFont(ofSize: 11, contentSizeCategory: contentSizeCategory, weight: .light)

        return mapping
    }
    
    @objc public convenience init(contentSizeCategory: UIContentSizeCategory) {
        self.init(fontMapping: type(of: self).defaultFontMapping(with: contentSizeCategory))
    }
    
    public init(fontMapping: FontMapping) {
        self.fontMapping = fontMapping

        super.init()
    }
    
    public func font(for fontType: FontSpec) -> UIFont? {
        return self.fontMapping[fontType]
    }
}
