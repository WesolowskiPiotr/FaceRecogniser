//
//  HistogramViewController.swift
//  FaceRecogniser
//
//  Created by Piotr Wesołowski on 03/10/2023.
//

import UIKit

class HistogramViewController: UIViewController {
    
    var imageView: UIImageView!
    var histogramView: UIImageView!
    var captureImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Histogram View"
        
        setupImageView()
        setupHistogramView()
        displayHistogram()
    }

    func setupImageView() {
        imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            imageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            imageView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            imageView.heightAnchor.constraint(equalToConstant: 400)
        ])
    }

    func setupHistogramView() {
        histogramView = UIImageView()
        histogramView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(histogramView)
        
        NSLayoutConstraint.activate([
            histogramView.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            histogramView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            histogramView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            histogramView.heightAnchor.constraint(equalToConstant: 200)
        ])
    }

    func displayHistogram() {
        guard let image = captureImage else { return }
        imageView.contentMode = .scaleAspectFit
        imageView.transform = CGAffineTransform(rotationAngle: .pi/2)
        imageView.image = image
        
        let histogramImage = OpenCVWrapper.generateHistogram(for: image)
        histogramView.image = histogramImage
    }
}
