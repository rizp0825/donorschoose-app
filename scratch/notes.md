

## TeacherImage

```
open func loadImageTeacher(_ imageURL:URL) {
    downloadTeacherImage(imageURL)
}


//extension ProposalDetailViewController : ProjectAPIDelegate {

//    public func dataUpdateCallback( _ dataAPI: ProjectAPIProtocol, didChangeData data:[ProposalModel]?, error:APIError? ) {
    
//        if let someError = error {
//            //tableView.hidden = true
//            //alert the user
//
//            // MAS TODO Move over to NotificationViewController
//            if let alertVC = AlertFactory.AlertFromError(someError) {
//                self.present(alertVC, animated: true, completion: nil)
//            }
//        }
//        else {
//            if let newData = data {
//                if newData.count > 0 {
//                    let newDataModel = newData[0]
//                    self.model = newDataModel
//                    confgureUI()
//                }
//                else {
//                    print( "Alert , model was not found")
//                    /*
//                     if let alertVC = AlertFactory.AlertFromError(someError) {
//                     self.presentViewController(alertVC, animated: true, completion: nil)
//                     }
//                     */
//                }
//            }
//
//            /*
//             tableView.hidden = false
//             if let newTableData = data {
//             tableData = newTableData
//             dispatch_async(dispatch_get_main_queue(), {
//             self.tableView.reloadData()
//             })
//             }
//             */
//        }
        //self.refreshControl.endRefreshing()
//    }
//}


// MAS TODO
//config the techer pic
//    self.imageTeacherPic.layer.cornerRadius = self.imageTeacherPic.frame.size.width / 2
//    self.imageTeacherPic.clipsToBounds = true
//
//    self.imageTeacherPic.layer.borderWidth = 3.0
//    self.imageTeacherPic.layer.borderColor = UIColor.white.cgColor

//  public func downloadTeacherImage(_ url: URL ){
//
//    getDataFromUrl(url) { (data, response, error)  in
//      DispatchQueue.main.async { () -> Void in
//        guard let data = data , error == nil else { return }
//        self.imageTeacherPic.isHidden = false
//        self.imageTeacherPic.image = UIImage(data: data)
//        self.imageTeacherPic.contentMode = .scaleAspectFill
//        self.imageTeacherPic.fadeIn(duration: config.fadeInTime)
//      }
//    }
//  }



```
