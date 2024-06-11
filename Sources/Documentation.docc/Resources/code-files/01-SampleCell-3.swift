import UIKit

class SampleCell: UITableViewCell {
    var sampleImageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    var sampleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(sampleImageView)
        NSLayoutConstraint.activate([
            sampleImageView.widthAnchor.constraint(equalToConstant: 64),
            sampleImageView.heightAnchor.constraint(equalToConstant: 64),
            sampleImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            sampleImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        
        contentView.addSubview(sampleLabel)
        NSLayoutConstraint.activate([
            sampleLabel.leadingAnchor.constraint(equalTo: sampleImageView.trailingAnchor, constant: 12),
            sampleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
