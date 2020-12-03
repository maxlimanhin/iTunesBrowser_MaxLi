//
//  ViewController.swift
//  iTunesBrowser
//
//  Created by Max on 2/12/2020.
//

import UIKit
import RxSwift
import RxCocoa
import Kingfisher
import AVFoundation

class ViewController: UIViewController, UITableViewDelegate {
    
    @IBOutlet weak var keyboardConstraint: NSLayoutConstraint!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    var selectedTrack: Int?
    var player: AVPlayer?
    
    private let disposeBag = DisposeBag()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.tableView.register(UINib(nibName: "SongTableViewCell", bundle: nil), forCellReuseIdentifier: "SongTableViewCell")
        
        let searchResults = searchTextField.rx.text.orEmpty
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .flatMapLatest { query -> Observable<[Result]> in
                if query.isEmpty {
                    return .just([])
                }
                return self.albumSearch(query)
                    .catchAndReturn([])
            }
            .observe(on: MainScheduler.instance)
        
        self.tableView.rx
                .setDelegate(self)
                .disposed(by: disposeBag)
        
        searchResults.bind(to: tableView.rx.items) { (tableView, row, songResult) in
            let cell = tableView.dequeueReusableCell(withIdentifier: "SongTableViewCell") as? SongTableViewCell
            
            cell?.titleLabel?.text = songResult.trackName ?? ""
            cell?.descLabel?.text = songResult.artistName ?? ""
            if let imageUrl = URL(string: songResult.artworkUrl100 ?? ""){
                cell?.thrumbnailImageVIew.kf.setImage(with: imageUrl)
            }
            if songResult.trackId == self.selectedTrack {
                cell?.bgView.layer.borderColor = UIColor.green.cgColor
                cell?.bgView.layer.borderWidth = 1.0
            } else {
                cell?.bgView.layer.borderColor = UIColor.white.cgColor
                cell?.bgView.layer.borderWidth = 0.0
            }
            return cell ?? UITableViewCell()
        }.disposed(by: disposeBag)
        
        Observable
            .zip(tableView.rx.itemSelected, tableView.rx.modelSelected(Result.self))
            .bind { [unowned self] indexPath, result in
                self.selectedTrack = result.trackId
                self.tableView.deselectRow(at: indexPath, animated: true)
                if let playerUrl = URL(string: result.previewUrl ?? ""){
                    if self.player != nil {
                        self.player?.pause()
                        self.player = nil
                    }
                    self.player = AVPlayer(url: playerUrl)
                    self.player?.play()
                }
                self.tableView.reloadData()
            }
            .disposed(by: disposeBag)
        
        keyboardHeight()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { (keyboardHeight) in
                self.keyboardConstraint.constant = keyboardHeight
                self.view.layoutIfNeeded()
            })
            .disposed(by: disposeBag)
    }
    
    private func albumSearch(_ albumKeyword: String) -> Observable<[Result]> {
        let urlString = "https://itunes.apple.com/search?media=music&term=\(albumKeyword.replacingOccurrences(of: " ", with: "+"))"
        let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!

        
        let request = URLRequest(url: url)
        return URLSession.shared.rx.response(request: request)
            .map { result in
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let decodedContent = try decoder.decode(SearchiTunesContent.self, from: result.data)
                    return decodedContent.results ?? []
                } catch {
                    print(error)
                }
                
                return []
            }
            .catchAndReturn([])
    }

    private func keyboardHeight() -> Observable<CGFloat> {
        return Observable
                .from([
                    
                    NotificationCenter.default.rx.notification(UIResponder.keyboardWillShowNotification)
                                .map { notification -> CGFloat in
                                    (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.height ?? 0
                                },
                    NotificationCenter.default.rx.notification(UIResponder.keyboardWillHideNotification)
                                .map { _ -> CGFloat in
                                    0
                                }
                ])
                .merge()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
}

