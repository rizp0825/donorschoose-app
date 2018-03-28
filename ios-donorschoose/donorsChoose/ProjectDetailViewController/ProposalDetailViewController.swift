//  ProposalDetailViewController.swift

import UIKit
import MessageUI
import Firebase
import Crashlytics

public enum ShareActionType {
    case email
    case web
    case copy_URL
    case cancel
    
    func analyticsString() -> String {
        switch( self ) {
        case .email: return "EMAIL"
        case .web: return "WEB"
        case .copy_URL: return "COPY_URL"
        case .cancel: return "CANCEL"
        }
    }
}

open class ProposalDetailViewController: UIViewController {
    
    let apiConfig:APIConfig
    
    fileprivate let defaultSectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
    var cellWidth: CGFloat = 0
    let columnNum: CGFloat = 1
    
    var model:ProposalModel?
    var proposalID:String?
    
    var dataAPI:ProjectAPIProtocol?
    var descriptionList:[(title:String, description:String)] = [(title:String, description:String)]()
    
    @IBOutlet weak var buttonModalDismiss: UIButton! {
        didSet {
            buttonModalDismiss.isHidden = true
        }
    }
    
    @IBAction func actionDismiss(_ sender: AnyObject) {
        self.dismiss(animated: true) { }
    }
    
    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            collectionView.register(DescriptionViewCell.nib, forCellWithReuseIdentifier: DescriptionViewCell.reuseIdentifier)
            collectionView.register(ProposalHeaderView.nib, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: ProposalHeaderView.reuseIdentifier)
            collectionView.register(ProposalFooterView.nib, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: ProposalFooterView.reuseIdentifier)
            collectionView.dataSource = self
            collectionView.delegate = self
        }
    }
    
    @IBOutlet weak var buttonGive: UIButton! {
        didSet {
            buttonGive.layer.cornerRadius = 8
        }
    }
    
    @IBAction func actionGive(_ sender: AnyObject) {
        
        if let model = self.model {
            let giveURL = model.proposalURL
            if let url:URL = URL(string: giveURL) {
                UIApplication.shared.openURL(url)
            }
        }
    }
    
    @IBAction func actionTeacherInfo(_ sender: AnyObject) {
        if let model = self.model {
            if let currentNC = self.navigationController {
                let vc = TeacherDetailVC(teacherID: model.teacherId , teacherName: model.teacherName )
                if let imageURLString = model.imageURL  {
                    if let url = URL(string: imageURLString) {
                        vc.backgroundImageURL = url
                    }
                }
                currentNC.pushViewController(vc, animated: true)
            }
            else
            {
                let vc = TeacherDetailVC(teacherID: model.teacherId , teacherName: model.teacherName )
                self.present(vc, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func actionSchoolInfo(_ sender: AnyObject) {
        
        guard let schoolID = self.model?.extractedSchoolID,
            let schoolName = self.model?.schoolName else {
                return
        }
        
        var schoolLocation:String?
        if let city = self.model?.city, let state = self.model?.state {
            schoolLocation = " \(city), \(state) "
        }
        
        if let currentNC = self.navigationController {
            let vc = SchoolDetailViewController(schoolID: schoolID , schoolName: schoolName, schoolCity:schoolLocation )
            currentNC.pushViewController(vc, animated: true)
        }
        else
        {
            let vc = SchoolDetailViewController(schoolID: schoolID , schoolName: schoolName, schoolCity:schoolLocation)
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    @IBOutlet weak var imageHeaderThumbnail: UIImageView!    {
        didSet {
            //imageHeaderThumbnail.layer.borderWidth = 1.0
            //imageHeaderThumbnail.layer.borderColor = COLOR_UIVIEW_CONTAINER_BACKGROUND.CGColor
            //imageHeaderThumbnail.contentMode = .ScaleAspectFit
        }
    }
    
    @IBOutlet weak var labelCurrenFundingAmount: UILabel! {
        didSet {
            labelCurrenFundingAmount.text = "-"
            labelCurrenFundingAmount.isHidden = false
        }
    }
    
    @IBOutlet weak var fundingStatusView: ViewFundingStatus! {
        didSet {
            fundingStatusView.cornerRadius = 4
        }
    }
    
    @IBOutlet weak var labelStillNeeded: UILabel!
    
    @IBOutlet weak var labelDonorCount: UILabel!
    
    @IBAction func actionShare( _ sender:AnyObject ) {
        if let model = self.model {
            if let url:URL = URL(string: model.proposalURL) {
                shareAsAlertController(url)
            }
        }
    }
    
    
    func shareAsActivityViewController( _ shareContentString:NSString ) {
        
        let activityViewController = UIActivityViewController(activityItems: [shareContentString as NSString], applicationActivities: nil)
        
        present(activityViewController, animated: true, completion: nil)
    }
    
    func shareAsAlertController( _ url:URL ) {
        
        if let model = self.model {
            
            let optionMenu = UIAlertController(title: nil, message: "Share this Project", preferredStyle: .actionSheet)
            
            let emailAction = UIAlertAction(title: "Email", style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                // MAS TODO
                //                Analytics.logEvent(AnalyticsEventShare, parameters: [
                //                    AnalyticsParameterItemID: "id-\(model.id)" as NSObject,
                //                    AnalyticsParameterContentType: "proposal" as NSObject
                //                    ])
                
                let emailTitle = "Checkout this great school project!"
                var messageBodyText = ""
                messageBodyText +=  "<p>"
                messageBodyText +=  "<p>"
                messageBodyText +=  "\(model.fulfillmentTrailer)"
                messageBodyText +=  "<p>"
                
                messageBodyText +=  "<a href=\"\(url)\"> \(model.title) </a>"
                messageBodyText +=  "<p>"
                
                let appURL = "https://itunes.apple.com/us/app/donors-choose/id1074056163?mt=8"
                messageBodyText +=  "<a href=\"\(appURL)\"> Donors Choose app </a>"
                messageBodyText +=  "<p>"
                
                let mc: MFMailComposeViewController = MFMailComposeViewController()
                mc.mailComposeDelegate = self
                mc.setSubject(emailTitle)
                mc.setMessageBody(messageBodyText, isHTML: true)
                
                self.present(mc, animated: true, completion: nil)
            })
            
            let webAction = UIAlertAction(title: "Web", style: .default, handler: {
                (alert: UIAlertAction!) -> Void in
                UIApplication.shared.openURL(url)
            })
            
            let copyAction = UIAlertAction(title: "Copy URL", style: .default, handler: {
                (alert:UIAlertAction!) -> Void in
                UIPasteboard.general.string = url.absoluteString
            })
            
            var watchAction: UIAlertAction? = nil
            let doesExist =  WatchList.doesWatchListItemExist(model)
            if doesExist == true {
                watchAction = UIAlertAction(title: "Remove From My Favorites", style: .default, handler: {
                    (alert:UIAlertAction!) -> Void in
                    WatchList.removeFromWatchList(model)
                })
            }
            else {
                watchAction = UIAlertAction(title: "Add To My Favorites", style: .default, handler: {
                    (alert:UIAlertAction!) -> Void in
                    WatchList.addToWatchList(model)
                })
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
                (alert: UIAlertAction!) -> Void in
            })
            
            optionMenu.addAction(emailAction)
            optionMenu.addAction(webAction)
            optionMenu.addAction(copyAction)
            if let saveAction = watchAction {
                optionMenu.addAction(saveAction)
            }
            optionMenu.addAction(cancelAction)
            
            self.present(optionMenu, animated: true, completion: nil)
        }
    }
    
    func confgureUI() {
        if let model = self.model {
            
            DispatchQueue.main.async {
                self.descriptionList.removeAll()
                self.descriptionList.append((model.title,model.fulfillmentTrailer))
                self.descriptionList.append(("My Students:",model.shortDescription))
                if let synopsis = model.synopsis {
                    // synopsis.htmlUnescape() results in: All our students receive free breakfast.<br/><br/>The materials will make a difference in my students' learning and improve their school lives because they will be able to use it interactively and productively.
                    
                    //MAS TODO scrub the <br/> or support in textview
                    // MAS TODO
                    //                    self.descriptionList.append(("My Project:", synopsis.htmlUnescape()))
                    self.descriptionList.append(("My Project:", synopsis))
                }
                
                // MAS TODO
                // descriptionList.append(("Where Your Donation Goes:",model.shortDescription))
                // descriptionList.append(("Project Activity:",model.shortDescription))
                
                let costToCompleteNumber = model.costToComplete.floatValue
                let numberFormatter = NumberFormatter()
                numberFormatter.numberStyle = NumberFormatter.Style.decimal
                
                if let formatedString = numberFormatter.string(from: costToCompleteNumber as NSNumber ) {
                    self.labelCurrenFundingAmount.text =  "$\(formatedString) still needed"
                }
                
                self.labelStillNeeded.text = "$\(model.totalPrice)"
                self.labelDonorCount.text = "\(model.numDonors)"
                
                let percentFloat = CGFloat( CGFloat(model.percentFunded) * 0.01 )
                self.fundingStatusView.percentComplete = percentFloat
                
                self.collectionView.reloadData()
                
            }//end dispatch
        }
    }//end configUI
    
    open func fetchAdditionalData(_ projectIDString:String) {
        dataAPI?.getData(projectIDString, callback: { (data, error) in
            
            if let someError = error {
                // self.processError(someError)
                //tableView.hidden = true
                if let alertVC = AlertFactory.AlertFromError(someError) {
                    self.present(alertVC, animated: true, completion: nil)
                }
            }
            else {
                if let newData = data {
                    self.model = newData
                    self.confgureUI()
                    //                    DispatchQueue.main.async(execute: {
                    //                        self.tableView.isHidden = false
                    //                        self.tableView.reloadData()
                    //                        self.refreshControl?.endRefreshing()
                    //                    })
//                    if let newTableData = data {
//                        tableData = newTableData
//                        dispatch_async(dispatch_get_main_queue(), {
//                            self.tableView.reloadData()
//                        })
//                    }
                }
            }
            
        })
        
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        // MAS TODO
        //        if let itemID = model?.id , let itemName = model?.proposalURL {
        //            Analytics.logEvent(AnalyticsEventSelectContent, parameters: [
        //                AnalyticsParameterItemID: "id-\(itemID)" as NSObject,
        //                AnalyticsParameterItemName: itemName as NSObject,
        //                AnalyticsParameterContentType: "proposal" as NSObject
        //                ])
        //        }
        
        dataAPI = ProjectAPI(config: apiConfig,user: "matt")//, delegate: self)
        
        let buttonShare : UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.action, target: self, action: #selector(ProposalDetailViewController.actionShare(_:)))
        self.navigationItem.rightBarButtonItem = buttonShare
        
        confgureUI()
        
        if let model = self.model {
            
            Answers.logContentView(withName: "Proposal", contentType: "ProposalDetail", contentId: model.id, customAttributes: [
                "TeacherID":model.teacherId,
                "costToComplete":model.costToComplete,
                "totalPrice":model.totalPrice,
                "Screen Orientation":"Landscape"
                ])
        }
        if let proposalIDFromModel = self.model?.id {
            self.proposalID = proposalIDFromModel
        }
        
        if let fetchID  = self.proposalID {
            fetchAdditionalData(fetchID)
        }
    }
    
    override open func viewWillLayoutSubviews()
    {
        super.viewWillLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    override open func viewDidLayoutSubviews()
    {
        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            let spaceBetweenCells = flowLayout.minimumInteritemSpacing * (columnNum - 1)
            let totalCellAvailableWidth = collectionView.frame.size.width - flowLayout.sectionInset.left - flowLayout.sectionInset.right - spaceBetweenCells
            cellWidth = floor(totalCellAvailableWidth / columnNum);
        }
    }
    
    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: Bundle! , apiConfig:APIConfig ,model:ProposalModel? , proposalID:String? ) {
        self.apiConfig = apiConfig
        self.model = model
        self.proposalID = proposalID
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    public convenience init(apiConfig:APIConfig, proposalID:String ) {
        self.init(nibName: "ProposalDetailViewController", bundle: Bundle(for: ProposalDetailViewController.self), apiConfig:apiConfig, model:nil, proposalID:proposalID )
    }
    
    public convenience init(apiConfig:APIConfig, model:ProposalModel )
    {
        self.init(nibName: "ProposalDetailViewController", bundle: Bundle(for: ProposalDetailViewController.self), apiConfig:apiConfig, model:model , proposalID:nil )
    }
}

extension ProposalDetailViewController : UICollectionViewDataSource {
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return descriptionList.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DescriptionViewCell.reuseIdentifier, for: indexPath) as! DescriptionViewCell
        cell.configure(descriptionList[(indexPath as NSIndexPath).row])
        let cellMargins = cell.layoutMargins.left + cell.layoutMargins.right
        cell.labelTitle.preferredMaxLayoutWidth = cellWidth - cellMargins
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        switch kind {
            
        case UICollectionElementKindSectionHeader:
            
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ProposalHeaderView.reuseIdentifier, for: indexPath) as! ProposalHeaderView
            
            if let model = self.model {
                
                headerView.buttonTeacher.setTitle(model.teacherName, for: UIControlState())
                headerView.buttonSchool.setTitle( model.schoolName, for: UIControlState())
                
                headerView.buttonTeacher.addTarget(self, action: #selector(actionTeacherInfo(_:)), for: .touchUpInside)
                headerView.buttonSchool.addTarget(self, action: #selector(actionSchoolInfo(_:)), for: .touchUpInside)
                
                headerView.labelLocation.text = "\(model.city), \(model.state)"
                //headerView.labelPovertyStatus.text = model.povertyLevel
                
                if let imageURLString = model.imageURL {
                    if let url = URL(string: imageURLString) {
                        headerView.loadImageBackground(url)
                    }
                }
            }
            return headerView
        case UICollectionElementKindSectionFooter:
            let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ProposalFooterView.reuseIdentifier, for: indexPath) as! ProposalFooterView
            footerView.backgroundColor = UIColor.green;
            return footerView
        default:
            assert(false, "Unexpected element kind")
        }
        
        //MAS TODO ... replace with EmptyCollectionReusableView
        let emptyView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ProposalHeaderView.reuseIdentifier, for: indexPath)
        return emptyView
    }
}

extension ProposalDetailViewController : UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        
        if let cell = DescriptionViewCell.fromNib() {
            
            let cellMargins = cell.layoutMargins.left + cell.layoutMargins.right
            
            cell.configure(descriptionList[(indexPath as NSIndexPath).row])
            
            let width = cellWidth - cellMargins
            cell.labelTitle.preferredMaxLayoutWidth = width
            cell.constraintWidth.constant = width //adjust the width to be correct for the number of columns
            
            //apply auto layout and retrieve the size of the cell
            return cell.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
        }
        return CGSize.zero
    }
}

extension ProposalDetailViewController : UICollectionViewDelegate {
    
    public func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt
        indexPath: IndexPath) -> Bool {
        return true
    }
    
    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
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
