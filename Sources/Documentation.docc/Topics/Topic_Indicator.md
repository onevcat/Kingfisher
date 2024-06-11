# Loading Indicator 

Setting and customizing indicator while loading.

#### Using the standard indicator

```swift
imageView.kf.indicatorType = .activity
imageView.kf.setImage(with: url)
```

#### Using an image as indicator

```swift
let path = Bundle.main.path(forResource: "loader", ofType: "gif")!
let data = try! Data(contentsOf: URL(fileURLWithPath: path))

imageView.kf.indicatorType = .image(imageData: data)
imageView.kf.setImage(with: url)
```

#### Using a customized view

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

#### Updating indicator with percentage progress

```swift
imageView.kf.setImage(with: url, progressBlock: {
    receivedSize, totalSize in
    let percentage = (Float(receivedSize) / Float(totalSize)) * 100.0
    print("downloading progress: \(percentage)%")
    myIndicator.percentage = percentage
})
```

The `progressBlock` is called only when the server's response includes a "Content-Length" in the header.
