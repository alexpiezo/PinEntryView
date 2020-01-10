import SwiftUI

private struct PinUITextField:UIViewRepresentable{
    private class CUITextField: UITextField {
        override func closestPosition(to point: CGPoint) -> UITextPosition? {
            let beginning = self.beginningOfDocument
            let end = self.position(from: beginning, offset: self.text?.count ?? 0)
            return end
        }
    }
   
    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        @Binding var numberOfDigits:Int
        
        var didBecomeFirstResponder = false
        var onComplete:((String) -> Void)?

        
        init(text: Binding<String>, numberOfDigits:Binding<Int>, onComplete:((String) -> Void)?) {
            _text = text
            _numberOfDigits = numberOfDigits
            self.onComplete = onComplete
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            text = textField.text ?? ""
            didBecomeFirstResponder = textField.isFirstResponder
            if numberOfDigits == text.count{
                self.onComplete?(text)
            }
        }
                
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let oldLength = textField.text!.count
            let replacementLength = string.count
            let rangeLength = range.length
            let newLength = oldLength - rangeLength + replacementLength
            return newLength <= numberOfDigits
        }
    }
    
    @Binding var text: String
    @Binding var numberOfDigits: Int
    @Binding var isFirstResponder: Bool
    var onComplete:((String) -> Void)?
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(text: $text, numberOfDigits: $numberOfDigits, onComplete: onComplete)
    }
    
    func makeUIView(context: Context) -> UITextField {
        let textField = CUITextField(frame: .zero)
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.setContentHuggingPriority(.defaultHigh, for: .vertical)
        textField.keyboardType = .numberPad
        textField.textContentType = .oneTimeCode
        textField.isHidden = true
        textField.delegate = context.coordinator

        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if isFirstResponder && !context.coordinator.didBecomeFirstResponder  {
            uiView.becomeFirstResponder()
            context.coordinator.didBecomeFirstResponder = true
        }
        if !isFirstResponder && context.coordinator.didBecomeFirstResponder  {
            uiView.resignFirstResponder()
            context.coordinator.didBecomeFirstResponder = false
        }
    }
}

private extension String{
    func items(for numberOfDigits:Int) -> [String?]{
        return self.enumerated().reduce(into: Array(repeating: nil, count: numberOfDigits)) { (result, el) in
            result[el.offset] = String(el.element)
        }
    }
}

public struct PinEntryView<Content>:View  where Content: View  {
    @Binding var isFirstResponder:Bool
    @State var numberOfDigits:Int = 6
    @Binding var text:String
    private var spacing:CGFloat = 10
    private let content: (_ text:String?,  _ selected:Bool, _ enabled:Bool) -> Content
    private var onComplete:((String) -> Void)?
    
    public init(text:Binding<String>,
                numberOfDigits:Int,
                spacing:CGFloat = 10, isFirstResponder:Binding<Bool>,
                onComplete: ((String) -> Void)? = nil,
                @ViewBuilder content: @escaping (_ text:String?, _ selected:Bool, _ enabled:Bool) -> Content) {
        _text = text
        _isFirstResponder = isFirstResponder
        self.content = content
        self.spacing = spacing
        self.numberOfDigits = numberOfDigits
        self.onComplete = onComplete
    }
       
    public var body: some View {
        let items = self.text.items(for: numberOfDigits)
                 
        return ZStack{
            PinUITextField(text:$text, numberOfDigits: $numberOfDigits, isFirstResponder: $isFirstResponder, onComplete: onComplete)
            HStack(spacing:spacing){
                ForEach(0..<items.count, id: \.self){ i in
                    Button(action: {
                        self.isFirstResponder = true
                    }) {
                        self.content(items[i], self.text.count == i, false)
                    }
                    
                }
            }
        }
    }
}
