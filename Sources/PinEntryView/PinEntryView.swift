import SwiftUI
import Combine

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
        
        init(text: Binding<String>, numberOfDigits:Binding<Int>) {
            _text = text
            _numberOfDigits = numberOfDigits
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            text = textField.text ?? ""
            didBecomeFirstResponder = textField.isFirstResponder
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

    func makeCoordinator() -> Coordinator { Coordinator(text: $text, numberOfDigits: $numberOfDigits) }
    
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
        uiView.text = text
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

public struct PinEntryView<Content>:View  where Content: View  {
    
    private class ViewData:ObservableObject{
        var numberOfDigits:Int
        @Published var text:String = ""
        @Published var completed:Bool = false
        
        private var cancelableSet = Set<AnyCancellable>()
       
        var onComplete:((String) -> Void)?
        
        init(numberOfDigits:Int = 6) {
            self.numberOfDigits = numberOfDigits
            
           $text
                .map { [unowned self] in $0.count == self.numberOfDigits }
                .receive(on: DispatchQueue.main)
                .assign(to: \ViewData.completed, on: self)
                .store(in: &cancelableSet)
            
            $completed
                .sink(receiveValue: { [unowned self] (completed) in
                    if completed{
                        self.onComplete?(self.text)
                    }
                }).store(in: &cancelableSet)
        }
        
        func items() -> [String?]{
            return text.enumerated().reduce(into: Array(repeating: nil, count: numberOfDigits)) { (result, el) in
                       result[el.offset] = String(el.element)
                   }
        }
        
    }
    
    @ObservedObject private var data = ViewData()
    @Binding var isFirstResponder:Bool
    var spacing:CGFloat = 10
    
    let content: (_ text:String?,  _ selected:Bool, _ enabled:Bool) -> Content
    
    
    public init(numberOfDigits:Int,
                spacing:CGFloat = 10, isFirstResponder:Binding<Bool>,
                onComplete: ((String) -> Void)? = nil,
                @ViewBuilder content: @escaping (_ text:String?, _ selected:Bool, _ enabled:Bool) -> Content) {
        _isFirstResponder = isFirstResponder
        
        self.content = content
        self.spacing = spacing
        self.data.numberOfDigits = numberOfDigits
        self.data.onComplete = onComplete
    }
    
    public var body: some View {
        let items = self.data.items()
                 
        return ZStack{
            PinUITextField( text:$data.text, numberOfDigits: $data.numberOfDigits, isFirstResponder: $isFirstResponder)
            HStack(spacing:spacing){
                ForEach(0..<items.count, id: \.self){ i in
                    Button(action: {
                        self.isFirstResponder = true
                    }) {
                        self.content(items[i], self.data.text.count == i, false)
                    }
                    
                }
            }
        }
    }
}
