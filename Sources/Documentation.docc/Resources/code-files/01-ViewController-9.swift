// cell.sampleImageView.kf.setImage(with: url, options: [.processor(roundCorner)])
cell.sampleImageView.kf.setImage(with: url, options: [.processor(roundCorner)]) { result in
    switch result {
    case .success(let imageResult):
        print("Image loaded from cache: \(imageResult.cacheType)")
    case .failure(let error):
        print("Error: \(error)")
    }
}
