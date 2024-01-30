# Setting and customizing indicator while loading

#### Using an Image as Indicator

```swift
let path = Bundle.main.path(forResource: "loader", ofType: "gif")!
let data = try! Data(contentsOf: URL(fileURLWithPath: path))

imageView.kf.indicatorType = .image(imageData: data)
imageView.kf.setImage(with: url)
```

#### Using a Customized View

```swift
struct MyIndicator: Indicator {
    let view: UIView = UIView()
    
    func startAnimatingView() { view.isHidden = false }
    func stopAnimatingView() { view.isHidden = true }
    
    init() {
        view.backgroundColor = .red
    }
}

let i = MyIndicator()
imageView.kf.indicatorType = .custom(indicator: i)
```

#### Updating Indicator with Percentage

```swift
imageView.kf.setImage(with: url, progressBlock: {
    receivedSize, totalSize in
    let percentage = (Float(receivedSize) / Float(totalSize)) * 100.0
    print("downloading progress: \(percentage)%")
    myIndicator.percentage = percentage
})
```

The `progressBlock` will be only called if your server response contains the "Content-Length" in the header.
