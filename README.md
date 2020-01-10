# PinEntryView

![Preview](images/preview.gif?raw=true "Preview")

## Usage

```Swift

import PinEntryView

struct ContentView: View {
    @State var isFirstResponder:Bool = false
    
    var body: some View {
        VStack{            
            PinEntryView(numberOfDigits: 6, spacing: 10, isFirstResponder: $isFirstResponder, onComplete: { (code) in
                self.isFirstResponder = false
            }) { (string, selected, enabled) in
                
                //Create item view 
                Text("\(string ?? "_")")
                .foregroundColor( Color.black)
                .frame(width: 30, height: 30)
                    .background(selected ? Color.clear : Color.gray)
                .border( Color.black, width: 1)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
```

