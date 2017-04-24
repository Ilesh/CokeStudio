//
//  ViewController.swift
//  CokeStudio
//
//  Created by ajay singh thakur on 19/04/17.
//  Copyright © 2017 ajay singh thakur. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class ViewController: UIViewController {

    @IBOutlet weak var tableView : UITableView!
    fileprivate var songsArray : [JSON] = []
    fileprivate var indexToPass : Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.serviceRequestToGetAllSongs()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "player" {
        
            let vc = segue.destination as! NewPlayerViewController
            vc.index = self.indexToPass
            vc.playList = self.songsArray
            
            
        }
    }

    func playButtonClicked(_ sender : UIButton) -> Void {
        self.indexToPass = sender.tag
        self.performSegue(withIdentifier: "player", sender: self)
        
    }
}

extension ViewController : UITableViewDelegate {

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.selectionStyle  = .none
        
    }
    
}
extension ViewController : UITableViewDataSource {

    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ListTableViewCell
        
        //cell.backgroundColor = .green
        cell.titleLabel.text = songsArray[indexPath.row]["song"].string
        cell.artistLabel.text = songsArray[indexPath.row]["artists"].string
        let imageUrl = songsArray[indexPath.row]["cover_image"].stringValue
        cell.bannerImageView.af_setImage(withURL: URL.init(string: imageUrl)!)
        
        cell.playButton.tag = indexPath.row
        cell.playButton.addTarget(self, action: #selector(playButtonClicked(_:)), for: .touchUpInside)
        return cell
    }
}
extension ViewController {

    func serviceRequestToGetAllSongs() -> Void {
        
    
        let url = "http://starlord.hackerearth.com/cokestudio"
        Alamofire.request(url, method: .get, parameters: nil, encoding: URLEncoding.default).responseJSON { (Response) in
            
            switch Response.result {
            
            case.success(let data):
                
                let json = JSON(data)
                print(json)
                self.songsArray = json.arrayValue
                self.tableView.reloadData()
                
                
                break
            case .failure:
                break
            }
            
        }
        
    }
}
extension UIImageView {
    public func imageFromServerURL(urlString: String) {
        
        URLSession.shared.dataTask(with: NSURL(string: urlString)! as URL, completionHandler: { (data, response, error) -> Void in
            
            if error != nil {
                print(error!)
                return
            }
            DispatchQueue.main.async(execute: { () -> Void in
                let image = UIImage(data: data!)
                self.image = image
            })
            
        }).resume()
    }}
